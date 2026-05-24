import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:school_rec/features/schools/data/school_dtos.dart';

void main() {
  group('School DTOs', () {
    test('School.fromJson parses basic fields and facility images', () {
      // Arrange
      const jsonStr = '''{
		"id": 101,
		"schoolName": "Test School",
		"address": "123 Main",
		"contactEmail": "a@b.com",
		"curriculum": "LOCAL",
		"tuitionFee": "75000.00",
		"facilityImages": [{"id":1, "imageUrl":"/img.png"}],
		"verificationStatus": "VERIFIED"
	}''';
      final m = json.decode(jsonStr) as Map<String, dynamic>;
      // Act
      final s = School.fromJson(m);
      // Assert
      expect(s.id, 101);
      expect(s.schoolName, 'Test School');
      expect(s.facilityImages, isNotEmpty);
      expect(s.facilityImages.first.imageUrl, '/img.png');
    });

    test('Pagination.fromJson parses numbers', () {
      const jsonStr = '{"total":10,"page":2,"limit":5,"totalPages":2}';
      final p =
          Pagination.fromJson(json.decode(jsonStr) as Map<String, dynamic>);
      expect(p.total, 10);
      expect(p.page, 2);
      expect(p.totalPages, 2);
    });

    test('School.fromJson throws on missing required id', () {
      final badJson = <String, dynamic>{};
      expect(() => School.fromJson(badJson), throwsA(isA<TypeError>()));
    });
  });
}
