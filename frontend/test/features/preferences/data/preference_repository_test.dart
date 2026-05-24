import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:school_rec/features/preferences/data/preference_dtos.dart';
import 'package:school_rec/features/preferences/data/preference_repository.dart';
import 'package:school_rec/features/auth/data/auth_repository.dart';

@GenerateNiceMocks([
  MockSpec<Dio>(),
  MockSpec<Response<dynamic>>(),
])
import 'preference_repository_test.mocks.dart';

void main() {
  late MockDio mockDio;
  late PreferenceRepository repo;

  setUp(() {
    mockDio = MockDio();
    repo = PreferenceRepository(mockDio);
  });

  test('getMine returns empty when no preference present', () async {
    final mockRes = MockResponse();
    when(mockRes.statusCode).thenReturn(200);
    when(mockRes.data).thenReturn(json.decode('{"preference": null}'));

    when(mockDio.get('/api/preferences/me')).thenAnswer((_) async => mockRes);

    final p = await repo.getMine();
    expect(p, isA<ParentPreferences>());
  });

  test('save posts data and refetches mine', () async {
    final postRes = MockResponse();
    when(postRes.statusCode).thenReturn(200);
    when(postRes.data)
        .thenReturn(json.decode('{"preference": {"minBudget":100}}'));

    final getRes = MockResponse();
    when(getRes.statusCode).thenReturn(200);
    when(getRes.data)
        .thenReturn(json.decode('{"preference": {"minBudget":100}}'));

    when(mockDio.post('/api/preferences', data: anyNamed('data')))
        .thenAnswer((_) async => postRes);
    when(mockDio.get('/api/preferences/me')).thenAnswer((_) async => getRes);

    final out = await repo.save(minBudget: 100);
    expect(out.minBudget, 100);
  });

  test('getMine throws ApiException on non-200', () async {
    final mockRes = MockResponse();
    when(mockRes.statusCode).thenReturn(500);
    when(mockRes.data).thenReturn('bad');

    when(mockDio.get('/api/preferences/me')).thenAnswer((_) async => mockRes);

    expect(() => repo.getMine(), throwsA(isA<ApiException>()));
  });

  test('save throws when post fails', () async {
    when(mockDio.post('/api/preferences', data: anyNamed('data')))
        .thenThrow(Exception('net'));

    expect(() => repo.save(minBudget: 100), throwsA(isA<Exception>()));
  });
}
