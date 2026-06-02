import { db } from "../config/db.js";
import { NotFoundError, ValidationError } from "../utils/errors.js";
import { logger } from "../config/logger.js";
import { createNotification } from "./notification.service.js";
import { deletePostAsModerator } from "./forum.service.js";

// ✅ Create Report
export async function createReport(data, userId) {  
  const { targetType, targetId, reason } = data;  
  
  const report = await db.report.create({  
    data: {  
      reporterId: userId,  
      targetType,  
      targetId: Number(targetId),  
      reason,  
    },  
  });  
  
  // Notify moderators and relevant MOE officers based on school subcity  
  try {  
    // Always notify moderators  
    const moderators = await db.user.findMany({  
      where: { role: "MODERATOR" },  
      select: { id: true },  
    });  
  
    for (const moderator of moderators) {  
      await createNotification({  
        recipientId: moderator.id,  
        recipientType: "MOE",  
        message: `New report: ${prettyTarget(targetType)} #${targetId} - ${reason}`,  
        sourceId: report.id,  
        sourceType: "REPORT",  
      });  
    }  
  
    // If report is about a school, notify the MOE officer for that subcity  
    if (targetType === "SCHOOL") {  
      const school = await db.school.findUnique({  
        where: { id: Number(targetId) },  
        select: { subCity: true, schoolName: true },  
      });  
  
      if (school && school.subCity) {  
        const assignedOfficer = await db.moEOfficer.findFirst({  
          where: { subCity: school.subCity },  
          select: { userId: true },  
        });  
  
        if (assignedOfficer) {  
          await createNotification({  
            recipientId: assignedOfficer.userId,  
            recipientType: "MOE",  
            message: `New report about school "${school.schoolName}" in your subcity: ${reason}`,  
            sourceId: report.id,  
            sourceType: "REPORT",  
          });  
        }  
      }  
    }  
  } catch (err) {  
    logger.warn({ err }, "Failed to notify moderators/MOE officers of new report");  
  }  
  
  return report;  
}

// ✅ Get All Reports (Moderator)
export async function getAllReports(query) {
  const { status } = query;

  const where = {
    ...(status && { status }),
  };

  return db.report.findMany({
    where,
    include: {
      reporter: true,
      actions: true,
    },
    orderBy: { createdAt: "desc" },
  });
}

// ✅ Get Single Report
export async function getReportById(id) {
  const report = await db.report.findUnique({
    where: { id: Number(id) },
    include: {
      reporter: true,
      actions: true,
    },
  });

  if (!report) throw new NotFoundError("Report not found");

  return report;
}


async function applyActionSideEffects(report, action) {
  const { actionType } = action;
  const targetType = report.targetType; // "REVIEW" | "ANNOUNCEMENT" | "FORUM_POST" | "SCHOOL"
  const targetId = report.targetId;

  // DISMISS — no side effects beyond closing the report.
  if (actionType === "DISMISS") {
    return { affectedUserId: null };
  }

  if (actionType === "REMOVE_CONTENT") {
    let authorId = null;
    if (targetType === "REVIEW") {
      const review = await db.review.findUnique({
        where: { id: targetId },
        select: { id: true, parentId: true, schoolId: true },
      });
      if (review) {
        authorId = review.parentId;
        await db.review.delete({ where: { id: review.id } });
        // Recompute the school's cached rating since a review just vanished.
        const agg = await db.review.aggregate({
          where: { schoolId: review.schoolId },
          _avg: { rating: true },
          _count: { _all: true },
        });
        const rating =
          agg._avg.rating == null
            ? 0
            : Number(Number(agg._avg.rating).toFixed(2));
        await db.school.update({
          where: { id: review.schoolId },
          data: { rating, reviewCount: agg._count._all },
        });
      }
    } else if (targetType === "ANNOUNCEMENT") {
      const ann = await db.announcement.findUnique({
        where: { id: targetId },
        select: { id: true, publisherId: true },
      });
      if (ann) {
        authorId = ann.publisherId;
        await db.announcement.delete({ where: { id: ann.id } });
      }
    } else if (targetType === "FORUM_POST") {
      const result = await deletePostAsModerator(targetId);
      authorId = result.authorId;
    } else {
      // SCHOOL targets are not auto-removable (would orphan reviews,
      // subscriptions, etc.). MoE workflow handles school deactivation.
      throw new ValidationError(
        "REMOVE_CONTENT is not valid for SCHOOL targets — use the school admin / MoE workflow instead"
      );
    }

    if (authorId) {
      try {
        await createNotification({
          recipientId: authorId,
          recipientType: "PARENT",
          message: `Your ${prettyTarget(targetType)} was removed by a moderator. Reason: ${
            report.reason
          }`,
          sourceId: report.id,
          sourceType: "MODERATION",
        });
      } catch (err) {
        logger.warn(
          { err, authorId, reportId: report.id },
          "Moderation notification (REMOVE_CONTENT) failed"
        );
      }
    }
    return { affectedUserId: authorId };
  }

  if (actionType === "WARN_USER" || actionType === "BAN_USER") {
    const authorId = await resolveTargetAuthorId(targetType, targetId);
    if (!authorId) {
      throw new NotFoundError(
        "Cannot apply user action — target content or its author no longer exists"
      );
    }

    if (actionType === "BAN_USER") {
      await db.user.update({
        where: { id: authorId },
        data: { accountStatus: "DEACTIVATED" },
      });
    }

    const message =
      actionType === "WARN_USER"
        ? `You received a moderator warning. Reason: ${report.reason}`
        : `Your account has been deactivated by a moderator. Reason: ${report.reason}`;
    try {
      await createNotification({
        recipientId: authorId,
        recipientType: "PARENT",
        message,
        sourceId: report.id,
        sourceType: "MODERATION",
      });
    } catch (err) {
      logger.warn(
        { err, authorId, reportId: report.id, actionType },
        "Moderation notification failed"
      );
    }
    return { affectedUserId: authorId };
  }

  // Should never reach here — Zod schema constrains to the four enum values.
  throw new ValidationError(`Unknown moderator action: ${actionType}`);
}

function prettyTarget(t) {
  switch (t) {
    case "REVIEW":
      return "review";
    case "ANNOUNCEMENT":
      return "announcement";
    case "FORUM_POST":
      return "forum post";
    case "SCHOOL":
      return "school listing";
    default:
      return "content";
  }
}

async function resolveTargetAuthorId(targetType, targetId) {
  if (targetType === "REVIEW") {
    const r = await db.review.findUnique({
      where: { id: targetId },
      select: { parentId: true },
    });
    return r?.parentId ?? null;
  }
  if (targetType === "ANNOUNCEMENT") {
    const a = await db.announcement.findUnique({
      where: { id: targetId },
      select: { publisherId: true },
    });
    return a?.publisherId ?? null;
  }
  if (targetType === "FORUM_POST") {
    const p = await db.discussionForum.findUnique({
      where: { id: targetId },
      select: { authorId: true },
    });
    return p?.authorId ?? null;
  }
  if (targetType === "SCHOOL") {
    const s = await db.school.findUnique({
      where: { id: targetId },
      select: { adminId: true },
    });
    return s?.adminId ?? null;
  }
  return null;
}


export async function takeAction(reportId, data, moderatorId) {
  const report = await db.report.findUnique({
    where: { id: Number(reportId) },
  });

  if (!report) throw new NotFoundError("Report not found");

  const action = await db.moderatorAction.create({
    data: {
      moderatorId,
      reportId: Number(reportId),
      actionType: data.actionType,
      notes: data.notes,
    },
  });

  // Side effects (delete/warn/ban). DISMISS is a no-op here.
  const sideEffects = await applyActionSideEffects(report, action);

  await db.report.update({
    where: { id: Number(reportId) },
    data: { status: "RESOLVED" },
  });

  // 🚀 Notify the original reporter that their report was handled.
  try {
    await createNotification({
      recipientId: report.reporterId,
      recipientType: "PARENT",
      message: `Your report (ID: ${reportId}) was handled by a moderator (action: ${data.actionType}).`,
      sourceId: Number(reportId),
      sourceType: "REPORT",
    });
  } catch (error) {
    logger.warn({ err: error, reportId }, "Report notification failed");
  }

  return { ...action, sideEffects };
}

export async function getReportedContent(reportId) {  
  const report = await db.report.findUnique({  
    where: { id: Number(reportId) },  
    select: { targetType: true, targetId: true },  
  });  
  
  if (!report) throw new NotFoundError("Report not found");  
  
  const { targetType, targetId } = report;  
  
  if (targetType === "ANNOUNCEMENT") {  
    return db.announcement.findUnique({  
      where: { id: targetId },  
      include: { publisher: { select: { fullName: true } } },  
    });  
  } else if (targetType === "FORUM_POST") {  
    return db.discussionForum.findUnique({  
      where: { id: targetId },  
      include: { author: { select: { fullName: true } } },  
    });  
  } else if (targetType === "REVIEW") {  
    return db.review.findUnique({  
      where: { id: targetId },  
      include: { parent: { select: { fullName: true } } },  
    });  
  }  
  
  throw new ValidationError("Unsupported target type for content viewing");  
}

