import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:school_rec/features/comparisons/data/comparison_dtos.dart';
import '../../../fixture_reader.dart';

void main() {
  group('Comparison DTOs', () {
    test('Comparison.fromJson parses metrics, date and nested schools', () {
      // Arrange
      final jsonMap = json.decode(fixture('Comparison/Comparison.json'))
          as Map<String, dynamic>;

      // Act
      final c = Comparison.fromJson(jsonMap);

      // Assert
      expect(c.id, 5);
      expect(c.parentId, 2);
      expect(c.metrics, containsAll(['tuition', 'rating']));
      expect(c.createdAt, DateTime.parse('2026-05-01T10:00:00.000Z'));
      expect(c.schools, isNotEmpty);
      final s = c.schools.first;
      expect(s.id, 101);
      expect(s.schoolName, 'Test School');
    });
  });
}
