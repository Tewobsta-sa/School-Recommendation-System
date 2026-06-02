import express from "express";
import cors from "cors";
import helmet from "helmet";
import rateLimit from "express-rate-limit";
import swaggerUi from "swagger-ui-express";

import { httpLogger } from "./config/logger.js";
import { openApiSpec } from "./config/openapi.js";
import { UPLOAD_DIR } from "./config/uploads.js";
import {
  errorHandler,
  notFoundHandler,
} from "./middlewares/error.middleware.js";

import trainingRoutes from "./routes/training.routes.js";

import demographicsRoutes from "./routes/demographics.routes.js";
import analyticsRoutes from "./routes/analytics.routes.js";  

const app = express();

// --- Security + infra middleware ---------------------------------------------
app.use(helmet());
app.use(cors());
app.use(express.json({ limit: "1mb" }));
app.use(httpLogger);

//increase timeout
app.use((req, res, next) => {
  req.setTimeout(60000); // 60s
  res.setTimeout(60000);
  next();
});

app.use((req, res, next) => {
  const originalJson = res.json;

  res.json = function (body) {
    req.log.info(
      {
        statusCode: res.statusCode,
        responseBody: body,
      },
      "Outgoing response"
    );

    return originalJson.call(this, body);
  };

  next();
});

// Basic global rate limit to protect against brute-force + accidental loops.
const globalLimiter = rateLimit({
  windowMs: 60 * 1000, // 1 minute
  limit: 300, // 300 req/min/IP — well above normal usage, blocks abuse
  standardHeaders: "draft-7",
  legacyHeaders: false,
});

// Tighter limit on /api/auth/* — resists credential stuffing + reset spam.
const authLimiter = rateLimit({
  windowMs: 10 * 60 * 1000, // 10 minutes
  limit: 20, // 20 req/10min/IP across all auth endpoints
  standardHeaders: "draft-7",
  legacyHeaders: false,
  message: {
    error: "Too many auth requests, try again later",
    code: "RATE_LIMITED",
  },
});

if (process.env.NODE_ENV !== "test") {
  app.use(globalLimiter);
  app.use("/api/auth", authLimiter);
}

// --- Health + docs -----------------------------------------------------------
app.get("/", (req, res) => {
  res.send("API running");
});

app.get("/api/healthz", (req, res) => {
  res.json({ status: "ok" });
});

app.use("/api/docs", swaggerUi.serve, swaggerUi.setup(openApiSpec));
app.get("/api/docs.json", (req, res) => res.json(openApiSpec));

// --- Static uploads -----------------------------------------------------------
// Files saved by the multer pipeline land under UPLOAD_DIR; expose them
// read-only at /uploads/* so the frontend can render document previews.
app.use("/uploads", express.static(UPLOAD_DIR, { fallthrough: true }));

// --- Feature routes ----------------------------------------------------------
app.use("/api/auth", (await import("./routes/auth.routes.js")).default);
app.use("/api/users", (await import("./routes/user.routes.js")).default);
app.use("/api/schools", (await import("./routes/school.routes.js")).default);
app.use("/api/demographics", demographicsRoutes);
// Follow/subscribe + my-follows. Mounted under two paths so the
// URL structure mirrors the conceptual model.
const subscriptionRoutes = await import("./routes/subscription.routes.js");
app.use("/api/schools/:schoolId/follow", subscriptionRoutes.schoolFollowRouter);
app.use("/api/me/follows", subscriptionRoutes.myFollowsRouter);

// Side-by-side comparisons.
app.use(
  "/api/comparisons",
  (await import("./routes/comparison.routes.js")).default,
);
app.use(
  "/api/recommendations",
  (await import("./routes/recommendation.routes.js")).default,
);
app.use(
  "/api/preferences",
  (await import("./routes/preference.routes.js")).default,
);
app.use(
  "/api/favorites",
  (await import("./routes/favorite.routes.js")).default,
);
app.use("/api/reviews", (await import("./routes/review.routes.js")).default);
app.use(
  "/api/announcements",
  (await import("./routes/announcement.routes.js")).default,
);
app.use("/api/reports", (await import("./routes/report.routes.js")).default);
// Discussion forum (threaded posts + replies, content moderated).
app.use("/api/forum", (await import("./routes/forum.routes.js")).default);
app.use(
  "/api/notifications",
  (await import("./routes/notification.routes.js")).default,
);
app.use(
  "/api/analytics",
  (await import("./routes/analytics.routes.js")).default,
);
app.use("/api/likes", (await import("./routes/like.routes.js")).default);
app.use("/api/ads", (await import("./routes/ad.routes.js")).default);

app.use("/api", (await import("./routes/achievement.routes.js")).default);
app.use("/api", analyticsRoutes);

// School-verification workflow. The router registers paths under
// both /api/schools/:id/verification-requests (submit) and
// /api/verification-requests/* (list/get/review), so it's mounted at /api.
app.use("/api", (await import("./routes/verification.routes.js")).default);
app.use("/api/training-data", trainingRoutes);

// Dev-only utility routes — never mount in production.
if (process.env.NODE_ENV !== "production") {
  app.use("/api/test", (await import("./routes/test.routes.js")).default);
}

// --- Error handling (must be last) -------------------------------------------
app.use(notFoundHandler);
app.use(errorHandler);

export default app;
