import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:school_rec/features/announcements/data/announcement_dtos.dart';
import 'package:school_rec/features/announcements/data/announcement_repository.dart';
import 'package:school_rec/features/announcements/state/announcements_feed_controller.dart';
import 'package:school_rec/features/auth/data/auth_dtos.dart';
import 'package:school_rec/features/auth/state/auth_controller.dart';
import 'announcements_feed_controller_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<AnnouncementRepository>(),
  MockSpec<AuthController>(),
])
Announcement _announcement(int id) => Announcement(
      id: id,
      publisherId: 1,
      publisherType: PublisherType.schoolAdmin,
      schoolId: 10,
      title: 'Title $id',
      content: 'Content $id',
      category: AnnouncementCategory.other,
      urgencyLevel: UrgencyLevel.normal,
      datePosted: DateTime(2024),
      imgUrl: null,
      school: null,
    );

void main() {
  group('AnnouncementsFeedController', () {
    test('applies filters and resets paging', () async {
      // Arrange
      final repo = MockAnnouncementRepository();
      when(repo.list(
        page: anyNamed('page'),
        limit: anyNamed('limit'),
        category: anyNamed('category'),
        urgencyLevel: anyNamed('urgencyLevel'),
        schoolId: anyNamed('schoolId'),
        followedOnly: anyNamed('followedOnly'),
      )).thenAnswer((_) async => (
            items: [_announcement(1)],
            page: 1,
            totalPages: 2,
            total: 2,
          ));
      final container = ProviderContainer(
        overrides: [
          announcementRepositoryProvider.overrideWith((ref) => repo),
          authControllerProvider.overrideWith((ref) {
            final m = MockAuthController();
            when(m.user).thenReturn(const AppUser(
              id: 1,
              fullName: 'Parent',
              email: 'p@example.com',
              phone: null,
              role: UserRole.parent,
              emailVerified: true,
              accountStatus: 'ACTIVE',
            ));
            when(m.initializing).thenReturn(false);
            when(m.isAuthenticated).thenReturn(true);
            return m;
          }),
        ],
      );
      final controller = container.read(announcementsFeedControllerProvider);

      await controller.ensureLoaded();

      // Act
      await controller.applyFilters(
        category: AnnouncementCategory.policy,
        followedOnly: true,
        schoolId: 44,
      );

      // Assert
      verify(repo.list(
        page: 1,
        limit: 20,
        category: null,
        urgencyLevel: null,
        schoolId: null,
        followedOnly: null,
      )).called(1);
      verify(repo.list(
        page: 1,
        limit: 20,
        category: AnnouncementCategory.policy,
        urgencyLevel: null,
        schoolId: 44,
        followedOnly: true,
      )).called(1);
      expect(controller.category, AnnouncementCategory.policy);
      expect(controller.followedOnly, isTrue);
      expect(controller.schoolId, 44);
      expect(controller.items.single.id, 1);
      container.dispose();
    });

    test('clears followedOnly for non-parents', () async {
      // Arrange
      final repo = MockAnnouncementRepository();
      when(repo.list(
        page: anyNamed('page'),
        limit: anyNamed('limit'),
        category: anyNamed('category'),
        urgencyLevel: anyNamed('urgencyLevel'),
        schoolId: anyNamed('schoolId'),
        followedOnly: anyNamed('followedOnly'),
      )).thenAnswer((_) async => (
            items: [_announcement(1)],
            page: 1,
            totalPages: 1,
            total: 1,
          ));
      final container = ProviderContainer(
        overrides: [
          announcementRepositoryProvider.overrideWith((ref) => repo),
          authControllerProvider.overrideWith((ref) {
            final m = MockAuthController();
            when(m.user).thenReturn(const AppUser(
              id: 2,
              fullName: 'Admin',
              email: 'a@example.com',
              phone: null,
              role: UserRole.schoolAdmin,
              emailVerified: true,
              accountStatus: 'ACTIVE',
            ));
            when(m.initializing).thenReturn(false);
            when(m.isAuthenticated).thenReturn(true);
            return m;
          }),
        ],
      );
      final controller = container.read(announcementsFeedControllerProvider);

      // Act
      await controller.applyFilters(followedOnly: true);

      // Assert
      expect(controller.canFollowedOnly, isFalse);
      expect(controller.followedOnly, isFalse);
      verify(repo.list(
        page: 1,
        limit: 20,
        category: null,
        urgencyLevel: null,
        schoolId: null,
        followedOnly: null,
      )).called(1);
      container.dispose();
    });
  });
}
