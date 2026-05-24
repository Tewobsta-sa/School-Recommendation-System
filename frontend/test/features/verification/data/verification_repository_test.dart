import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:school_rec/features/verification/data/verification_repository.dart';
import 'package:school_rec/features/auth/data/auth_repository.dart';

import '../../../fixture_reader.dart';

@GenerateNiceMocks([
  MockSpec<Dio>(),
  MockSpec<Response<dynamic>>(),
])
import 'verification_repository_test.mocks.dart';

void main() {
  late MockDio mockDio;
  late VerificationRepository repository;

  setUp(() {
    mockDio = MockDio();
    repository = VerificationRepository(mockDio);
  });

  test('list returns parsed requests and meta', () async {
    final mockRes = MockResponse();
    when(mockRes.statusCode).thenReturn(200);
    when(mockRes.data)
        .thenReturn(json.decode(fixture('Verification/list_response.json')));

    when(
      mockDio.get(
        '/api/verification-requests',
        queryParameters: {'page': '1', 'limit': '20'},
      ),
    ).thenAnswer((_) async => mockRes);

    final res = await repository.list();
    expect(res.items, hasLength(1));
    expect(res.page, 1);
    expect(res.totalPages, 1);
    expect(res.total, 1);
    verify(
      mockDio.get(
        '/api/verification-requests',
        queryParameters: {'page': '1', 'limit': '20'},
      ),
    );
  });

  test('getById parses request', () async {
    final mockRes = MockResponse();
    when(mockRes.statusCode).thenReturn(200);
    when(mockRes.data)
        .thenReturn(json.decode(fixture('Verification/request_response.json')));

    when(mockDio.get('/api/verification-requests/10'))
        .thenAnswer((_) async => mockRes);

    final r = await repository.getById(10);
    expect(r.id, 10);
    expect(r.schoolId, 5);
    verify(mockDio.get('/api/verification-requests/10'));
  });

  test('list throws ApiException on non-200', () async {
    final mockRes = MockResponse();
    when(mockRes.statusCode).thenReturn(500);
    when(mockRes.data).thenReturn('error');

    when(
      mockDio.get(
        '/api/verification-requests',
        queryParameters: {'page': '1', 'limit': '20'},
      ),
    ).thenAnswer((_) async => mockRes);

    expect(() => repository.list(), throwsA(isA<ApiException>()));
  });

  test('getById throws when Dio fails', () async {
    when(mockDio.get('/api/verification-requests/10'))
        .thenThrow(Exception('network'));

    expect(() => repository.getById(10), throwsA(isA<Exception>()));
  });
}
