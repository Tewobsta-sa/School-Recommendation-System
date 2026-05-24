import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:school_rec/features/notifications/data/notification_dtos.dart';

void main() {
  group('Notification DTOs', () {
    test('AppNotification.fromJson parses and markedRead toggles', () {
      // Arrange
      const jsonStr =
          '{"id":4,"message":"Hello","sourceType":"ANNOUNCEMENT","sourceId":10,"isRead":false,"createdAt":"2026-05-01T10:00:00.000Z"}';

      // Act
      final n = AppNotification.fromJson(
          json.decode(jsonStr) as Map<String, dynamic>);

      // Assert
      expect(n.id, 4);
      expect(n.sourceType, NotificationSourceType.announcement);

      // Act
      final read = n.markedRead();

      // Assert
      expect(read.isRead, isTrue);
    });
  });
}
