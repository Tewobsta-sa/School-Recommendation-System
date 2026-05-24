import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:school_rec/features/auth/data/auth_dtos.dart';
import 'package:school_rec/features/auth/data/auth_repository.dart';

import '../../../fixture_reader.dart';

@GenerateNiceMocks([
  MockSpec<Dio>(),
  MockSpec<Response<dynamic>>(),
])
import 'auth_repository_test.mocks.dart';

void main() {
  late MockDio mockDio;
  late AuthRepository repository;

  setUp(() {
    mockDio = MockDio();
    repository = AuthRepository(mockDio);
  });

  group('AuthRepository', () {
    group('login', () {
      // Future<LoginResult> login(String identifier, String password) async {
      //   final res = await _dio.post('/api/auth/login', data: {
      //     'identifier': identifier,
      //     'password': password,
      //   });
      //   if (res.statusCode != 200) throw _toApiException(res);
      //   final body = res.data as Map<String, dynamic>;
      //   return LoginResult(
      //     token: body['token'] as String,
      //     user: AppUser.fromJson(body['user'] as Map<String, dynamic>),
      //   );
      // }

      test('returns LoginResult when server responds 200', () async {
        final mockRes = MockResponse();
        when(mockRes.statusCode).thenReturn(200);
        when(mockRes.data)
            .thenReturn(json.decode(fixture('Auth/login_response.json')));

        when(mockDio.post('/api/auth/login', data: {
          'identifier': 'me@example.com',
          'password': 'pw',
        })).thenAnswer((_) async => mockRes);

        final result = await repository.login('me@example.com', 'pw');

        expect(result.token, 'secrettoken');
        expect(result.user.id, 42);
      });

      test('throws ApiException when non-200', () async {
        final mockRes = MockResponse();
        when(mockRes.statusCode).thenReturn(401);
        when(mockRes.data).thenReturn(
            {'error': 'Invalid credentials', 'code': 'UNAUTHORIZED'});

        when(mockDio.post('/api/auth/login', data: anyNamed('data')))
            .thenAnswer((_) async => mockRes);

        expect(
            () => repository.login('bad', 'pw'), throwsA(isA<ApiException>()));
      });

      test('throws on network error', () async {
        when(mockDio.post('/api/auth/login', data: anyNamed('data')))
            .thenThrow(Exception('net'));

        expect(() => repository.login('bad', 'pw'), throwsA(isA<Exception>()));
      });
    });

    group('getMe', () {
      // Future<AppUser> getMe() async {
      //   final res = await _dio.get('/api/users/me');
      //   if (res.statusCode != 200) throw _toApiException(res);
      //   return AppUser.fromJson((res.data as Map<String, dynamic>)['user'] as Map<String, dynamic>);
      // }

      test('returns AppUser when server responds 200', () async {
        final mockRes = MockResponse();
        when(mockRes.statusCode).thenReturn(200);
        when(mockRes.data)
            .thenReturn(json.decode(fixture('Auth/get_me_response.json')));

        when(mockDio.get('/api/users/me')).thenAnswer((_) async => mockRes);

        final user = await repository.getMe();

        expect(user.id, 99);
        expect(user.fullName, 'Current User');
      });

      test('throws ApiException on non-200', () async {
        final mockRes = MockResponse();
        when(mockRes.statusCode).thenReturn(500);
        when(mockRes.data).thenReturn('server error');

        when(mockDio.get('/api/users/me')).thenAnswer((_) async => mockRes);

        expect(() => repository.getMe(), throwsA(isA<ApiException>()));
      });
    });

    group('register', () {
      // Future<void> register({
      //   required String fullName,
      //   String? email,
      //   String? phone,
      //   required String password,
      //   required UserRole role,
      // }) async {
      //   assert((email != null && email.isNotEmpty) || (phone != null && phone.isNotEmpty));
      //   final res = await _dio.post('/api/auth/register', data: { ... });
      //   if (res.statusCode != 201) throw _toApiException(res);
      // }

      test('completes when server responds 201', () async {
        final mockRes = MockResponse();
        when(mockRes.statusCode).thenReturn(201);
        when(mockRes.data).thenReturn({});

        when(mockDio.post('/api/auth/register', data: anyNamed('data')))
            .thenAnswer((_) async => mockRes);

        await repository.register(
          fullName: 'New',
          email: 'new@example.com',
          password: 'pw',
          role: UserRole.parent,
        );
      });

      test('throws ApiException on non-201', () async {
        final mockRes = MockResponse();
        when(mockRes.statusCode).thenReturn(400);
        when(mockRes.data).thenReturn({'error': 'Bad', 'code': 'BAD'});

        when(mockDio.post('/api/auth/register', data: anyNamed('data')))
            .thenAnswer((_) async => mockRes);

        expect(
            () => repository.register(
                fullName: 'x',
                email: 'x@x',
                password: 'p',
                role: UserRole.parent),
            throwsA(isA<ApiException>()));
      });
    });

    group('verifyEmail', () {
      // Future<void> verifyEmail(String token) async {
      //   final res = await _dio.post('/api/auth/verify-email', data: {'token': token});
      //   if (res.statusCode != 200) throw _toApiException(res);
      // }

      test('completes on 200', () async {
        final mockRes = MockResponse();
        when(mockRes.statusCode).thenReturn(200);
        when(mockRes.data).thenReturn({});

        when(mockDio.post('/api/auth/verify-email', data: anyNamed('data')))
            .thenAnswer((_) async => mockRes);

        await repository.verifyEmail('token');
      });

      test('throws ApiException on non-200', () async {
        final mockRes = MockResponse();
        when(mockRes.statusCode).thenReturn(400);
        when(mockRes.data).thenReturn({'error': 'Bad token'});

        when(mockDio.post('/api/auth/verify-email', data: anyNamed('data')))
            .thenAnswer((_) async => mockRes);

        expect(
            () => repository.verifyEmail('bad'), throwsA(isA<ApiException>()));
      });
    });

    group('resendVerification', () {
      // Future<void> resendVerification(String email) async {
      //   final res = await _dio.post('/api/auth/resend-verification', data: {'email': email});
      //   if (res.statusCode != 200) throw _toApiException(res);
      // }

      test('completes on 200', () async {
        final mockRes = MockResponse();
        when(mockRes.statusCode).thenReturn(200);
        when(mockRes.data).thenReturn({});

        when(mockDio.post('/api/auth/resend-verification',
                data: anyNamed('data')))
            .thenAnswer((_) async => mockRes);

        await repository.resendVerification('u@example.com');
      });
    });

    group('forgotPassword', () {
      // Future<void> forgotPassword(String email) async {
      //   final res = await _dio.post('/api/auth/forgot-password', data: {'email': email});
      //   if (res.statusCode != 200) throw _toApiException(res);
      // }

      test('completes on 200', () async {
        final mockRes = MockResponse();
        when(mockRes.statusCode).thenReturn(200);
        when(mockRes.data).thenReturn({});

        when(mockDio.post('/api/auth/forgot-password', data: anyNamed('data')))
            .thenAnswer((_) async => mockRes);

        await repository.forgotPassword('u@example.com');
      });
    });

    group('resetPassword', () {
      // Future<void> resetPassword({ required String token, required String newPassword }) async {
      //   final res = await _dio.post('/api/auth/reset-password', data: {'token': token, 'newPassword': newPassword});
      //   if (res.statusCode != 200) throw _toApiException(res);
      // }

      test('completes on 200', () async {
        final mockRes = MockResponse();
        when(mockRes.statusCode).thenReturn(200);
        when(mockRes.data).thenReturn({});

        when(mockDio.post('/api/auth/reset-password', data: anyNamed('data')))
            .thenAnswer((_) async => mockRes);

        await repository.resetPassword(token: 't', newPassword: 'n');
      });
    });

    group('changePassword', () {
      // Future<void> changePassword({ required String currentPassword, required String newPassword }) async {
      //   final res = await _dio.post('/api/auth/change-password', data: {'currentPassword': currentPassword, 'newPassword': newPassword});
      //   if (res.statusCode != 200) throw _toApiException(res);
      // }

      test('completes on 200', () async {
        final mockRes = MockResponse();
        when(mockRes.statusCode).thenReturn(200);
        when(mockRes.data).thenReturn({});

        when(mockDio.post('/api/auth/change-password', data: anyNamed('data')))
            .thenAnswer((_) async => mockRes);

        await repository.changePassword(currentPassword: 'c', newPassword: 'n');
      });
    });

    group('updateMe', () {
      // Future<AppUser> updateMe({String? fullName, String? phone}) async {
      //   final res = await _dio.put('/api/users/me', data: { ... });
      //   if (res.statusCode != 200) throw _toApiException(res);
      //   return AppUser.fromJson((res.data as Map<String, dynamic>)['user'] as Map<String, dynamic>);
      // }

      test('returns updated AppUser on 200', () async {
        final mockRes = MockResponse();
        when(mockRes.statusCode).thenReturn(200);
        when(mockRes.data)
            .thenReturn(json.decode(fixture('Auth/update_me_response.json')));

        when(mockDio.put('/api/users/me', data: anyNamed('data')))
            .thenAnswer((_) async => mockRes);

        final user = await repository.updateMe(fullName: 'Updated');
        expect(user.fullName, 'Updated User');
      });
    });

    group('reactivate', () {
      // Future<LoginResult> reactivate(String identifier, String password) async { ... }

      test('returns LoginResult on 200', () async {
        final mockRes = MockResponse();
        when(mockRes.statusCode).thenReturn(200);
        when(mockRes.data)
            .thenReturn(json.decode(fixture('Auth/reactivate_response.json')));

        when(mockDio.post('/api/auth/reactivate', data: anyNamed('data')))
            .thenAnswer((_) async => mockRes);

        final lr = await repository.reactivate('me', 'pw');
        expect(lr.token, 'reactivatetoken');
        expect(lr.user.id, 7);
      });
    });

    group('deactivateMe', () {
      // Future<void> deactivateMe() async {
      //   final res = await _dio.post('/api/users/me/deactivate');
      //   if (res.statusCode != 200) throw _toApiException(res);
      // }

      test('completes on 200', () async {
        final mockRes = MockResponse();
        when(mockRes.statusCode).thenReturn(200);
        when(mockRes.data).thenReturn({});

        when(mockDio.post('/api/users/me/deactivate'))
            .thenAnswer((_) async => mockRes);

        await repository.deactivateMe();
      });
    });
  });
}
