import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:school_rec/features/reviews/data/review_dtos.dart';
import 'package:school_rec/features/reviews/data/review_repository.dart';
import 'package:school_rec/features/auth/data/auth_repository.dart';

@GenerateNiceMocks([
  MockSpec<Dio>(),
  MockSpec<Response<dynamic>>(),
])
import 'review_repository_test.mocks.dart';

void main() {
  late MockDio mockDio;
  late ReviewRepository repo;

  setUp(() {
    mockDio = MockDio();
    repo = ReviewRepository(mockDio);
  });

  test('listForSchool returns parsed list', () async {
    final mockRes = MockResponse();
    when(mockRes.statusCode).thenReturn(200);
    when(mockRes.data).thenReturn(json.decode(
        '{"data":[{"id":1,"rating":5,"schoolId":2,"parentId":3,"categoryTag":"OTHER","createdAt":"2026-05-01T10:00:00.000Z","updatedAt":"2026-05-01T10:00:00.000Z"}]}'));

    when(mockDio.get('/api/reviews/school/2')).thenAnswer((_) async => mockRes);

    final list = await repo.listForSchool(2);
    expect(list, hasLength(1));
    expect(list.first.rating, 5);
  });

  test('create posts review and parses returned review', () async {
    final mockRes = MockResponse();
    when(mockRes.statusCode).thenReturn(201);
    when(mockRes.data).thenReturn(json.decode(
        '{"review":{"id":9,"rating":4,"schoolId":7,"parentId":1,"categoryTag":"OTHER","createdAt":"2026-05-01T10:00:00.000Z","updatedAt":"2026-05-01T10:00:00.000Z"}}'));

    when(mockDio.post('/api/reviews/7', data: anyNamed('data')))
        .thenAnswer((_) async => mockRes);

    const input = ReviewInput(
        rating: 4, comment: 'Nice', categoryTag: ReviewCategoryTag.other);
    final r = await repo.create(7, input);
    expect(r.id, 9);
    expect(r.schoolId, 7);
  });

  test('listForSchool throws ApiException on non-200', () async {
    final mockRes = MockResponse();
    when(mockRes.statusCode).thenReturn(500);
    when(mockRes.data).thenReturn('x');

    when(mockDio.get('/api/reviews/school/2')).thenAnswer((_) async => mockRes);

    expect(() => repo.listForSchool(2), throwsA(isA<ApiException>()));
  });

  test('create throws when Dio fails', () async {
    when(mockDio.post('/api/reviews/7', data: anyNamed('data')))
        .thenThrow(Exception('net'));

    const input = ReviewInput(
        rating: 4, comment: 'Nice', categoryTag: ReviewCategoryTag.other);
    expect(() => repo.create(7, input), throwsA(isA<Exception>()));
  });
}
