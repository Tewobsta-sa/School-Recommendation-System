import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:school_rec/features/comparisons/data/comparison_dtos.dart';
import 'package:school_rec/features/comparisons/data/comparison_repository.dart';
import 'package:school_rec/features/comparisons/state/comparisons_controller.dart';
import 'package:school_rec/features/schools/data/school_dtos.dart';
import 'comparisons_controller_test.mocks.dart';

@GenerateNiceMocks([MockSpec<ComparisonRepository>()])
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

Comparison _comparison(int id) => Comparison(
      id: id,
      parentId: 1,
      metrics: const ['fees', 'distance'],
      createdAt: DateTime(2024),
      schools: [_school(id)],
    );

// MockComparisonRepository generated in comparisons_controller_test.mocks.dart

void main() {
  group('ComparisonsController', () {
    test('refreshes and prepends created comparisons', () async {
      // Arrange
      final repo = MockComparisonRepository();
      when(repo.listMine()).thenAnswer((_) async => [_comparison(1)]);
      when(repo.create(any)).thenAnswer((_) async => _comparison(2));
      when(repo.delete(any)).thenAnswer((_) async {});
      final controller = ComparisonsController(repo);
      await untilCalled(repo.listMine());

      // Act
      await controller.create([1, 2]);

      // Assert
      expect(controller.state.items.map((comparison) => comparison.id), [2, 1]);
      expect(controller.state.loading, isFalse);
    });

    test('deletes comparisons from the list', () async {
      // Arrange
      final repo = MockComparisonRepository();
      when(repo.listMine())
          .thenAnswer((_) async => [_comparison(1), _comparison(2)]);
      when(repo.create(any)).thenAnswer((_) async => _comparison(3));
      when(repo.delete(any)).thenAnswer((_) async {});
      final controller = ComparisonsController(repo);
      await untilCalled(repo.listMine());

      // Act
      await controller.delete(1);

      // Assert
      expect(controller.state.items.map((comparison) => comparison.id), [2]);
    });
  });
}
