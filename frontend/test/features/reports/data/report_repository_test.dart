import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:school_rec/features/reports/data/report_dtos.dart';
import 'package:school_rec/features/reports/data/report_repository.dart';
import 'package:school_rec/features/auth/data/auth_repository.dart';

@GenerateNiceMocks([
  MockSpec<Dio>(),
  MockSpec<Response<dynamic>>(),
])
import 'report_repository_test.mocks.dart';

void main() {
  late MockDio mockDio;
  late ReportRepository repo;

  setUp(() {
    mockDio = MockDio();
    repo = ReportRepository(mockDio);
  });

  test('list returns parsed list', () async {
    final mockRes = MockResponse();
    when(mockRes.statusCode).thenReturn(200);
    when(mockRes.data).thenReturn(json.decode(
        '{"data":[{"id":1,"reporterId":2,"targetType":"SCHOOL","targetId":3,"reason":"X","status":"PENDING","createdAt":"2026-05-01T10:00:00.000Z"}]}'));

    when(mockDio.get('/api/reports',
            queryParameters: anyNamed('queryParameters')))
        .thenAnswer((_) async => mockRes);

    final list = await repo.list();
    expect(list, hasLength(1));
    expect(list.first.targetType, ReportTargetType.school);
  });

  test('create posts and returns Report', () async {
    final mockRes = MockResponse();
    when(mockRes.statusCode).thenReturn(201);
    when(mockRes.data).thenReturn(json.decode(
        '{"report":{"id":7,"reporterId":2,"targetType":"REVIEW","targetId":9,"reason":"Bad","status":"PENDING","createdAt":"2026-05-01T10:00:00.000Z"}}'));

    when(mockDio.post('/api/reports', data: anyNamed('data')))
        .thenAnswer((_) async => mockRes);

    const input = ReportInput(
        targetType: ReportTargetType.review, targetId: 9, reason: 'Bad');
    final r = await repo.create(input);
    expect(r.id, 7);
    expect(r.targetType, ReportTargetType.review);
  });

  test('list throws ApiException on non-200', () async {
    final mockRes = MockResponse();
    when(mockRes.statusCode).thenReturn(500);
    when(mockRes.data).thenReturn('err');

    when(mockDio.get('/api/reports',
            queryParameters: anyNamed('queryParameters')))
        .thenAnswer((_) async => mockRes);

    expect(() => repo.list(), throwsA(isA<ApiException>()));
  });

  test('create throws when Dio fails', () async {
    when(mockDio.post('/api/reports', data: anyNamed('data')))
        .thenThrow(Exception('net'));

    const input = ReportInput(
        targetType: ReportTargetType.review, targetId: 9, reason: 'Bad');
    expect(() => repo.create(input), throwsA(isA<Exception>()));
  });
}
