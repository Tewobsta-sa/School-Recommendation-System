import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:school_rec/features/forum/data/forum_dtos.dart';
import 'package:school_rec/features/forum/data/forum_repository.dart';
import 'package:school_rec/features/auth/data/auth_repository.dart';

import '../../../fixture_reader.dart';

@GenerateNiceMocks([
  MockSpec<Dio>(),
  MockSpec<Response<dynamic>>(),
])
import 'forum_repository_test.mocks.dart';

void main() {
  late MockDio mockDio;
  late ForumRepository repository;

  setUp(() {
    mockDio = MockDio();
    repository = ForumRepository(mockDio);
  });

  void expectPost(ForumPost actual) {
    expect(actual.id, 10);
    expect(actual.authorId, 2);
    expect(actual.content, 'Parent post');
  }

  group('ForumRepository', () {
    group('list', () {
      test('returns parsed posts and pagination', () async {
        final mockRes = MockResponse();
        when(mockRes.statusCode).thenReturn(200);
        when(mockRes.data)
            .thenReturn(json.decode(fixture('Forum/list_response.json')));

        when(
          mockDio.get(
            '/api/forum',
            queryParameters: {'page': '1', 'limit': '20'},
          ),
        ).thenAnswer((_) async => mockRes);

        final result = await repository.list();

        expect(result.items, hasLength(1));
        expect(result.page, 1);
        expect(result.totalPages, 1);
        expect(result.total, 1);
        expectPost(result.items[0]);
        verify(
          mockDio.get(
            '/api/forum',
            queryParameters: {'page': '1', 'limit': '20'},
          ),
        );
        verifyNoMoreInteractions(mockDio);
      });

      test('throws ApiException on non-200', () async {
        final mockRes = MockResponse();
        when(mockRes.statusCode).thenReturn(500);
        when(mockRes.data).thenReturn('err');

        when(
          mockDio.get(
            '/api/forum',
            queryParameters: {'page': '1', 'limit': '20'},
          ),
        ).thenAnswer((_) async => mockRes);

        expect(() => repository.list(), throwsA(isA<ApiException>()));
      });
    });

    group('getById', () {
      test('returns parsed post', () async {
        final mockRes = MockResponse();
        when(mockRes.statusCode).thenReturn(200);
        when(mockRes.data)
            .thenReturn(json.decode(fixture('Forum/post_response.json')));

        when(mockDio.get('/api/forum/10')).thenAnswer((_) async => mockRes);

        final result = await repository.getById(10);

        expectPost(result);
        verify(mockDio.get('/api/forum/10'));
        verifyNoMoreInteractions(mockDio);
      });
    });

    group('create', () {
      test('posts content and returns created post', () async {
        final mockRes = MockResponse();
        when(mockRes.statusCode).thenReturn(201);
        when(mockRes.data)
            .thenReturn(json.decode(fixture('Forum/post_response.json')));

        when(
          mockDio.post(
            '/api/forum',
            data: {'content': 'New post'},
          ),
        ).thenAnswer((_) async => mockRes);

        final result = await repository.create('New post');

        expectPost(result);
        verify(
          mockDio.post(
            '/api/forum',
            data: {'content': 'New post'},
          ),
        );
        verifyNoMoreInteractions(mockDio);
      });

      test('create throws when Dio fails', () async {
        when(
          mockDio.post(
            '/api/forum',
            data: {'content': 'New post'},
          ),
        ).thenThrow(Exception('net'));

        expect(() => repository.create('New post'), throwsA(isA<Exception>()));
      });
    });

    group('reply', () {
      test('posts reply and returns created reply', () async {
        final mockRes = MockResponse();
        when(mockRes.statusCode).thenReturn(201);
        when(mockRes.data)
            .thenReturn(json.decode(fixture('Forum/post_response.json')));

        when(
          mockDio.post(
            '/api/forum/10/replies',
            data: {'content': 'Reply'},
          ),
        ).thenAnswer((_) async => mockRes);

        final result = await repository.reply(10, 'Reply');

        expectPost(result);
        verify(
          mockDio.post(
            '/api/forum/10/replies',
            data: {'content': 'Reply'},
          ),
        );
        verifyNoMoreInteractions(mockDio);
      });
    });

    group('update', () {
      test('puts content and returns updated post', () async {
        final mockRes = MockResponse();
        when(mockRes.statusCode).thenReturn(200);
        when(mockRes.data)
            .thenReturn(json.decode(fixture('Forum/post_response.json')));

        when(
          mockDio.put(
            '/api/forum/10',
            data: {'content': 'Updated'},
          ),
        ).thenAnswer((_) async => mockRes);

        final result = await repository.update(10, 'Updated');

        expectPost(result);
        verify(
          mockDio.put(
            '/api/forum/10',
            data: {'content': 'Updated'},
          ),
        );
        verifyNoMoreInteractions(mockDio);
      });
    });

    group('delete', () {
      test('succeeds on 204', () async {
        final mockRes = MockResponse();
        when(mockRes.statusCode).thenReturn(204);
        when(mockRes.data).thenReturn(null);

        when(mockDio.delete('/api/forum/10')).thenAnswer((_) async => mockRes);

        await repository.delete(10);

        verify(mockDio.delete('/api/forum/10'));
        verifyNoMoreInteractions(mockDio);
      });
    });
  });
}
