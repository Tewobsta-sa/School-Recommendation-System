import { db } from "../config/db.js";
import { NotFoundError } from "../utils/errors.js";
import bcrypt from "bcrypt";
import { UnauthorizedError, ValidationError } from "../utils/errors.js";
import { recomputeSchoolRating } from "./review.service.js";

const PUBLIC_USER_SELECT = {
  id: true,
  fullName: true,
  email: true,
  phone: true,
  role: true,
  accountStatus: true,
  emailVerified: true,
  createdAt: true,
  updatedAt: true,
};

export async function getMe(userId) {
  const user = await db.user.findUnique({
    where: { id: userId },
    select: PUBLIC_USER_SELECT,
  });
  if (!user) throw new NotFoundError("User not found");
  return user;
}

export async function updateMe(userId, { fullName, phone }) {
  // Only allow these two — email/role/status changes are separate flows.
  const data = {};
  if (fullName !== undefined) data.fullName = fullName;
  if (phone !== undefined) data.phone = phone;

  const user = await db.user.update({
    where: { id: userId },
    data,
    select: PUBLIC_USER_SELECT,
  });
  return user;
}

export async function deactivateMe(userId) {
  const user =await db.user.update({  
  where: { id: userId },  
  data: {   
    accountStatus: "SELF_DEACTIVATED",  
    deactivatedAt: new Date()   
  },  
});
  return user;
}

export async function enforceDeactivationLimit() {  
  const cutoff = new Date();  
  cutoff.setDate(cutoff.getDate() - 30);  
  
  await db.user.updateMany({  
    where: {  
      accountStatus: "SELF_DEACTIVATED",  
      deactivatedAt: { lt: cutoff }  
    },  
    data: { accountStatus: "DEACTIVATED" }  
  });  
}

export async function deleteMePermanently(userId, password) {
  // Verify password first for security.
  // Also include relation presence flags so we know which profiles to clean up.
  const user = await db.user.findUnique({
    where: { id: userId },
    include: {
      parentProfile: true,
      moeOfficerProfile: true,
    },
  });
  if (!user) throw new NotFoundError("User not found");

  const match = await bcrypt.compare(password, user.password);
  if (!match) throw new UnauthorizedError("Invalid password");

  // Prevent deletion if user administers any schools (check early to fail fast).
  const administeredSchools = await db.school.findMany({ where: { adminId: userId } });
  if (administeredSchools.length > 0) {
    throw new ValidationError(
      "Cannot delete account that administers schools. Please transfer ownership or delete schools first."
    );
  }

  // ── 1. Likes posted BY this user ──────────────────────────────────────────
  await db.like.deleteMany({ where: { userId } });

  // ── 2. Likes posted by OTHER users on THIS user's forum posts/announcements ─
  // Must be removed before the target records are deleted.
  const userForumPostIds = (
    await db.discussionForum.findMany({ where: { authorId: userId }, select: { id: true } })
  ).map((p) => p.id);
  if (userForumPostIds.length > 0) {
    await db.like.deleteMany({
      where: { targetType: "FORUM_POST", targetId: { in: userForumPostIds } },
    });
  }

  const userAnnouncementIds = (
    await db.announcement.findMany({ where: { publisherId: userId }, select: { id: true } })
  ).map((a) => a.id);
  if (userAnnouncementIds.length > 0) {
    await db.like.deleteMany({
      where: { targetType: "ANNOUNCEMENT", targetId: { in: userAnnouncementIds } },
    });
  }

  // ── 3. Notifications received by this user ────────────────────────────────
  await db.notification.deleteMany({ where: { recipientId: userId } });

  // ── 4. Moderator actions performed by this user ───────────────────────────
  await db.moderatorAction.deleteMany({ where: { moderatorId: userId } });

  // ── 5. Reports submitted by this user ────────────────────────────────────
  await db.report.deleteMany({ where: { reporterId: userId } });

  // ── 6. Forum posts (replies first, then top-level threads) ───────────────
  await db.discussionForum.deleteMany({ where: { authorId: userId, threadId: { not: null } } });
  await db.discussionForum.deleteMany({ where: { authorId: userId } });

  // ── 7. Announcements published by this user ───────────────────────────────
  await db.announcement.deleteMany({ where: { publisherId: userId } });

  // ── 8. Reviews (recalculate school ratings after each deletion) ───────────
  const reviews = await db.review.findMany({ where: { parentId: userId } });
  for (const review of reviews) {
    await db.review.delete({ where: { id: review.id } });
    await recomputeSchoolRating(review.schoolId);
  }

  // ── 9. Favorites & subscriptions ─────────────────────────────────────────
  await db.favorite.deleteMany({ where: { parentId: userId } });
  await db.subscription.deleteMany({ where: { parentId: userId } });

  // ── 10. Verification requests ─────────────────────────────────────────────
  await db.verificationRequest.deleteMany({ where: { submittedById: userId } });
  await db.verificationRequest.updateMany({
    where: { reviewedById: userId },
    data: { reviewedById: null },
  });

  // ── 11. Recommendation histories ──────────────────────────────────────────
  const histories = await db.recommendationHistory.findMany({ where: { parentId: userId } });
  for (const history of histories) {
    await db.recommendationPreferenceCriteria.deleteMany({ where: { recommendationId: history.id } });
    await db.recommendedSchool.deleteMany({ where: { recommendationId: history.id } });
  }
  await db.recommendationHistory.deleteMany({ where: { parentId: userId } });

  // ── 12. Comparisons ───────────────────────────────────────────────────────
  const comparisons = await db.comparison.findMany({ where: { parentId: userId } });
  for (const comparison of comparisons) {
    await db.comparisonSchool.deleteMany({ where: { comparisonId: comparison.id } });
  }
  await db.comparison.deleteMany({ where: { parentId: userId } });

  // ── 13. Role-specific profiles ────────────────────────────────────────────
  // NOTE: parentProfile / moeOfficerProfile are loaded via `include` above,
  // so these checks are now reliable (previously findUnique had no `include`,
  // making both properties always undefined and skipping the cleanup).
  if (user.parentProfile) {
    await db.preference.deleteMany({ where: { parentId: userId } });
    await db.parent.delete({ where: { userId } });
  }
  if (user.moeOfficerProfile) {
    await db.moEOfficer.delete({ where: { userId } });
  }

  // ── 14. Finally, delete the user row itself ───────────────────────────────
  await db.user.delete({ where: { id: userId } });

  return { message: "Account permanently deleted" };
}