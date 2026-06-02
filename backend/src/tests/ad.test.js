import request from "supertest";
import app from "../app.js";
import { db } from "../config/db.js";
import { registerVerifiedUser } from "./utils/auth.js";
import axios from "axios";
import { jest } from "@jest/globals";

// Monkey-patch axios instead of jest.mock to support experimental Jest ESM/VM modules
const originalPost = axios.post;
const originalGet = axios.get;

let mockPostFn = jest.fn();
let mockGetFn = jest.fn();

axios.post = mockPostFn;
axios.get = mockGetFn;

let moderatorToken;
let adId;

async function cleanAdsOnly() {
  await db.advertisement.deleteMany();
  await db.payment.deleteMany();
}

beforeAll(async () => {
  await cleanAdsOnly();
  ({ token: moderatorToken } = await registerVerifiedUser({
    fullName: "Ad Moderator",
    email: `mod-ads-${Date.now()}@test.com`,
    phone: `0911${String(Date.now()).slice(-6)}`,
    role: "MODERATOR",
  }));
}, 30_000);

afterAll(async () => {
  await cleanAdsOnly();
  // Restore original axios methods
  axios.post = originalPost;
  axios.get = originalGet;
  await db.$disconnect();
});

describe("Advertisement API", () => {
  beforeEach(() => {
    mockPostFn.mockReset();
    mockGetFn.mockReset();
  });

  it("returns public pricing", async () => {
    const res = await request(app).get("/api/ads/pricing");
    expect(res.statusCode).toBe(200);
    expect(res.body.pricing.rates.BANNER).toBe(1000);
  });

  it("creates a review-pending request without payment", async () => {
    const res = await request(app)
      .post("/api/ads/request")
      .field("companyName", "Bright Future Supplies")
      .field("contactEmail", "advertiser@test.com")
      .field("contactPhone", "0911223344")
      .field("title", "Back to School Sale")
      .field("targetUrl", "https://example.com/sale")
      .field("durationDays", "7")
      .field("placementType", "BANNER");

    expect(res.statusCode).toBe(201);
    expect(res.body.advertisement.status).toBe("PENDING_REVIEW");
    expect(res.body.advertisement.payment).toBeUndefined();
    expect(res.body.pricing.amountEtb).toBe(7000);

    adId = res.body.advertisement.id;
  });

  it("rejects payment before moderator approval", async () => {
    const res = await request(app).get(`/api/ads/${adId}/payment/initiate`);
    expect(res.statusCode).toBe(409);
  });

  it("moderator approves and emails payment instructions", async () => {
    const res = await request(app)
      .post(`/api/ads/admin/${adId}/approve`)
      .set("Authorization", `Bearer ${moderatorToken}`);

    expect(res.statusCode).toBe(200);
    expect(res.body.advertisement.status).toBe("AWAITING_PAYMENT");
    expect(Number(res.body.advertisement.payment.amount)).toBe(7000);
    if (process.env.NODE_ENV === "test" && globalThis.__lastMail) {
      expect(globalThis.__lastMail.to).toBe("advertiser@test.com");
      expect(globalThis.__lastMail.text).toContain(`/advertise/pay/${adId}`);
    }
  });

  it("exposes pay details for approved ad", async () => {
    const res = await request(app).get(`/api/ads/pay/${adId}`);
    expect(res.statusCode).toBe(200);
    expect(res.body.advertisement.status).toBe("AWAITING_PAYMENT");
  });

  it("initializes payment with Chappa", async () => {
    const txRef = `mock_tx_ref_${adId}`;
    mockPostFn.mockResolvedValueOnce({
      data: {
        status: "success",
        data: {
          checkout_url: "https://mock.chappa.co/checkout",
          id: "mock_checkout_id",
        },
        tx_ref: txRef,
      },
    });

    const res = await request(app).get(`/api/ads/${adId}/payment/initiate`);

    expect(res.statusCode).toBe(200);
    expect(res.body.paymentUrl).toBe("https://mock.chappa.co/checkout");
    expect(res.body.checkoutId).toBe("mock_checkout_id");
  });

  it("activates ad after successful callback", async () => {
    const txRef = `mock_tx_ref_${adId}`;
    mockGetFn.mockResolvedValueOnce({
      data: {
        status: "success",
        data: {
          status: "success",
          reference: "mock_reference",
          amount: 7000,
        },
      },
    });

    // Send callback to simulate successful payment
    const callbackRes = await request(app)
      .post("/api/ads/chappa/callback")
      .send({ tx_ref: txRef });

    expect(callbackRes.statusCode).toBe(200);

    // Verify advertisement has been activated
    const res = await request(app).get(`/api/ads/request/${adId}`);
    expect(res.statusCode).toBe(200);
    expect(res.body.advertisement.status).toBe("ACTIVE");
    expect(res.body.advertisement.payment.status).toBe("COMPLETED");
    expect(res.body.advertisement.startDate).toBeTruthy();
    expect(res.body.advertisement.endDate).toBeTruthy();
  });

  it("lists active ads publicly", async () => {
    const res = await request(app)
      .get("/api/ads/active")
      .query({ placement: "BANNER" });

    expect(res.statusCode).toBe(200);
    expect(res.body.data.some((a) => a.id === adId)).toBe(true);
  });
});
