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
