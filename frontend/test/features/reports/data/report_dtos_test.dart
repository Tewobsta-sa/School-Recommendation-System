import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:school_rec/features/reports/data/report_dtos.dart';

void main() {
  group('Report DTOs', () {
    test('Report.fromJson parses core fields and reporter', () {
      // Arrange
      const jsonStr =
          '{"id":3,"reporterId":2,"targetType":"REVIEW","targetId":9,"reason":"Spam","status":"PENDING","createdAt":"2026-05-01T10:00:00.000Z","reporter":{"fullName":"Alice"}}';

      // Act
      final r = Report.fromJson(json.decode(jsonStr) as Map<String, dynamic>);

      // Assert
      expect(r.id, 3);
      expect(r.targetType, ReportTargetType.review);
      expect(r.reporterName, 'Alice');
    });

    test('ReportInput and ModeratorActionInput toJson formats correctly', () {
      // Arrange
      const in1 = ReportInput(
          targetType: ReportTargetType.school, targetId: 5, reason: 'Abuse');

      // Act & Assert
      expect(in1.toJson()['targetType'], 'SCHOOL');

      const act = ModeratorActionInput(
          actionType: ModeratorActionType.removeContent, notes: 'Removed');
      expect(act.toJson()['actionType'], 'REMOVE_CONTENT');
      expect(act.toJson()['notes'], 'Removed');
    });
  });
}
