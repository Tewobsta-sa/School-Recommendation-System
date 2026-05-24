import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:school_rec/features/likes/data/like_dtos.dart';

void main() {
  group('Like DTOs', () {
    test('LikeToggleRequest.toJson uses wire values', () {
      // Arrange
      final reqAnn = LikeToggleRequest(
        targetType: LikeTargetType.announcement,
        targetId: 42,
      );

      // Act & Assert
      expect(reqAnn.toJson(), {'targetType': 'ANNOUNCEMENT', 'targetId': 42});

      // Arrange
      final reqForum = LikeToggleRequest(
        targetType: LikeTargetType.forumPost,
        targetId: 7,
      );

      // Act & Assert
      expect(reqForum.toJson(), {'targetType': 'FORUM_POST', 'targetId': 7});
    });

    test('LikeToggleResponse.fromJson parses liked flag', () {
      // Arrange
      final jsonMap = json.decode('{"liked": true}') as Map<String, dynamic>;

      // Act
      final resp = LikeToggleResponse.fromJson(jsonMap);

      // Assert
      expect(resp.liked, isTrue);
    });

    test('LikeCountResponse.fromJson parses count', () {
      // Arrange
      final jsonMap = json.decode('{"count": 123}') as Map<String, dynamic>;

      // Act
      final resp = LikeCountResponse.fromJson(jsonMap);

      // Assert
      expect(resp.count, 123);
    });
  });
}
