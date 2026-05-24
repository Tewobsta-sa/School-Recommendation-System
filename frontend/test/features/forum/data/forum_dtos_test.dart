import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_rec/features/forum/data/forum_dtos.dart';

import '../../../fixture_reader.dart';

void main() {
  group('Forum DTOs', () {
    test('ForumPost.fromJson parses nested replies and author', () {
      // Arrange
      final jsonMap = json.decode(fixture('Forum/ForumPost_with_replies.json'))
          as Map<String, dynamic>;

      // Act
      final post = ForumPost.fromJson(jsonMap);

      // Assert
      expect(post.id, 10);
      expect(post.authorId, 2);
      expect(post.content, 'Parent post');
      expect(post.timestamp, DateTime.parse('2026-05-01T11:00:00.000Z'));
      expect(post.replies, isNotNull);
      expect(post.replies!.length, 1);
      final reply = post.replies!.first;
      expect(reply.id, 11);
      expect(reply.threadId, 10);
      expect(reply.author, isNull);
    });

    test('ForumPost.fromJson tolerates missing author', () {
      // Arrange
      final jsonMap = json.decode(fixture('Forum/ForumPost_no_author.json'))
          as Map<String, dynamic>;

      // Act
      final post = ForumPost.fromJson(jsonMap);

      // Assert
      expect(post.author, isNull);
    });
  });
}
