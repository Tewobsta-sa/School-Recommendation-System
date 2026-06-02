import { db } from "../config/db.js";
import { calculateAdAmount, AD_DAILY_RATES_ETB } from "../config/ad-pricing.js";
import { sendAdPaymentInstructionsEmail } from "./ad-email.service.js";
import { logger } from "../config/logger.js";
import {
  ConflictError,
  ForbiddenError,
  NotFoundError,
  ValidationError,
} from "../utils/errors.js";

function toIntId(id, label = "id") {
  const parsed = Number(id);
  if (!Number.isInteger(parsed) || parsed <= 0) {
    throw new ValidationError(`Invalid ${label}`);
  }
  return parsed;
}

function pricingForAd(ad) {
  const p = calculateAdAmount(ad.placementType, ad.durationDays);
  return {
    placementType: ad.placementType,
    durationDays: ad.durationDays,
    dailyRateEtb: p.dailyRateEtb,
    amountEtb: ad.payment ? Number(ad.payment.amount) : p.amountEtb,
    currency: "ETB",
  };
}

function serializeAd(ad) {
  if (!ad) return null;
  return {
    ...ad,
    amount: ad.payment?.amount != null ? Number(ad.payment.amount) : undefined,
    payment: ad.payment
      ? {
          ...ad.payment,
          amount: Number(ad.payment.amount),
        }
      : undefined,
  };
}

const publicAdSelect = {
  id: true,
  title: true,
  description: true,
  imageUrl: true,
  targetUrl: true,
  placementType: true,
  companyName: true,
  startDate: true,
  endDate: true,
  impressions: true,
  clicks: true,
};

function activeAdWhere(extra = {}) {
  const now = new Date();
  return {
    status: "ACTIVE",
    payment: { status: "COMPLETED" },
    startDate: { lte: now },
    endDate: { gte: now },
    ...extra,
  };
}

// -----------------------------------------------------------------------------
// Public — request (no payment until moderator approves)
// -----------------------------------------------------------------------------

export async function createAdRequest({
  companyName,
  contactEmail,
  contactPhone,
  title,
  description,
  targetUrl,
  durationDays,
  placementType,
  imageUrl,
}) {
  const pricing = calculateAdAmount(placementType, durationDays);

  const ad = await db.advertisement.create({
    data: {
      companyName,
      contactEmail: contactEmail.toLowerCase(),
      contactPhone,
      title,
      description: description || null,
      imageUrl: imageUrl || null,
      targetUrl,
      durationDays,
      placementType,
      status: "PENDING_REVIEW",
    },
  });

  return {
    advertisement: serializeAd(ad),
    pricing: {
      placementType,
      durationDays: pricing.durationDays,
      dailyRateEtb: pricing.dailyRateEtb,
      amountEtb: pricing.amountEtb,
      currency: "ETB",
    },
    message:
      "Advertisement request submitted. You will receive an email with payment instructions after a moderator approves your ad.",
  };
}

export async function getAdRequestStatus(adId) {
  const id = toIntId(adId, "adId");
  let ad = await db.advertisement.findUnique({
    where: { id },
    include: { payment: true },
  });
  if (!ad) throw new NotFoundError("Advertisement request not found");

  // Reconciliation: If the payment is initialized with Chappa but still pending locally, check Chappa directly!
  if (ad.status === "AWAITING_PAYMENT" && ad.payment && ad.payment.status === "PENDING" && ad.chappaTransactionId) {
    try {
      const { verifyChappaPayment } = await import("./chappa.service.js");
      const verification = await verifyChappaPayment(ad.chappaTransactionId);
      if (verification.status === "success") {
        logger.info({ adId: id }, "Payment verified via reconciliation pull. Activating advertisement.");
        
        const now = new Date();
        const endDate = new Date(now);
        endDate.setDate(endDate.getDate() + ad.durationDays);
        
        ad = await db.advertisement.update({
          where: { id },
          data: {
            status: "ACTIVE",
            startDate: now,
            endDate,
            payment: {
              update: {
                status: "COMPLETED",
              },
            },
          },
          include: { payment: true },
        });
      }
    } catch (err) {
      logger.warn({ err, adId: id }, "Reconciliation verification failed or payment still pending at Chappa.");
    }
  }

  return {
    advertisement: serializeAd(ad),
    pricing: pricingForAd(ad),
  };
}

/** Public payment page — only ads awaiting payment after moderator approval. */
export async function getAdForPayment(adId) {
  const id = toIntId(adId, "adId");
  const ad = await db.advertisement.findUnique({
    where: { id },
    include: { payment: true },
  });
  if (!ad) throw new NotFoundError("Advertisement not found");
  if (ad.status !== "AWAITING_PAYMENT") {
    throw new ConflictError(
      "This advertisement is not awaiting payment. Check your email for the correct link or contact support.",
    );
  }
  if (!ad.payment) {
    throw new ValidationError("Payment record missing for this advertisement");
  }

  return {
    advertisement: serializeAd(ad),
    pricing: pricingForAd(ad),
  };
}

// -----------------------------------------------------------------------------
// Public — display + analytics
// -----------------------------------------------------------------------------

export async function listActiveAds({ placement, limit = 5 }) {
  const where = activeAdWhere(placement ? { placementType: placement } : {});

  const ads = await db.advertisement.findMany({
    where,
    take: Number(limit),
    orderBy: { createdAt: "desc" },
    select: publicAdSelect,
  });

  return { data: ads };
}

export async function recordImpression(adId) {
  const id = toIntId(adId, "adId");
  const ad = await db.advertisement.findFirst({
    where: { id, ...activeAdWhere() },
  });
  if (!ad) throw new NotFoundError("Active advertisement not found");

  await db.advertisement.update({
    where: { id },
    data: { impressions: { increment: 1 } },
  });
  return { recorded: true };
}

export async function recordClick(adId) {
  const id = toIntId(adId, "adId");
  const ad = await db.advertisement.findFirst({
    where: { id, ...activeAdWhere() },
  });
  if (!ad) throw new NotFoundError("Active advertisement not found");

  await db.advertisement.update({
    where: { id },
    data: { clicks: { increment: 1 } },
  });
  return { recorded: true, targetUrl: ad.targetUrl };
}

// -----------------------------------------------------------------------------
// Admin (MODERATOR) — content review, then email payment link
// -----------------------------------------------------------------------------

export async function listAdsForAdmin({ query }) {
  const { status, page = 1, limit = 10 } = query;
  const where = {};
  if (status) where.status = status;
  else {
    where.status = {
      in: [
        "PENDING_REVIEW",
        "AWAITING_PAYMENT",
        "ACTIVE",
        "REJECTED",
        "EXPIRED",
      ],
    };
  }

  const skip = (Number(page) - 1) * Number(limit);
  const [data, total] = await Promise.all([
    db.advertisement.findMany({
      where,
      skip,
      take: Number(limit),
      orderBy: { createdAt: "desc" },
      include: {
        payment: true,
      },
    }),
    db.advertisement.count({ where }),
  ]);

  return {
    data: data.map(serializeAd),
    meta: {
      total,
      page: Number(page),
      limit: Number(limit),
      totalPages: Math.ceil(total / Number(limit)) || 1,
    },
  };
}

/** Approve ad content → create payment, email pay link (does not go live yet). */
export async function approveAd({ adId }) {
  // Remove userId parameter
  const id = toIntId(adId, "adId");
  const ad = await db.advertisement.findUnique({
    where: { id },
    include: { payment: true },
  });
  if (!ad) throw new NotFoundError("Advertisement not found");
  if (ad.status !== "PENDING_REVIEW") {
    throw new ConflictError("Only ads pending review can be approved");
  }

  const pricing = calculateAdAmount(ad.placementType, ad.durationDays);

  const payment = await db.payment.create({
    data: {
      amount: pricing.amountEtb,
      currency: "ETB",
      status: "PENDING",
    },
  });

  const updated = await db.advertisement.update({
    where: { id },
    data: {
      status: "AWAITING_PAYMENT",
      paymentId: payment.id,
      rejectReason: null,
    },
    include: { payment: true },
  });

  try {
    await sendAdPaymentInstructionsEmail({
      to: updated.contactEmail,
      adId: updated.id,
      title: updated.title,
      amountEtb: Number(payment.amount),
      durationDays: updated.durationDays,
      placementType: updated.placementType,
    });
  } catch (err) {
    logger.error(
      { err, adId: updated.id },
      "Failed to send ad payment instructions email, continuing",
    );
  }

  return serializeAd(updated);
}

export async function rejectAd({ adId, userId, reason }) {
  const id = toIntId(adId, "adId");
  const ad = await db.advertisement.findUnique({
    where: { id },
    include: { payment: true },
  });
  if (!ad) throw new NotFoundError("Advertisement not found");
  if (ad.status !== "PENDING_REVIEW" && ad.status !== "AWAITING_PAYMENT") {
    throw new ConflictError("This advertisement can no longer be rejected");
  }

  if (ad.paymentId) {
    await db.payment.update({
      where: { id: ad.paymentId },
      data: { status: "FAILED" },
    });
  }

  const updated = await db.advertisement.update({
    where: { id },
    data: {
      status: "REJECTED",
      rejectReason: reason || null,
    },
    include: { payment: true },
  });

  return serializeAd(updated);
}

export async function getAdPricingInfo() {
  return {
    currency: "ETB",
    rates: AD_DAILY_RATES_ETB,
    example: {
      placementType: "BANNER",
      durationDays: 7,
      ...calculateAdAmount("BANNER", 7),
    },
  };
}

export async function getAdRevenueAnalytics({ query }) {
  const { page = 1, limit = 10 } = query;
  const skip = (Number(page) - 1) * Number(limit);

  const [completedPayments, totalRevenue, activeCount, pendingReview] =
    await Promise.all([
      db.payment.findMany({
        where: { status: "COMPLETED" },
        skip,
        take: Number(limit),
        orderBy: { updatedAt: "desc" },
        include: {
          advertisement: {
            select: {
              id: true,
              title: true,
              companyName: true,
              impressions: true,
              clicks: true,
              placementType: true,
              status: true,
            },
          },
        },
      }),
      db.payment.aggregate({
        where: { status: "COMPLETED" },
        _sum: { amount: true },
      }),
      db.advertisement.count({ where: activeAdWhere() }),
      db.advertisement.count({ where: { status: "PENDING_REVIEW" } }),
    ]);

  const totalImpressions = await db.advertisement.aggregate({
    _sum: { impressions: true, clicks: true },
  });

  return {
    summary: {
      totalRevenueEtb: Number(totalRevenue._sum.amount || 0),
      activeAds: activeCount,
      pendingReview,
      totalImpressions: totalImpressions._sum.impressions || 0,
      totalClicks: totalImpressions._sum.clicks || 0,
    },
    payments: completedPayments.map((p) => ({
      ...p,
      amount: Number(p.amount),
      advertisement: p.advertisement,
    })),
    meta: { page: Number(page), limit: Number(limit) },
  };
}

export async function expireDueAdvertisements() {
  const now = new Date();
  const result = await db.advertisement.updateMany({
    where: {
      status: "ACTIVE",
      endDate: { lt: now },
    },
    data: { status: "EXPIRED" },
  });
  return { expiredCount: result.count };
}

export function assertModerator(user) {
  if (!user || user.role !== "MODERATOR") {
    throw new ForbiddenError("Moderator access required");
  }
}

export async function initializeAdPayment({ adId }) {
  const id = toIntId(adId, "adId");

  const ad = await db.advertisement.findUnique({
    where: { id },
    include: { payment: true },
  });

  if (!ad) throw new NotFoundError("Advertisement not found");
  if (ad.status !== "AWAITING_PAYMENT") {
    throw new ConflictError("This advertisement is not awaiting payment");
  }
  if (!ad.payment) {
    throw new ValidationError("Payment record missing for this advertisement");
  }

  // Dynamic import is perfectly fine here if optimizing startup times
  const { initializeChappaPayment } = await import("./chappa.service.js");

  // 1. Call the payment gateway
  let chappaResult;
  try {
    chappaResult = await initializeChappaPayment({
      amount: Number(ad.payment.amount),
      email: ad.contactEmail,
      phone: ad.contactPhone,
      adId: id,
      title: ad.title,
    });
  } catch (error) {
    logger.error(
      { adId: id, error: error.message },
      "Chapa API initialization failed",
    );
    throw new Error(`Payment Gateway Error: ${error.message}`);
  }

  // 2. Single atomic database operation using Prisma nested updates
  await db.advertisement.update({
    where: { id },
    data: {
      chappaPaymentUrl: chappaResult.checkoutUrl,
      chappaTransactionId: chappaResult.txRef,
      payment: {
        update: {
          chappaCheckoutId: chappaResult.checkoutId,
          chappaReference: chappaResult.txRef,
        },
      },
    },
  });

  // 3. Handle Development/Mock Payments
  if (chappaResult.txRef?.startsWith("mock_")) {
    logger.info(
      { adId: id, txRef: chappaResult.txRef },
      "Auto-processing callback for mock payment in development mode.",
    );
    try {
      // Assuming handleChappaCallback is imported or available in scope
      await handleChappaCallback({ txRef: chappaResult.txRef });
    } catch (callbackError) {
      logger.error(
        { txRef: chappaResult.txRef, err: callbackError },
        "Failed to auto-process mock callback",
      );
      // Do not block the user response if the local mock processor fails
    }
  }

  return {
    paymentUrl: chappaResult.checkoutUrl,
    checkoutId: chappaResult.checkoutId,
  };
}
export async function handleChappaCallback({ txRef }) {
  const { verifyChappaPayment } = await import("./chappa.service.js");
  const verification = await verifyChappaPayment(txRef);

  if (
    verification.status !== "success" &&
    verification.status !== "COMPLETED"
  ) {
    throw new Error("Payment verification failed at provider level");
  }

  const ad = await db.advertisement.findFirst({
    where: { chappaTransactionId: txRef },
    include: { payment: true },
  });

  if (!ad) throw new NotFoundError("Advertisement not found");

  const now = new Date();
  const endDate = new Date(now);
  endDate.setDate(endDate.getDate() + ad.durationDays);

  await db.$transaction([
    db.payment.update({
      where: { id: ad.paymentId },
      data: { status: "COMPLETED" },
    }),
    db.advertisement.update({
      where: { id: ad.id },
      data: {
        status: "ACTIVE",
        startDate: now,
        endDate,
      },
    }),
  ]);

  return { success: true, adId: ad.id };
}

export async function verifyAdPayment(adId) {
  const id = toIntId(adId, "adId");
  const ad = await db.advertisement.findUnique({
    where: { id },
    include: { payment: true },
  });

  if (!ad) throw new NotFoundError("Advertisement not found");

  // If already active/completed, no need to verify again
  if (ad.status === "ACTIVE" && ad.payment?.status === "COMPLETED") {
    return serializeAd(ad);
  }

  const txRef = ad.chappaTransactionId;
  if (!txRef) {
    // Payment hasn't been initialized yet
    return serializeAd(ad);
  }

  const { verifyChappaPayment } = await import("./chappa.service.js");
  let verification;
  try {
    verification = await verifyChappaPayment(txRef);
  } catch (error) {
    logger.error(
      { adId: id, txRef, error: error.message },
      "Chappa verification check failed",
    );
    return serializeAd(ad); // Return current state without crashing
  }

  if (
    verification.status === "success" ||
    verification.status === "COMPLETED"
  ) {
    const now = new Date();
    const endDate = new Date(now);
    endDate.setDate(endDate.getDate() + ad.durationDays);

    const updated = await db.$transaction([
      db.payment.update({
        where: { id: ad.paymentId },
        data: { status: "COMPLETED" },
      }),
      db.advertisement.update({
        where: { id: ad.id },
        data: {
          status: "ACTIVE",
          startDate: now,
          endDate,
        },
        include: { payment: true },
      }),
    ]);
    return serializeAd(updated[1]);
  }

  return serializeAd(ad);
}

