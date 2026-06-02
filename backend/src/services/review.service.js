import { db } from "../config/db.js";
import { ConflictError, ForbiddenError, NotFoundError, ValidationError } from "../utils/errors.js";
import { validateContent } from "./moderation.service.js";


export async function recomputeSchoolRating(schoolId) {
  const id = Number(schoolId);
  const agg = await db.review.aggregate({
    where: { schoolId: id },
    _avg: { rating: true },
    _count: { _all: true },
  });

  const avg = agg._avg.rating;
  const rating = avg == null ? 0 : Number(Number(avg).toFixed(2));
  const reviewCount = agg._count._all;

  await db.school.update({
    where: { id },
    data: { rating, reviewCount },
  });

  return { rating, reviewCount };
}

// ✅ Create review
export async function createReview(userId, schoolId, data) {
  let parent = await db.parent.findUnique({
    where: { userId },
  });

  // Create parent profile if it doesn't exist (lazy creation)
  if (!parent) {
    parent = await db.parent.create({
      data: {
        userId,
        latitude: 0,
        longitude: 0,
      },
    });
  }

  const existing = await db.review.findFirst({
    where: {
      parentId: userId,
      schoolId: Number(schoolId),
    },
  });

  if (existing) {
    throw new ConflictError("You already reviewed this school");
  }

  if (data.rating < 1 || data.rating > 5) {
    throw new ValidationError("Rating must be between 1 and 5");
  }

  if (data.comment) {
    validateContent(data.comment, { field: "comment" });
  }

  const review = await db.review.create({
    data: {
      parentId: userId,
      schoolId: Number(schoolId),
      rating: data.rating,
      comment: data.comment,
      categoryTag: data.categoryTag,
    },
  });

  await recomputeSchoolRating(schoolId);

  return review;
}

// ✅ Get reviews by school
export async function getReviewsBySchool(schoolId) {
  return db.review.findMany({
    where: { schoolId: Number(schoolId) },
    include: {
      parent: {
        select: { fullName: true },
      },
    },
  });
}

// ✅ Update review
export async function updateReview(userId, reviewId, data) {
  const review = await db.review.findUnique({
    where: { id: Number(reviewId) },
  });

  if (!review) throw new NotFoundError("Review not found");

  if (review.parentId !== userId) {
    throw new ForbiddenError("Not authorized to update this review");
  }

  if (data.comment) {
    validateContent(data.comment, { field: "comment" });
  }

  const updated = await db.review.update({
    where: { id: review.id },
    data,
  });

  // Rating may have changed → refresh the school aggregate.
  await recomputeSchoolRating(review.schoolId);

  return updated;
}

// ✅ Delete review
export async function deleteReview(userId, reviewId) {
  const review = await db.review.findUnique({
    where: { id: Number(reviewId) },
  });

  if (!review) throw new NotFoundError("Review not found");

  if (review.parentId !== userId) {
    throw new ForbiddenError("Not authorized to delete this review");
  }

  await db.review.delete({
    where: { id: review.id },
  });

  await recomputeSchoolRating(review.schoolId);

  return { message: "Review deleted" };
}

export async function getRatingDistribution(schoolId) {  
  const id = Number(schoolId);  
    
  const distribution = await db.review.groupBy({  
    by: ['rating'],  
    where: { schoolId: id },  
    _count: { rating: true },  
  });  
  
  // Initialize all ratings 1-5 with 0 count  
  const result = {};  
  for (let i = 1; i <= 5; i++) {  
    result[i] = 0;  
  }  
    
  // Fill in actual counts  
  distribution.forEach(item => {  
    result[item.rating] = item._count.rating;  
  });  
  
  return result;  
}