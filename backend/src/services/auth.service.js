import bcrypt from "bcrypt";
import jwt from "jsonwebtoken";
import { db } from "../config/db.js";
import { sendMail } from "../config/mailer.js";
import { sendSMS } from "../config/sms.js";
import { logger } from "../config/logger.js";
import {
  ConflictError,
  NotFoundError,
  UnauthorizedError,
  ValidationError,
} from "../utils/errors.js";
import {
  EMAIL_VERIFICATION_TTL_MS,
  PASSWORD_RESET_TTL_MS,
  PHONE_VERIFICATION_TTL_MS,
  expiresAt,
  generateToken,
} from "../utils/tokens.js";

const SALT_ROUNDS = 10;

// 🔒 strip every sensitive field before returning user
function sanitizeUser(user) {
  const {
    password,
    emailVerificationToken,
    emailVerificationExpires,
    passwordResetToken,
    passwordResetExpires,
    phoneVerificationToken,
    phoneVerificationExpires,
    ...safeUser
  } = user;

  return safeUser;
}

function signToken(user) {
  return jwt.sign(
    { userId: user.id, role: user.role },
    process.env.JWT_SECRET,
    { expiresIn: process.env.JWT_EXPIRES_IN || "1d" },
  );
}

// Best-effort: swallow mail failures so the request still succeeds if SMTP
// is temporarily unavailable. Users can always re-request verification/reset.
async function sendMailSafe(payload, logCtx) {
  try {
    await sendMail(payload);
  } catch (err) {
    logger.warn({ err, ...logCtx }, "Email delivery failed");
  }
}

function appBaseUrl() {
  return process.env.APP_URL || "http://localhost:5050";
}

export function normalizePhone(phone) {
  const cleaned = phone.replace(/\s+/g, "");
  return cleaned;
}

// -----------------------------------------------------------------------------
// Register + verify email
// -----------------------------------------------------------------------------

export async function registerUser({ fullName, email, phone, password, role, subCity, officerRole }) {
  if (!fullName || !password || !role) {
    throw new ValidationError("Missing required fields");
  }

  if (!email && !phone) {
    throw new ValidationError("Either email or phone is required");
  }
  // Validate MOE_OFFICER specific fields
  if (role === "MOE_OFFICER" && (!subCity || !officerRole)) {
    throw new ValidationError("subCity and officerRole are required for MOE_OFFICER role");
  }  

  const normalizedEmail = email ? email.toLowerCase() : null;

  const normalizedPhone = phone ? normalizePhone(phone) : null;

  if (normalizedEmail) {
    const existingByEmail = await db.user.findUnique({
      where: {
        email: normalizedEmail,
      },
    });

    if (existingByEmail) {
      throw new ConflictError("Email already registered");
    }
  }

  // Prevent duplicate phone
  if (normalizedPhone) {
    const existingByPhone = await db.user.findUnique({
      where: {
        phone: normalizedPhone,
      },
    });

    if (existingByPhone) {
      throw new ConflictError("Phone already registered");
    }
  }

  const hashedPassword = await bcrypt.hash(password, SALT_ROUNDS);

  const emailVerificationToken = normalizedEmail ? generateToken() : null;

  const isPhoneSignup = !!normalizedPhone;

  let phoneVerificationToken = null;
  let phoneVerificationExpires = null;

  if (isPhoneSignup) {
    phoneVerificationToken = Math.floor(
      100000 + Math.random() * 900000,
    ).toString();

    phoneVerificationExpires = expiresAt(PHONE_VERIFICATION_TTL_MS);
  }

  /*
   |--------------------------------------------------------------------------
   | Create user
   |--------------------------------------------------------------------------
   */

  const user = await db.$transaction(async (tx) => {
  const newUser = await tx.user.create({
    data: {
      fullName,

      // Prisma requires email unique.
      // Phone-only accounts get placeholder email.
      email: normalizedEmail ?? `phone-${normalizedPhone}@placeholder.invalid`,

      phone: normalizedPhone,

      password: hashedPassword,

      accountStatus: "ACTIVE",

      role,
      emailVerified: !normalizedEmail,

      emailVerificationToken,

      emailVerificationExpires: emailVerificationToken
        ? expiresAt(EMAIL_VERIFICATION_TTL_MS)
        : null,

      /*
       |--------------------------------------------------------------------------
       | Phone verification
       |--------------------------------------------------------------------------
       */

      phoneVerified: !isPhoneSignup ? true : false,

      phoneVerificationToken,

      phoneVerificationExpires,
    },
  });

  // Create MoEOfficer profile if role is MOE_OFFICER
  if (role === "MOE_OFFICER") {
    await tx.moEOfficer.create({
      data: {
        userId: newUser.id,
        officerRole: officerRole,
        subCity: subCity,
      },
    });
  }

  return newUser;
});

  if (normalizedEmail && emailVerificationToken) {
    await sendMailSafe(
      {
        to: normalizedEmail,

        subject: "Verify your School Recommendation account",

        text:
          `Hi ${fullName},\n\n` +
          `Welcome! Please verify your email by visiting:\n\n` +
          `${appBaseUrl()}/verify-email?token=${emailVerificationToken}\n\n` +
          `The link expires in 24 hours.`,
      },
      {
        event: "register",
        userId: user.id,
      },
    );
  }

  if (normalizedPhone && phoneVerificationToken) {
    try {
      await sendSMS({
        to: normalizedPhone,
        message: `Your School Recommendation verification code is ${phoneVerificationToken}`,
      });

      console.log("SMS verification sent to", normalizedPhone);
    } catch (e) {
      console.error("SMS failed:", e.message);
    }
  }

  return sanitizeUser(user);
}

export async function verifyEmail({ token }) {
  if (!token) throw new ValidationError("Verification token is required");

  const user = await db.user.findUnique({
    where: { emailVerificationToken: token },
  });
  if (!user) throw new ValidationError("Invalid verification token");

  if (
    user.emailVerificationExpires &&
    user.emailVerificationExpires < new Date()
  ) {
    throw new ValidationError("Verification token has expired");
  }

  if (user.emailVerified) {
    // Idempotent — clear any stale token anyway.
    await db.user.update({
      where: { id: user.id },
      data: { emailVerificationToken: null, emailVerificationExpires: null },
    });
    return { alreadyVerified: true };
  }

  await db.user.update({
    where: { id: user.id },
    data: {
      emailVerified: true,
      emailVerificationToken: null,
      emailVerificationExpires: null,
    },
  });
  return { alreadyVerified: false };
}

export async function verifyPhone({ token }) {
  if (!token) {
    throw new ValidationError("Verification token is required");
  }

  const user = await db.user.findUnique({
    where: {
      phoneVerificationToken: token,
    },
  });

  if (!user) {
    throw new ValidationError("Invalid verification token");
  }

  if (
    user.phoneVerificationExpires &&
    user.phoneVerificationExpires < new Date()
  ) {
    throw new ValidationError("Verification token expired");
  }

  await db.user.update({
    where: {
      id: user.id,
    },
    data: {
      phoneVerified: true,
      phoneVerificationToken: null,
      phoneVerificationExpires: null,
    },
  });

  return {
    success: true,
  };
}

export async function resendVerificationEmail({ email }) {
  const normalizedEmail = email.toLowerCase();
  const user = await db.user.findUnique({ where: { email: normalizedEmail } });

  // Do not leak which addresses exist — always return success-shaped payload.
  if (!user || user.emailVerified) return { sent: false };

  const verificationToken = generateToken();
  await db.user.update({
    where: { id: user.id },
    data: {
      emailVerificationToken: verificationToken,
      emailVerificationExpires: expiresAt(EMAIL_VERIFICATION_TTL_MS),
    },
  });

  await sendMailSafe(
    {
      to: normalizedEmail,
      subject: "Verify your School Recommendation account",
      text:
        `Hi ${user.fullName},\n\n` +
        `Here is a fresh verification link (expires in 24 hours):\n` +
        `${appBaseUrl()}/verify-email?token=${verificationToken}`,
    },
    { event: "resend_verification", userId: user.id },
  );
  return { sent: true };
}

export async function resendVerificationPhone({ phone }) {
  if (!phone) throw new ValidationError("Phone is required");

  const normalizedPhone = normalizePhone(phone);

  const user = await db.user.findUnique({ where: { phone: normalizedPhone } });

  // Do not leak whether the phone exists — always return success-shaped payload.
  if (!user || user.phoneVerified) return { sent: false };

  // Generate a fresh 6-digit OTP
  const phoneVerificationToken = Math.floor(
    100000 + Math.random() * 900000,
  ).toString();
  const phoneVerificationExpires = expiresAt(PHONE_VERIFICATION_TTL_MS);

  await db.user.update({
    where: { id: user.id },
    data: {
      phoneVerificationToken,
      phoneVerificationExpires,
    },
  });

  try {
    await sendSMS({
      to: normalizedPhone,
      message: `Your School Recommendation verification code is ${phoneVerificationToken}`,
    });
    logger.info({ userId: user.id }, "Phone verification SMS resent");
  } catch (err) {
    logger.warn(
      { err, userId: user.id },
      "Phone verification SMS failed on resend",
    );
  }

  return { sent: true };
}

// -----------------------------------------------------------------------------
// Login
// -----------------------------------------------------------------------------

export async function loginUser({ identifier, email, password }) {
  // Accept either the new `identifier` field (email or phone) or the legacy
  // `email` field so older clients still work. Validator guarantees at least
  // one is present.
  const raw = (identifier ?? email ?? "").trim();
  if (!raw || !password) {
    throw new ValidationError("identifier and password are required");
  }

  // Phone numbers are 5-15 digits — anything containing "@" is treated as an
  // email lookup, everything else as a phone lookup. This is intentional:
  // backend stores phones verbatim (no normalization), so a digit-only
  // identifier maps 1:1 to the `phone` column.
  let user;
  if (raw.includes("@")) {
    const normalizedEmail = raw.toLowerCase();
    user = await db.user.findUnique({ where: { email: normalizedEmail } });
  } else {
    user = await db.user.findUnique({ where: { phone: raw } });
  }

  if (!user) throw new UnauthorizedError("Invalid credentials");

  if (user.accountStatus !== "ACTIVE") {
    if (user.accountStatus === "SELF_DEACTIVATED") {
      const err = new UnauthorizedError("Account is self-deactivated");
      err.code = "ACCOUNT_SELF_DEACTIVATED";
      throw err;
    }
    // Account is deactivated by moderator (banned) - fetch ban reason
    let banReason = "Account is banned due to violations of terms and services";
    
    try {
      // Find the most recent BAN_USER action that affected this user
      // by checking reports on content created by this user
      const banAction = await db.moderatorAction.findFirst({
        where: {
          actionType: "BAN_USER",
          report: {
            OR: [
              { targetType: "REVIEW", targetId: { in: await getUserReviewIds(user.id) } },
              { targetType: "ANNOUNCEMENT", targetId: { in: await getUserAnnouncementIds(user.id) } },
              { targetType: "FORUM_POST", targetId: { in: await getUserForumPostIds(user.id) } },
              { targetType: "SCHOOL", targetId: { in: await getUserSchoolIds(user.id) } },
            ]
          }
        },
        include: {
          report: true
        },
        orderBy: { actionDate: "desc" }
      });
      
      if (banAction && banAction.notes) {
        banReason = `Account banned: ${banAction.notes}`;
      } else if (banAction && banAction.report) {
        banReason = `Account banned due to: ${banAction.report.reason}`;
      }
    } catch (err) {
      logger.warn({ err, userId: user.id }, "Failed to fetch ban reason");
    }
    
    const error = new UnauthorizedError(banReason);
    error.code = "ACCOUNT_BANNED";
    throw error;
  }

  const match = await bcrypt.compare(password, user.password);
  if (!match) throw new UnauthorizedError("Invalid credentials");
  if (user.phone && !user.phoneVerified) {
    const err = new UnauthorizedError("Phone not verified");

    err.code = "PHONE_NOT_VERIFIED";

    throw err;
  }

  const verified = user.emailVerified && user.phoneVerified;

  if (!verified) {
    const err = new UnauthorizedError("Account not verified");

    err.code = "ACCOUNT_NOT_VERIFIED";

    throw err;
  }
  return { token: signToken(user), user: sanitizeUser(user) };
}

// -----------------------------------------------------------------------------
// Forgot / reset password
// -----------------------------------------------------------------------------

export async function requestPasswordReset({ email }) {
  const normalizedEmail = email.toLowerCase();
  const user = await db.user.findUnique({ where: { email: normalizedEmail } });

  // Do not leak existence — always act like success.
  if (!user || user.accountStatus !== "ACTIVE") return { sent: false };

  const resetToken = generateToken();
  await db.user.update({
    where: { id: user.id },
    data: {
      passwordResetToken: resetToken,
      passwordResetExpires: expiresAt(PASSWORD_RESET_TTL_MS),
    },
  });

  await sendMailSafe(
    {
      to: normalizedEmail,
      subject: "Reset your School Recommendation password",
      text:
        `Hi ${user.fullName},\n\n` +
        `Someone (hopefully you) asked to reset your password.\n` +
        `Use this link within 1 hour:\n` +
        `${appBaseUrl()}/reset-password?token=${resetToken}\n\n` +
        `If you didn't request this, ignore this email.`,
    },
    { event: "forgot_password", userId: user.id },
  );
  return { sent: true };
}

export async function resetPassword({ token, newPassword }) {
  if (!token || !newPassword) {
    throw new ValidationError("Token and newPassword are required");
  }

  const user = await db.user.findUnique({
    where: { passwordResetToken: token },
  });
  if (!user) throw new ValidationError("Invalid reset token");
  if (user.passwordResetExpires && user.passwordResetExpires < new Date()) {
    throw new ValidationError("Reset token has expired");
  }

  const hashed = await bcrypt.hash(newPassword, SALT_ROUNDS);
  await db.user.update({
    where: { id: user.id },
    data: {
      password: hashed,
      passwordResetToken: null,
      passwordResetExpires: null,
    },
  });
}

// -----------------------------------------------------------------------------
// Change password (authenticated)
// -----------------------------------------------------------------------------

export async function changePassword({ userId, currentPassword, newPassword }) {
  if (!currentPassword || !newPassword) {
    throw new ValidationError("currentPassword and newPassword are required");
  }
  if (currentPassword === newPassword) {
    throw new ValidationError("New password must differ from current password");
  }

  const user = await db.user.findUnique({ where: { id: userId } });
  if (!user) throw new NotFoundError("User not found");

  const match = await bcrypt.compare(currentPassword, user.password);
  if (!match) throw new UnauthorizedError("Current password is incorrect");

  const hashed = await bcrypt.hash(newPassword, SALT_ROUNDS);
  await db.user.update({ where: { id: userId }, data: { password: hashed } });
}

export async function reactivateAccount({ identifier, password }) {
  const raw = identifier.trim();
  if (!raw || !password) {
    throw new ValidationError("identifier and password are required");
  }

  let user;
  if (raw.includes("@")) {
    const normalizedEmail = raw.toLowerCase();
    user = await db.user.findUnique({ where: { email: normalizedEmail } });
  } else {
    user = await db.user.findUnique({ where: { phone: raw } });
  }

  if (!user) throw new UnauthorizedError("Invalid credentials");

  if (user.accountStatus !== "SELF_DEACTIVATED") {
    throw new UnauthorizedError("Account cannot be reactivated");
  }

  const match = await bcrypt.compare(password, user.password);
  if (!match) throw new UnauthorizedError("Invalid credentials");

  await db.user.update({
    where: { id: user.id },
    data: { accountStatus: "ACTIVE", deactivatedAt: null },
  });

  return { token: signToken(user), user: sanitizeUser(user) };
}

// Helper functions to get user content IDs for ban reason lookup
async function getUserReviewIds(userId) {
  const reviews = await db.review.findMany({
    where: { parentId: userId },
    select: { id: true }
  });
  return reviews.map(r => r.id);
}

async function getUserAnnouncementIds(userId) {
  const announcements = await db.announcement.findMany({
    where: { publisherId: userId },
    select: { id: true }
  });
  return announcements.map(a => a.id);
}

async function getUserForumPostIds(userId) {
  const posts = await db.discussionForum.findMany({
    where: { authorId: userId },
    select: { id: true }
  });
  return posts.map(p => p.id);
}

async function getUserSchoolIds(userId) {
  const schools = await db.school.findMany({
    where: { adminId: userId },
    select: { id: true }
  });
  return schools.map(s => s.id);
}
