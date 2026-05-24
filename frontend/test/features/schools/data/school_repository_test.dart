import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:school_rec/features/schools/data/school_dtos.dart';
import 'package:school_rec/features/schools/data/school_repository.dart';
import 'package:school_rec/features/auth/data/auth_repository.dart';
import '../../../fixture_reader.dart';

@GenerateNiceMocks([
  MockSpec<Dio>(),
  MockSpec<Response<dynamic>>(),
])
import 'school_repository_test.mocks.dart';

void main() {
  late MockDio mockDio;
  late SchoolRepository repo;

  setUp(() {
    mockDio = MockDio();
    repo = SchoolRepository(mockDio);
  });

  test('list returns SchoolsPage with items and meta', () async {
    final mockRes = MockResponse();
    when(mockRes.statusCode).thenReturn(200);
    when(mockRes.data)
        .thenReturn(json.decode(fixture('School/list_response.json')));

    when(mockDio.get('/api/schools',
            queryParameters: anyNamed('queryParameters')))
        .thenAnswer((_) async => mockRes);

    const filters = SchoolListFilters();
    final page = await repo.list(filters);
    expect(page.items, hasLength(1));
    expect(page.meta.total, 1);
    verify(mockDio.get('/api/schools',
        queryParameters: anyNamed('queryParameters')));
  });

  test('getById returns parsed School', () async {
    final mockRes = MockResponse();
    when(mockRes.statusCode).thenReturn(200);
    when(mockRes.data)
        .thenReturn(json.decode(fixture('School/school_response.json')));

    when(mockDio.get('/api/schools/5')).thenAnswer((_) async => mockRes);

    final s = await repo.getById(5);
    expect(s.id, 5);
    expect(s.schoolName, 'Z');
  });

  test('list throws ApiException on non-200', () async {
    final mockRes = MockResponse();
    when(mockRes.statusCode).thenReturn(500);
    when(mockRes.data).thenReturn('error');

    when(mockDio.get('/api/schools',
            queryParameters: anyNamed('queryParameters')))
        .thenAnswer((_) async => mockRes);

    const filters = SchoolListFilters();
    expect(() => repo.list(filters), throwsA(isA<ApiException>()));
  });

  test('getById throws when Dio fails', () async {
    when(mockDio.get('/api/schools/5')).thenThrow(Exception('net'));
    expect(() => repo.getById(5), throwsA(isA<Exception>()));
  });
}
