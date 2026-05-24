import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:school_rec/features/schools/data/school_dtos.dart';
import 'package:school_rec/features/schools/data/school_repository.dart';
import 'package:school_rec/features/schools/state/school_detail_controller.dart';
import 'school_detail_controller_test.mocks.dart';

@GenerateNiceMocks([MockSpec<SchoolRepository>()])
School _school({required int id, int followerCount = 10}) => School(
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
      followerCount: followerCount,
      distanceKm: null,
    );

void main() {
  group('SchoolDetailController', () {
    test('loads the school and follow status for parents', () async {
      // Arrange
      final repo = MockSchoolRepository();
      when(repo.getById(1)).thenAnswer((_) async => _school(id: 1));
      when(repo.myFollowedSchoolIds()).thenAnswer((_) async => {1});
      when(repo.follow(any)).thenAnswer((_) async {});
      when(repo.unfollow(any)).thenAnswer((_) async {});

      // Act
      final controller = SchoolDetailController(repo, 1, canFollow: true);
      await controller.load();

      // Assert
      expect(controller.state.loading, isFalse);
      expect(controller.state.school?.id, 1);
      expect(controller.state.isFollowing, isTrue);
    });

    test('rolls back a failed follow toggle', () async {
      // Arrange
      final repo = MockSchoolRepository();
      when(repo.getById(2))
          .thenAnswer((_) async => _school(id: 2, followerCount: 5));
      when(repo.myFollowedSchoolIds()).thenAnswer((_) async => const <int>{});
      when(repo.follow(any)).thenThrow(Exception('follow failed'));
      when(repo.unfollow(any)).thenAnswer((_) async {});
      final controller = SchoolDetailController(repo, 2, canFollow: true);
      await controller.load();

      // Act
      await controller.toggleFollow();

      // Assert
      expect(controller.state.isFollowing, isFalse);
      expect(controller.state.followBusy, isFalse);
      expect(controller.state.school?.followerCount, 5);
    });
  });
}
