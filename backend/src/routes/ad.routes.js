import express from "express";

import { adImageUpload } from "../config/uploads.js";
import { authenticate } from "../middlewares/auth.middleware.js";
import { authorizeRoles } from "../middlewares/role.middleware.js";
import { validate } from "../middlewares/validate.middleware.js";
import { idParamsSchema } from "../schemas/common.schema.js";
import {
  submitAdRequestBodySchema,
  listActiveAdsQuerySchema,
  listAdminAdsQuerySchema,
  rejectAdBodySchema,
  adAnalyticsQuerySchema,
} from "../schemas/ad.schema.js";
import {
  requestAd,
  getRequestStatus,
  getPaymentDetails,
  getActive,
  trackImpression,
  trackClick,
  getPricing,
  adminList,
  adminApprove,
  adminReject,
  adminAnalytics,
} from "../controllers/ad.controller.js";

import {  
  initializePayment,  
  chappaCallback,  
  verifyPaymentStatus,  
} from "../controllers/ad.controller.js";

const router = express.Router();

/**
 * @openapi
 * /api/ads/pricing:
 *   get:
 *     tags: [Advertisements]
 *     summary: Public pricing rules (ETB per day by placement)
 */
router.get("/pricing", getPricing);

/**
 * @openapi
 * /api/ads/active:
 *   get:
 *     tags: [Advertisements]
 *     summary: List publicly visible active ads
 */
router.get(
  "/active",
  validate({ query: listActiveAdsQuerySchema }),
  getActive
);

/**
 * @openapi
 * /api/ads/request:
 *   post:
 *     tags: [Advertisements]
 *     summary: Submit an advertisement request (no account required)
 */
router.post(
  "/request",
  adImageUpload,
  validate({ body: submitAdRequestBodySchema }),
  requestAd
);

/**
 * @openapi
 * /api/ads/request/{id}:
 *   get:
 *     tags: [Advertisements]
 *     summary: Check advertisement request + payment status
 */
router.get(
  "/request/:id",
  validate({ params: idParamsSchema }),
  getRequestStatus
);

router.get(
  "/pay/:id",
  validate({ params: idParamsSchema }),
  getPaymentDetails
);

/**
 * @openapi
 * /api/ads/{id}/payment:
 *   post:
 *     tags: [Advertisements]
 *     summary: Submit one-time payment details for an ad request
 */

router.post(
  "/:id/impression",
  validate({ params: idParamsSchema }),
  trackImpression
);

router.post(
  "/:id/click",
  validate({ params: idParamsSchema }),
  trackClick
);

// --- Admin (MODERATOR) -------------------------------------------------------

router.get(
  "/admin/list",
  authenticate,
  authorizeRoles("MODERATOR"),
  validate({ query: listAdminAdsQuerySchema }),
  adminList
);

router.get(
  "/admin/analytics",
  authenticate,
  authorizeRoles("MODERATOR"),
  validate({ query: adAnalyticsQuerySchema }),
  adminAnalytics
);

router.post(
  "/admin/:id/approve",
  authenticate,
  authorizeRoles("MODERATOR"),
  validate({ params: idParamsSchema }),
  adminApprove
);

router.post(
  "/admin/:id/reject",
  authenticate,
  authorizeRoles("MODERATOR"),
  validate({ params: idParamsSchema, body: rejectAdBodySchema }),
  adminReject
);

router.get(  
  "/:id/payment/initiate",  
  validate({ params: idParamsSchema }),  
  initializePayment  
);  
  
router.post(  
  "/chappa/callback",  
  chappaCallback  
);

router.get(
  "/:id/verify-payment", 
  validate({ params: idParamsSchema }), 
  verifyPaymentStatus
);


export default router;
