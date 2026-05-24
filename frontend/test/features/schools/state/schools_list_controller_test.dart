import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:school_rec/features/schools/data/school_dtos.dart';
import 'package:school_rec/features/schools/data/school_repository.dart';
import 'package:school_rec/features/schools/state/schools_list_controller.dart';
import 'schools_list_controller_test.mocks.dart';

@GenerateNiceMocks([MockSpec<SchoolRepository>()])
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
  group('SchoolsListController', () {
    test('refreshes and loads more items', () async {
      // Arrange
      final repo = MockSchoolRepository();
      when(repo.list(argThat(predicate((SchoolListFilters f) => f.page == 1))))
          .thenAnswer((_) async => SchoolsPage([_school(1), _school(2)],
              const Pagination(total: 4, page: 1, limit: 2, totalPages: 2)));
      when(repo.list(argThat(predicate((SchoolListFilters f) => f.page == 2))))
          .thenAnswer((_) async => SchoolsPage([_school(3), _school(4)],
              const Pagination(total: 4, page: 2, limit: 2, totalPages: 2)));

      // Act
      final controller = SchoolsListController(repo);
      await untilCalled(
          repo.list(argThat(predicate((SchoolListFilters f) => f.page == 1))));
      await controller.loadMore();

      // Assert
      verify(repo.list(
          argThat(predicate((SchoolListFilters f) => f.page == 1)))).called(1);
      verify(repo.list(
          argThat(predicate((SchoolListFilters f) => f.page == 2)))).called(1);
      expect(controller.state.items.map((school) => school.id), [1, 2, 3, 4]);
      expect(controller.state.initialLoading, isFalse);
      expect(controller.state.loadingMore, isFalse);
      expect(controller.state.hasMore, isFalse);
    });

    test('applyFilters resets to page one', () async {
      // Arrange
      final repo = MockSchoolRepository();
      when(repo.list(any)).thenAnswer((inv) {
        final filters = inv.positionalArguments.first as SchoolListFilters;
        return Future.value(SchoolsPage([
          _school(filters.page)
        ], Pagination(total: 1, page: filters.page, limit: 10, totalPages: 1)));
      });
      final controller = SchoolsListController(repo);
      await untilCalled(repo.list(any));

      // Act
      await controller.applyFilters(const SchoolListFilters(search: 'math'));

      // Assert
      verify(repo.list(
          argThat(predicate((SchoolListFilters f) => f.page == 1)))).called(2);
      expect(controller.state.filters.search, 'math');
      expect(controller.state.filters.page, 1);
      expect(controller.state.items.single.id, 1);
    });
  });
}
