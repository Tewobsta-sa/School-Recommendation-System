import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:school_rec/features/reviews/data/review_dtos.dart';

void main() {
  group('Review DTOs', () {
    test('Review.fromJson parses fields and parent.fullName', () {
      // Arrange
      const jsonStr =
          '{"id":8,"parentId":3,"schoolId":5,"rating":4,"comment":"Good","categoryTag":"SAFETY","createdAt":"2026-05-01T10:00:00.000Z","updatedAt":"2026-05-02T10:00:00.000Z","parent":{"fullName":"John Doe"}}';
      final m = json.decode(jsonStr) as Map<String, dynamic>;

      // Act
      final r = Review.fromJson(m);

      // Assert
      expect(r.id, 8);
      expect(r.rating, 4);
      expect(r.parentFullName, 'John Doe');
    });

    test('ReviewInput.toJson omits empty comment', () {
      // Arrange
      const input = ReviewInput(
          rating: 5, comment: '', categoryTag: ReviewCategoryTag.other);

      // Act
      final j = input.toJson();

      // Assert
      expect(j['rating'], 5);
      expect(j.containsKey('comment'), isFalse);
      expect(j['categoryTag'], 'OTHER');
    });
  });
}
