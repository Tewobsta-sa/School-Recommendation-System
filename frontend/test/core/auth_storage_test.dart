import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mockito/mockito.dart';
import 'package:school_rec/core/auth_storage.dart';

@GenerateNiceMocks([
  MockSpec<FlutterSecureStorage>(),
])
import 'auth_storage_test.mocks.dart';

void main() {
  late MockFlutterSecureStorage mockFlutterSecureStorage;
  late AuthStorage authStorage;
  late String tokenKey;

  setUp(() {
    mockFlutterSecureStorage = MockFlutterSecureStorage();
    authStorage = AuthStorage(mockFlutterSecureStorage);
    tokenKey = 'jwt_token';
  });

  group('AuthStorage', () {
    test('writes token to secure storage', () async {
      await authStorage.writeToken('abc123');

      verify(mockFlutterSecureStorage.write(key: tokenKey, value: 'abc123'));
      verifyNoMoreInteractions(mockFlutterSecureStorage);
    });

    test('reads token from secure storage', () async {
      when(mockFlutterSecureStorage.read(key: tokenKey))
          .thenAnswer((_) async => 'abc123');

      expect(await authStorage.readToken(), 'abc123');
      verify(mockFlutterSecureStorage.read(key: tokenKey));
      verifyNoMoreInteractions(mockFlutterSecureStorage);
    });

    test('deletes token from secure storage', () async {
      await authStorage.clear();

      verify(mockFlutterSecureStorage.delete(key: tokenKey));
      verifyNoMoreInteractions(mockFlutterSecureStorage);
    });
  });
}
