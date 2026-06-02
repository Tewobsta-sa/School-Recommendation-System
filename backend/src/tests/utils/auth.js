import request from "supertest";
import app from "../../app.js";
import { db } from "../../config/db.js";

/**
 * Test helper: register a user, immediately mark their email as verified in
 * the DB (bypassing the real email flow), and log them in. Returns
 * `{ token, user }` for use in authenticated requests.
 *
 * This exists because Phase 1 gates login on `emailVerified === true`. Each
 * test suite would otherwise have to re-implement the same
 * register → flip → login dance for every fixture user.
 */
export async function registerVerifiedUser({
  fullName,
  email,
  phone,
  password = "123456",
  role,
}) {
  const registerRes = await request(app).post("/api/auth/register").send({
    fullName,
    email,
    phone,
    password,
    role,
  });

  if (registerRes.statusCode !== 201) {
    throw new Error(
      `registerVerifiedUser: register failed (${registerRes.statusCode}): ` +
        JSON.stringify(registerRes.body)
    );
  }

  // Mark verified directly in DB.
  await db.user.update({
    where: { email: email.toLowerCase() },
    data: {
      emailVerified: true,
      emailVerificationToken: null,
      emailVerificationExpires: null,
      phoneVerified: true,
      phoneVerificationToken: null,
      phoneVerificationExpires: null,
    },
  });

  const loginRes = await request(app).post("/api/auth/login").send({
    email,
    password,
  });

  if (loginRes.statusCode !== 200) {
    throw new Error(
      `registerVerifiedUser: login failed (${loginRes.statusCode}): ` +
        JSON.stringify(loginRes.body)
    );
  }

  return { token: loginRes.body.token, user: loginRes.body.user };
}
