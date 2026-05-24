import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:school_rec/features/reviews/data/review_dtos.dart';
import 'package:school_rec/features/reviews/data/review_repository.dart';
import 'package:school_rec/features/reviews/state/reviews_controller.dart';
import 'reviews_controller_test.mocks.dart';

@GenerateNiceMocks([MockSpec<ReviewRepository>()])
Review _review(int id) => Review(
      id: id,
      parentId: 10,
      schoolId: 20,
      rating: 4,
      comment: 'Comment $id',
      categoryTag: ReviewCategoryTag.other,
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
      parentFullName: 'Parent',
    );

void main() {
  group('ReviewsController', () {
    test('loads items and inserts new reviews at the front', () async {
      // Arrange
      final repo = MockReviewRepository();
      when(repo.listForSchool(20))
          .thenAnswer((_) async => [_review(1), _review(2)]);
      when(repo.create(20, any)).thenAnswer((_) async => _review(3));
      when(repo.update(any, any)).thenAnswer(
          (inv) async => _review(inv.positionalArguments.first as int));
      when(repo.delete(any)).thenAnswer((_) async {});

      final controller = ReviewsController(repo, 20);

      // Act
      await controller.refresh();
      await controller.create(const ReviewInput(
        rating: 5,
        comment: 'New',
        categoryTag: ReviewCategoryTag.other,
      ));

      // Assert
      expect(controller.items.map((review) => review.id), [3, 1, 2]);
      expect(controller.initialized, isTrue);
      expect(controller.loading, isFalse);
    });

    test('updates and deletes reviews in place', () async {
      // Arrange
      final repo = MockReviewRepository();
      when(repo.listForSchool(20))
          .thenAnswer((_) async => [_review(1), _review(2)]);
      when(repo.create(20, any)).thenAnswer((_) async => _review(3));
      when(repo.update(any, any)).thenAnswer(
          (inv) async => _review(inv.positionalArguments.first as int));
      when(repo.delete(any)).thenAnswer((_) async {});
      final controller = ReviewsController(repo, 20);
      await controller.refresh();

      // Act
      await controller.update(
          2,
          const ReviewInput(
            rating: 3,
            comment: 'Updated',
            categoryTag: ReviewCategoryTag.other,
          ));
      await controller.remove(1);

      // Assert
      expect(controller.items.map((review) => review.id), [2]);
      expect(controller.saving, isFalse);
      expect(controller.error, isNull);
    });
  });
}
