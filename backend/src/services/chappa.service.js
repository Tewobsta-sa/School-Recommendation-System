import axios from "axios";
import { logger } from "../config/logger.js";

const CHAPPA_SECRET_KEY = process.env.CHAPPA_SECRET_KEY;
const CHAPPA_BASE_URL = process.env.CHAPPA_BASE_URL;

export async function initializeChappaPayment({
  amount,
  email,
  phone,
  adId,
  title,
}) {
  const frontendUrl = process.env.FRONTEND_URL;
  const txRef = `ad_${adId}_${Date.now()}`;

  // 1. Clean the phone number format (Chapa strictly prefers 2519XXXXXXXX or +2519XXXXXXXX)
  let formattedPhone = phone ? String(phone).trim() : "";
  if (formattedPhone.startsWith("0")) {
    formattedPhone = "251" + formattedPhone.slice(1);
  } else if (formattedPhone.startsWith("+")) {
    formattedPhone = formattedPhone.replace("+", "");
  }

  // 2. Safely clean first and last name variables to prevent validation hiccups
  const cleanFirstName = "Advertisement";
  const cleanLastName = `AdID${adId}`;

  // 🟢 Construct a clean description and tightly bound it to Chapa's strict 50-character ceiling
  const rawDescription = `Ad Pay: ${title || ""}`.trim();
  const cleanDescription = rawDescription.substring(0, 50);

  try {
    const response = await axios.post(
      `${CHAPPA_BASE_URL}/v1/transaction/initialize`,
      {
        amount: Number(amount),
        currency: "ETB",
        email: email ? email.trim() : "",
        phone: formattedPhone,
        first_name: cleanFirstName,
        last_name: cleanLastName,
        tx_ref: txRef,
        callback_url: `${process.env.APP_URL}/api/ads/chappa/callback`,
        return_url: `${frontendUrl}/advertise/success/${adId}`,
        customization: {
          title: `Ad Payment`,
          description: `Payment for Advertisement ID ${adId}`, // Safe: only contains letters, spaces, and numbers
        },
      },
      {
        headers: {
          Authorization: `Bearer ${CHAPPA_SECRET_KEY}`,
          "Content-Type": "application/json",
        },
      },
    );

    // Chapa returns response data wrapped inside a .data object
    return {
      checkoutUrl: response.data?.data?.checkout_url,
      checkoutId: response.data?.data?.id || `chapa_${Date.now()}`,
      txRef: txRef,
    };
  } catch (error) {
    // Helpful debugging fallback: Log the EXACT text response from Chapa's API validators
    if (error.response && error.response.data) {
      logger.error(
        { chapaErrorDetails: error.response.data, adId },
        "Chapa API rejected payload parameters",
      );
    }

    // If the network call failed because of offline status/DNS issue, fall back to mock in dev/test mode
    if (
      process.env.NODE_ENV !== "production" &&
      (error.code === "ENOTFOUND" ||
        error.code === "ECONNREFUSED" ||
        error.code === "ETIMEDOUT")
    ) {
      const fallbackTxRef = `mock_tx_ref_${adId}_${Date.now()}`;
      logger.warn(
        { error: error.message, adId },
        "Chapa API unreachable. Falling back to Mock Payment Checkout for development/testing.",
      );
      return {
        checkoutUrl: `${frontendUrl}/advertise/success/${adId}?tx_ref=${fallbackTxRef}`,
        checkoutId: `mock_checkout_id_${adId}`,
        txRef: fallbackTxRef,
      };
    }

    logger.error(
      { error: error.message, adId },
      "Chappa payment initialization failed",
    );
    throw new Error("Failed to initialize payment");
  }
}
export async function verifyChappaPayment(txRef) {
  if (!txRef)
    throw new Error("Transaction reference token is required for verification");

  if (txRef.startsWith("mock_") || process.env.MOCK_CHAPPA === "true") {
    return {
      status: "success",
      reference: txRef,
      amount: 0,
    };
  }

  try {
    const response = await axios.get(
      `${CHAPPA_BASE_URL}/v1/transaction/verify/${txRef}`,
      {
        headers: {
          Authorization: `Bearer ${CHAPPA_SECRET_KEY}`,
        },
      },
    );

    return {
      status: response.data?.data?.status,
      reference: response.data?.data?.reference,
      amount: response.data?.data?.amount,
    };
  } catch (error) {
    if (error.response && error.response.data) {
      logger.error(
        { chapaVerifyDetails: error.response.data, txRef },
        "Chapa verification API error context",
      );
    }
    logger.error(
      { error: error.message, txRef },
      "Chappa payment verification failed",
    );
    throw new Error("Failed to verify payment");
  }
}
