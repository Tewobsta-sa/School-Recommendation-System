import { z } from "zod";

import { paginationQuery } from "./common.schema.js";

const placementEnum = z.enum(["BANNER", "POPUP"]);
const adStatusEnum = z.enum([
  "PENDING_REVIEW",
  "AWAITING_PAYMENT",
  "PENDING_PAYMENT",
  "PAYMENT_PENDING_VERIFICATION",
  "ACTIVE",
  "REJECTED",
  "EXPIRED",
]);

export const submitAdRequestBodySchema = z.object({
  companyName: z.string().trim().min(2).max(150),
  contactEmail: z.string().trim().email().max(100),
  contactPhone: z
    .string()
    .trim()
    .min(9)
    .max(15)
    .regex(/^\+?[0-9]+$/, "Invalid phone number"),
  title: z.string().trim().min(3).max(150),
  description: z.string().trim().max(5000).optional(),
  targetUrl: z.string().trim().url().max(255),
  durationDays: z.coerce.number().int().min(1).max(365),
  placementType: placementEnum.default("BANNER"),
});

export const listActiveAdsQuerySchema = z.object({
  placement: placementEnum.optional(),
  limit: z.coerce.number().int().positive().max(20).default(5),
});

export const listAdminAdsQuerySchema = z.object({
  ...paginationQuery,
  status: adStatusEnum.optional(),
});

export const rejectAdBodySchema = z.object({
  reason: z.string().trim().min(3).max(2000).optional(),
});

export const adAnalyticsQuerySchema = z.object({
  ...paginationQuery,
});
