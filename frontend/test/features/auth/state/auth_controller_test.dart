import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:school_rec/core/api_client.dart';
import 'package:school_rec/core/auth_storage.dart';
import 'package:school_rec/features/auth/data/auth_dtos.dart';
import 'package:school_rec/features/auth/data/auth_repository.dart';
import 'package:school_rec/features/auth/state/auth_controller.dart';

import 'auth_controller_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<AuthRepository>(),
  MockSpec<AuthStorage>(),
  MockSpec<ApiClient>(),
])
void main() {
  late MockAuthRepository mockRepo;
  late MockAuthStorage mockStorage;
  late MockApiClient mockApi;

  setUp(() {
    mockRepo = MockAuthRepository();
    mockStorage = MockAuthStorage();
    mockApi = MockApiClient();
  });

  test('initializes unauthenticated when no token in storage', () async {
    // Arrange: storage has no token
    when(mockStorage.readToken()).thenAnswer((_) async => null);

    // Act
    final c = AuthController(mockRepo, mockStorage, mockApi);
    await untilCalled(mockStorage.readToken());
    await Future<void>.delayed(Duration.zero);

    // Assert
    expect(c.initializing, isFalse);
    expect(c.user, isNull);
    expect(c.isAuthenticated, isFalse);
  });

  test('bootstraps user when token present', () async {
    // Arrange: storage has token and repo returns user
    when(mockStorage.readToken()).thenAnswer((_) async => 'tok');
    const user = AppUser(
      id: 9,
      fullName: 'Test',
      email: 'a@b.com',
      phone: null,
      role: UserRole.parent,
      emailVerified: true,
      accountStatus: 'ACTIVE',
    );
    when(mockRepo.getMe()).thenAnswer((_) async => user);

    // Act
    final c = AuthController(mockRepo, mockStorage, mockApi);
    await untilCalled(mockRepo.getMe());
    await Future<void>.delayed(Duration.zero);

    // Assert
    expect(c.initializing, isFalse);
    expect(c.user?.id, 9);
    expect(c.isAuthenticated, isTrue);
  });

  test('clears storage and remains unauthenticated on 401 from getMe',
      () async {
    // Arrange: storage has token, getMe throws 401
    when(mockStorage.readToken()).thenAnswer((_) async => 'tok');
    when(mockRepo.getMe()).thenThrow(ApiException('bad', statusCode: 401));

    // Act
    final c = AuthController(mockRepo, mockStorage, mockApi);
    await untilCalled(mockStorage.clear());
    await Future<void>.delayed(Duration.zero);

    // Assert
    expect(c.initializing, isFalse);
    expect(c.user, isNull);
    verify(mockStorage.clear()).called(1);
  });

  test('login writes token and sets user', () async {
    const user = AppUser(
      id: 3,
      fullName: 'LoginUser',
      email: 'l@u.com',
      phone: null,
      role: UserRole.parent,
      emailVerified: true,
      accountStatus: 'ACTIVE',
    );
    // Arrange
    when(mockRepo.login('u', 'p'))
        .thenAnswer((_) async => const LoginResult(token: 't', user: user));
    when(mockStorage.readToken()).thenAnswer((_) async => null);

    final c = AuthController(mockRepo, mockStorage, mockApi);
    await untilCalled(mockStorage.readToken());

    // Act
    await c.login('u', 'p');

    // Assert
    verify(mockStorage.writeToken('t')).called(1);
    expect(c.user?.id, 3);
  });

  test('logout clears storage and clears user', () async {
    // Arrange
    when(mockStorage.readToken()).thenAnswer((_) async => null);
    final c = AuthController(mockRepo, mockStorage, mockApi);
    await untilCalled(mockStorage.readToken());

    // Act
    await c.logout();

    // Assert
    verify(mockStorage.clear()).called(1);
    expect(c.user, isNull);
  });
}
