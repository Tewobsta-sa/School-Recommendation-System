import { db } from "../../config/db.js";

export const cleanDatabase = async () => {
  // Order matters: delete dependent rows before their parents to respect FKs.
  await db.advertisement.deleteMany();
  await db.payment.deleteMany();
  await db.analytics.deleteMany();
  await db.notification.deleteMany();
  await db.moderatorAction.deleteMany();
  await db.report.deleteMany();
  await db.review.deleteMany();
  await db.announcement.deleteMany();
  await db.favorite.deleteMany();
  await db.preference.deleteMany();
  await db.recommendationPreferenceCriteria.deleteMany();
  await db.recommendedSchool.deleteMany();
  await db.recommendationHistory.deleteMany();
  // Phase 2: subscription + verification_request hold FKs to school + user.
  await db.subscription.deleteMany();
  await db.verificationRequest.deleteMany();
  // Phase 4: comparison + comparison_school join.
  await db.comparisonSchool.deleteMany();
  await db.comparison.deleteMany();
  // Phase 5: discussion_forum holds FK to user. Delete replies first so
  // the self-referential FK on threadId doesn't block the parent rows.
  await db.discussionForum.deleteMany({ where: { threadId: { not: null } } });
  await db.discussionForum.deleteMany();
  // Phase 11: facility images FK to School — wipe before schools.
  await db.like.deleteMany();
  await db.facilityImage.deleteMany();
  await db.schoolDemographics.deleteMany();
  await db.staffBreakdown.deleteMany();
  await db.achievement.deleteMany();
  await db.schoolUpdate.deleteMany();
  await db.school.deleteMany();
  await db.parent.deleteMany();
  await db.moEOfficer.deleteMany();
  await db.user.deleteMany();
};
