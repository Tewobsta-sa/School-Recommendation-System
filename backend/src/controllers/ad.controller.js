import { asyncHandler } from "../middlewares/async.middleware.js";
import { relativeUrl } from "../config/uploads.js";
import {
  createAdRequest,
  getAdRequestStatus,
  getAdForPayment,
  listActiveAds,
  recordImpression,
  recordClick,
  listAdsForAdmin,
  approveAd,
  rejectAd,
  getAdPricingInfo,
  getAdRevenueAnalytics,
  initializeAdPayment,
  handleChappaCallback,
  verifyAdPayment,
} from "../services/ad.service.js";

export const requestAd = asyncHandler(async (req, res) => {
  const imageUrl = relativeUrl(req.file);

  const result = await createAdRequest({
    ...req.body,
    imageUrl,
  });

  res.status(201).json(result);
});

export const getPaymentDetails = asyncHandler(async (req, res) => {
  const result = await getAdForPayment(req.params.id);
  res.json({ message: "Advertisement ready for payment", ...result });
});

export const getRequestStatus = asyncHandler(async (req, res) => {
  const result = await getAdRequestStatus(req.params.id);
  res.json({ message: "Advertisement request fetched", ...result });
});

export const getActive = asyncHandler(async (req, res) => {
  const result = await listActiveAds(req.query);
  res.json({ message: "Active advertisements", ...result });
});

export const trackImpression = asyncHandler(async (req, res) => {
  await recordImpression(req.params.id);
  res.status(204).send();
});

export const trackClick = asyncHandler(async (req, res) => {
  const result = await recordClick(req.params.id);
  res.json({ message: "Click recorded", ...result });
});

export const getPricing = asyncHandler(async (req, res) => {
  const pricing = await getAdPricingInfo();
  res.json({ message: "Advertisement pricing", pricing });
});

export const adminList = asyncHandler(async (req, res) => {
  const result = await listAdsForAdmin({ query: req.query });
  res.json({ message: "Advertisements fetched", ...result });
});

export const adminApprove = asyncHandler(async (req, res) => {
  const ad = await approveAd({ adId: req.params.id });
  res.json({
    message:
      "Advertisement approved. Payment instructions were emailed to the advertiser.",
    advertisement: ad,
  });
});

export const adminReject = asyncHandler(async (req, res) => {
  const ad = await rejectAd({
    adId: req.params.id,
    reason: req.body.reason,
  });
  res.json({ message: "Advertisement rejected", advertisement: ad });
});

export const adminAnalytics = asyncHandler(async (req, res) => {
  const result = await getAdRevenueAnalytics({ query: req.query });
  res.json({ message: "Advertisement analytics", ...result });
});

export const initializePayment = asyncHandler(async (req, res) => {
  const result = await initializeAdPayment({ adId: req.params.id });
  res.json({ message: "Payment initialized", ...result });
});

export const chappaCallback = asyncHandler(async (req, res) => {
  const result = await handleChappaCallback({ txRef: req.body.tx_ref });
  res.json({ message: "Payment processed successfully", ...result });
});

export const verifyPaymentStatus = asyncHandler(async (req, res) => {
  const ad = await verifyAdPayment(req.params.id);
  res.json({ message: "Payment status verified", advertisement: ad });
});

