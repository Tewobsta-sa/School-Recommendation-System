import 'package:flutter_test/flutter_test.dart';
import 'package:school_rec/features/schools/data/school_dtos.dart';
import 'package:school_rec/features/schools/state/compare_cart.dart';

School _school(int id) => School(
      id: id,
      schoolName: 'School $id',
      address: 'Address',
      contactEmail: 'school$id@example.com',
      contactPhone: null,
      curriculum: Curriculum.local,
      tuitionFee: 1000,
      facilities: null,
      latitude: null,
      longitude: null,
      rating: null,
      reviewCount: null,
      verificationStatus: VerificationStatus.pending,
      schoolLevel: null,
      schoolType: null,
      passingRate: null,
      nationalExamScore: null,
      facilityImages: const [],
      followerCount: null,
      distanceKm: null,
    );

void main() {
  group('CompareCart', () {
    test('adds, removes, toggles, and clears items', () {
      // Arrange
      final cart = CompareCart();
      final first = _school(1);
      final second = _school(2);

      // Act
      final addedFirst = cart.add(first);
      cart.toggle(second);
      cart.toggle(first);
      cart.clear();

      // Assert
      expect(addedFirst, isTrue);
      expect(cart.length, 0);
      expect(cart.contains(1), isFalse);
      expect(cart.canCreateComparison, isFalse);
    });

    test('respects the maximum item limit', () {
      // Arrange
      final cart = CompareCart();

      // Act
      final results = List.generate(
        CompareCart.maxItems + 1,
        (index) => cart.add(_school(index + 1)),
      );

      // Assert
      expect(
          results.take(CompareCart.maxItems).every((value) => value), isTrue);
      expect(results.last, isFalse);
      expect(cart.length, CompareCart.maxItems);
      expect(cart.canCreateComparison, isTrue);
    });
  });
}
