import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:school_rec/core/api_client.dart';
import 'package:school_rec/features/likes/data/like_dtos.dart';
import 'package:school_rec/features/likes/data/like_repository.dart';
import 'package:school_rec/features/likes/state/like_controller.dart';

import 'like_controller_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<ApiClient>(),
  MockSpec<LikeRepository>(),
])

// Mocks generated in like_controller_test.mocks.dart

void main() {
  group('LikeController', () {
    test('toggles likes and refreshes cached values', () async {
      // Arrange
      final repo = MockLikeRepository();
      when(repo.toggleLike(any, any))
          .thenAnswer((_) async => LikeToggleResponse(liked: true));
      when(repo.getLikeCount(any, any))
          .thenAnswer((_) async => LikeCountResponse(count: 11));
      when(repo.getUserLikeStatus(any, any))
          .thenAnswer((_) async => LikeToggleResponse(liked: true));
      final controller = LikeController(repo);

      // Act
      await controller.toggleLike(LikeTargetType.forumPost, 7);

      // Assert
      expect(controller.isLiked(LikeTargetType.forumPost, 7), isTrue);
      expect(controller.getLikeCount(LikeTargetType.forumPost, 7), 11);
    });

    test('rolls back optimistic updates when the repository fails', () async {
      // Arrange
      final repo = MockLikeRepository();
      when(repo.toggleLike(any, any)).thenThrow(Exception('boom'));
      when(repo.getLikeCount(any, any))
          .thenAnswer((_) async => LikeCountResponse(count: 11));
      when(repo.getUserLikeStatus(any, any))
          .thenAnswer((_) async => LikeToggleResponse(liked: true));
      final controller = LikeController(repo);

      // Act
      await controller.toggleLike(LikeTargetType.announcement, 9);

      // Assert
      expect(controller.isLiked(LikeTargetType.announcement, 9), isFalse);
      expect(controller.getLikeCount(LikeTargetType.announcement, 9), 0);
    });
  });
}
