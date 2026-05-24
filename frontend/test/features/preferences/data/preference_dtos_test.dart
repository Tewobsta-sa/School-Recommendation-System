import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:school_rec/features/preferences/data/preference_dtos.dart';

void main() {
  group('Preference DTOs', () {
    test('ParentPreferences.fromJson and hasHomePin', () {
      // Arrange
      const jsonStr =
          '{"minBudget":"1000.0","maxBudget":2000,"curriculum":"LOCAL","address":"Home","latitude":9.1,"longitude":38.7}';

      // Act
      final p = ParentPreferences.fromJson(
          json.decode(jsonStr) as Map<String, dynamic>);

      // Assert
      expect(p.minBudget, 1000.0);
      expect(p.maxBudget, 2000);
      expect(p.curriculum, PreferredCurriculum.local);
      expect(p.hasHomePin, isTrue);
    });
  });
}
