import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:school_rec/features/analytics/data/analytics_repository.dart';
import 'package:school_rec/features/analytics/data/analytics_dtos.dart';

import '../../../fixture_reader.dart';

@GenerateNiceMocks([
  MockSpec<Dio>(),
  MockSpec<Response<dynamic>>(),
])
import 'analytics_repository_test.mocks.dart';

void main() {
  late MockDio mockDio;
  late AnalyticsRepository repository;

  setUp(() {
    mockDio = MockDio();
    repository = AnalyticsRepository(mockDio);
  });

  group('AnalyticsRepository', () {
    group('dashboard', () {
      test('returns Dashboard when response is 200', () async {
        final mockRes = MockResponse();
        when(mockRes.statusCode).thenReturn(200);
        when(mockRes.data)
            .thenReturn(json.decode(fixture('Dashboard/Dashboard_full.json')));

        when(mockDio.get('/api/analytics/dashboard'))
            .thenAnswer((_) async => mockRes);

        final result = await repository.dashboard();

        expect(result, isA<Dashboard>());
        expect(result.summary.totalUsers, 100);
        expect(result.topSchools.length, 2);
        verify(mockDio.get('/api/analytics/dashboard'));
        verifyNoMoreInteractions(mockDio);
      });

      test('throws ApiException when statusCode != 200', () async {
        final mockRes = MockResponse();
        when(mockRes.statusCode).thenReturn(500);
        when(mockRes.data)
            .thenReturn({'error': 'Server exploded', 'code': 'SERVER'});

        when(mockDio.get('/api/analytics/dashboard'))
            .thenAnswer((_) async => mockRes);

        expect(
            () async => await repository.dashboard(),
            throwsA(predicate((e) =>
                e.toString().contains('Server exploded') ||
                e.toString().contains('Request failed'))));
        verify(mockDio.get('/api/analytics/dashboard'));
        verifyNoMoreInteractions(mockDio);
      });

      test('throws when Dio fails', () async {
        when(mockDio.get('/api/analytics/dashboard'))
            .thenThrow(Exception('net'));

        expect(() async => await repository.dashboard(),
            throwsA(isA<Exception>()));
      });
    });

    group('dashboardCsv', () {
      test('returns CSV string when response is 200', () async {
        final mockRes = MockResponse();
        when(mockRes.statusCode).thenReturn(200);
        when(mockRes.data).thenReturn('a,b,c\n1,2,3');

        when(mockDio.get<dynamic>('/api/analytics/dashboard.csv',
                options: anyNamed('options')))
            .thenAnswer((_) async => mockRes);

        final csv = await repository.dashboardCsv();
        expect(csv, 'a,b,c\n1,2,3');
        verify(mockDio.get<dynamic>('/api/analytics/dashboard.csv',
            options: anyNamed('options')));
        verifyNoMoreInteractions(mockDio);
      });

      test('throws ApiException when response is not 200', () async {
        final mockRes = MockResponse();
        when(mockRes.statusCode).thenReturn(404);
        when(mockRes.data).thenReturn('not found');

        when(mockDio.get<dynamic>('/api/analytics/dashboard.csv',
                options: anyNamed('options')))
            .thenAnswer((_) async => mockRes);

        expect(
            () async => await repository.dashboardCsv(),
            throwsA(predicate((e) =>
                e.toString().contains('Request failed') ||
                e.toString().contains('not found'))));
        verify(mockDio.get<dynamic>('/api/analytics/dashboard.csv',
            options: anyNamed('options')));
        verifyNoMoreInteractions(mockDio);
      });
    });
  });
}
