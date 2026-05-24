import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:school_rec/features/notifications/data/notification_repository.dart';
import 'package:school_rec/features/auth/data/auth_repository.dart';

@GenerateNiceMocks([
  MockSpec<Dio>(),
  MockSpec<Response<dynamic>>(),
])
import 'notification_repository_test.mocks.dart';

void main() {
  late MockDio mockDio;
  late NotificationRepository repo;

  setUp(() {
    mockDio = MockDio();
    repo = NotificationRepository(mockDio);
  });

  test('list returns items and meta', () async {
    final mockRes = MockResponse();
    when(mockRes.statusCode).thenReturn(200);
    when(mockRes.data).thenReturn(json.decode(
        '{"data":[{"id":1,"message":"Hi","sourceType":"SYSTEM","isRead":false,"createdAt":"2026-05-01T10:00:00.000Z"}],"meta":{"total":1,"page":1,"limit":20,"totalPages":1}}'));

    when(mockDio.get('/api/notifications',
            queryParameters: anyNamed('queryParameters')))
        .thenAnswer((_) async => mockRes);

    final res = await repo.list();
    expect(res.items, hasLength(1));
    expect(res.total, 1);
  });

  test('markRead sends put and completes', () async {
    final mockRes = MockResponse();
    when(mockRes.statusCode).thenReturn(200);
    when(mockDio.put('/api/notifications/3/read'))
        .thenAnswer((_) async => mockRes);

    await repo.markRead(3);
    verify(mockDio.put('/api/notifications/3/read'));
  });

  test('list throws ApiException on non-200', () async {
    final mockRes = MockResponse();
    when(mockRes.statusCode).thenReturn(500);
    when(mockRes.data).thenReturn('err');

    when(mockDio.get('/api/notifications',
            queryParameters: anyNamed('queryParameters')))
        .thenAnswer((_) async => mockRes);

    expect(() => repo.list(), throwsA(isA<ApiException>()));
  });

  test('markRead throws when Dio fails', () async {
    when(mockDio.put('/api/notifications/3/read')).thenThrow(Exception('net'));
    expect(() => repo.markRead(3), throwsA(isA<Exception>()));
  });
}
