import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:school_rec/features/auth/data/auth_dtos.dart';
import 'package:school_rec/features/auth/state/auth_controller.dart';
import 'package:school_rec/features/notifications/data/notification_dtos.dart';
import 'package:school_rec/features/notifications/data/notification_repository.dart';
import 'package:school_rec/features/notifications/state/notifications_controller.dart';
import 'notifications_controller_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<NotificationRepository>(),
  MockSpec<AuthController>(),
])
AppNotification _notification(int id, {bool isRead = false}) => AppNotification(
      id: id,
      message: 'Message $id',
      sourceType: NotificationSourceType.system,
      sourceId: id,
      isRead: isRead,
      createdAt: DateTime(2024),
    );

void main() {
  group('NotificationsController', () {
    test('loads, paginates, and marks notifications read', () async {
      // Arrange
      final repo = MockNotificationRepository();
      when(repo.list(
              page: 1,
              limit: anyNamed('limit'),
              unreadOnly: anyNamed('unreadOnly')))
          .thenAnswer((inv) async => (
                items: [_notification(1), _notification(2)],
                total: 3,
                page: 1,
                totalPages: 2,
              ));
      when(repo.list(
              page: 2,
              limit: anyNamed('limit'),
              unreadOnly: anyNamed('unreadOnly')))
          .thenAnswer((inv) async => (
                items: [_notification(3)],
                total: 3,
                page: 2,
                totalPages: 2,
              ));
      when(repo.markRead(any)).thenAnswer((_) async {});
      final container = ProviderContainer(
        overrides: [
          notificationRepositoryProvider.overrideWith((ref) => repo),
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
      final controller = container.read(notificationsControllerProvider);

      // Act
      await controller.ensureLoaded();
      await controller.loadMore();
      await untilCalled(repo.list(page: 1, limit: 1, unreadOnly: true));
      await controller.markRead(1);

      // Assert
      verify(repo.list(page: 1, limit: 20, unreadOnly: false)).called(1);
      verify(repo.list(page: 2, limit: 20, unreadOnly: false)).called(1);
      expect(
          controller.items.map((notification) => notification.id), [1, 2, 3]);
      expect(controller.items.first.isRead, isTrue);
      expect(controller.unreadTotal, 2);
      verify(repo.markRead(1)).called(1);
      container.dispose();
    });

    test('clears unread count when unauthenticated', () async {
      // Arrange
      final repo = MockNotificationRepository();
      when(repo.list(
              page: anyNamed('page'),
              limit: anyNamed('limit'),
              unreadOnly: anyNamed('unreadOnly')))
          .thenAnswer((_) async => (
                items: [_notification(1)],
                total: 1,
                page: 1,
                totalPages: 1,
              ));
      when(repo.markRead(any)).thenAnswer((_) async {});
      final container = ProviderContainer(
        overrides: [
          notificationRepositoryProvider.overrideWith((ref) => repo),
          authControllerProvider.overrideWith((ref) {
            final m = MockAuthController();
            when(m.user).thenReturn(null);
            when(m.initializing).thenReturn(false);
            when(m.isAuthenticated).thenReturn(false);
            return m;
          }),
        ],
      );
      final controller = container.read(notificationsControllerProvider);

      // Act
      await controller.refreshUnreadCount();

      // Assert
      expect(controller.unreadTotal, 0);
      verifyNever(repo.list(
          page: anyNamed('page'), limit: anyNamed('limit'), unreadOnly: true));
      container.dispose();
    });
  });
}
