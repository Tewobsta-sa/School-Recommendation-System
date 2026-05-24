import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:school_rec/features/announcements/data/comment_dtos.dart';

import '../../../fixture_reader.dart';

void main() {
  final tTimestamp = DateTime.parse('2026-05-01T12:30:00.000Z');
  final tChildTimestamp = DateTime.parse('2026-05-01T13:00:00.000Z');

  final tChild = Comment(
    id: 2,
    content: 'Child comment',
    timestamp: tChildTimestamp,
    authorName: 'Bob',
    replies: [],
  );

  final tParent = Comment(
    id: 1,
    content: 'Parent comment',
    timestamp: tTimestamp,
    authorName: 'Alice',
    replies: [tChild],
  );

  group('Comment DTOs', () {
    test('fromJson should parse a comment with nested replies', () {
      // Arrange
      final jsonMap = json.decode(fixture('Comment/Comment.json'));

      // Act
      final result = Comment.fromJson(jsonMap);

      // Assert
      expect(result.id, tParent.id);
      expect(result.content, tParent.content);
      expect(result.timestamp, tParent.timestamp);
      expect(result.authorName, tParent.authorName);
      expect(result.replies, isA<List<Comment>>());
      expect(result.replies.length, 1);
      final child = result.replies.first;
      expect(child.id, tChild.id);
      expect(child.content, tChild.content);
      expect(child.timestamp, tChild.timestamp);
      expect(child.authorName, tChild.authorName);
    });

    test('fromJson should treat null replies as empty list', () {
      // Arrange
      final jsonMap = json.decode(fixture('Comment/Comment_no_replies.json'));

      // Act
      final result = Comment.fromJson(jsonMap);

      // Assert
      expect(result.id, 3);
      expect(result.content, 'No replies comment');
      expect(result.authorName, 'Carol');
      expect(result.replies, isEmpty);
    });
  });
}
