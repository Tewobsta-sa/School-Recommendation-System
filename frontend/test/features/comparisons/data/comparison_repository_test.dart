import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:school_rec/features/comparisons/data/comparison_dtos.dart';
import 'package:school_rec/features/comparisons/data/comparison_repository.dart';
import 'package:school_rec/features/auth/data/auth_repository.dart';

import '../../../fixture_reader.dart';

@GenerateNiceMocks([
  MockSpec<Dio>(),
  MockSpec<Response<dynamic>>(),
])
import 'comparison_repository_test.mocks.dart';

void main() {
  late MockDio mockDio;
  late ComparisonRepository repository;

  setUp(() {
    mockDio = MockDio();
    repository = ComparisonRepository(mockDio);
  });

  void expectComparison(Comparison actual) {
    expect(actual.id, 5);
    expect(actual.parentId, 2);
    expect(actual.metrics, contains('tuition'));
    expect(actual.createdAt, DateTime.parse('2026-05-01T10:00:00.000Z'));
    expect(actual.schools, isNotEmpty);
    expect(actual.schools.first.id, 101);
    expect(actual.schools.first.schoolName, 'Test School');
  }

  group('ComparisonRepository', () {
    group('getById', () {
      test('returns parsed comparison', () async {
        final mockRes = MockResponse();
        when(mockRes.statusCode).thenReturn(200);
        when(mockRes.data)
            .thenReturn(json.decode(fixture('Comparison/Comparison.json')));

        when(mockDio.get('/api/comparisons/5'))
            .thenAnswer((_) async => mockRes);

        final result = await repository.getById(5);

        expectComparison(result);
        verify(mockDio.get('/api/comparisons/5'));
        verifyNoMoreInteractions(mockDio);
      });

      test('getById throws ApiException on non-200', () async {
        final mockRes = MockResponse();
        when(mockRes.statusCode).thenReturn(500);
        when(mockRes.data).thenReturn('err');

        when(mockDio.get('/api/comparisons/5'))
            .thenAnswer((_) async => mockRes);

        expect(() => repository.getById(5), throwsA(isA<ApiException>()));
      });
    });

    group('create', () {
      test('posts payload and returns created comparison', () async {
        final mockRes = MockResponse();
        when(mockRes.statusCode).thenReturn(201);
        when(mockRes.data)
            .thenReturn(json.decode(fixture('Comparison/Comparison.json')));

        when(
          mockDio.post(
            '/api/comparisons',
            data: {
              'schoolIds': [101, 102],
              'metrics': ['tuition']
            },
          ),
        ).thenAnswer((_) async => mockRes);

        final result =
            await repository.create([101, 102], metrics: ['tuition']);

        expectComparison(result);
        verify(
          mockDio.post(
            '/api/comparisons',
            data: {
              'schoolIds': [101, 102],
              'metrics': ['tuition']
            },
          ),
        );
        verifyNoMoreInteractions(mockDio);
      });

      test('create throws when Dio fails', () async {
        when(
          mockDio.post(
            '/api/comparisons',
            data: {
              'schoolIds': [101, 102],
              'metrics': ['tuition']
            },
          ),
        ).thenThrow(Exception('net'));

        expect(() => repository.create([101, 102], metrics: ['tuition']),
            throwsA(isA<Exception>()));
      });
    });

    group('delete', () {
      test('succeeds on 204', () async {
        final mockRes = MockResponse();
        when(mockRes.statusCode).thenReturn(204);
        when(mockRes.data).thenReturn(null);

        when(mockDio.delete('/api/comparisons/5'))
            .thenAnswer((_) async => mockRes);

        await repository.delete(5);

        verify(mockDio.delete('/api/comparisons/5'));
        verifyNoMoreInteractions(mockDio);
      });
    });
  });
}
