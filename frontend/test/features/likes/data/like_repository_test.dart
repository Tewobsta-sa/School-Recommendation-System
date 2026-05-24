import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:school_rec/core/api_client.dart';
import 'package:school_rec/features/likes/data/like_repository.dart';
import 'package:school_rec/features/likes/data/like_dtos.dart';
import '../../../fixture_reader.dart';

@GenerateNiceMocks([
  MockSpec<ApiClient>(),
  MockSpec<Response<dynamic>>(),
])
import 'like_repository_test.mocks.dart';

void main() {
  late MockApiClient mockApi;
  late LikeRepository repo;

  setUp(() {
    mockApi = MockApiClient();
    repo = LikeRepository(mockApi);
  });

  test('toggleLike posts payload and parses liked flag', () async {
    final mockRes = MockResponse();
    when(mockRes.data)
        .thenReturn(json.decode(fixture('Like/toggle_response.json')));
    when(mockApi.post('/api/likes/toggle', data: anyNamed('data')))
        .thenAnswer((_) async => mockRes);

    final res = await repo.toggleLike(LikeTargetType.announcement, 5);
    expect(res.liked, isTrue);
    verify(mockApi.post('/api/likes/toggle', data: anyNamed('data'))).called(1);
  });

  test('getLikeCount GETs count and parses', () async {
    final mockRes = MockResponse();
    when(mockRes.data)
        .thenReturn(json.decode(fixture('Like/count_response.json')));
    when(mockApi.get('/api/likes/ANNOUNCEMENT/5/count'))
        .thenAnswer((_) async => mockRes);

    final r = await repo.getLikeCount(LikeTargetType.announcement, 5);
    expect(r.count, 7);
    verify(mockApi.get('/api/likes/ANNOUNCEMENT/5/count')).called(1);
  });

  test('getUserLikeStatus GETs status and parses liked flag', () async {
    final mockRes = MockResponse();
    when(mockRes.data)
        .thenReturn(json.decode(fixture('Like/status_response.json')));
    when(mockApi.get('/api/likes/FORUM_POST/3/status'))
        .thenAnswer((_) async => mockRes);

    final r = await repo.getUserLikeStatus(LikeTargetType.forumPost, 3);
    expect(r.liked, isFalse);
    verify(mockApi.get('/api/likes/FORUM_POST/3/status')).called(1);
  });

  test('toggleLike throws when API client fails', () async {
    when(mockApi.post('/api/likes/toggle', data: anyNamed('data')))
        .thenThrow(Exception('net'));

    expect(() => repo.toggleLike(LikeTargetType.announcement, 5),
        throwsA(isA<Exception>()));
  });

  test('getLikeCount throws when API client fails', () async {
    when(mockApi.get('/api/likes/ANNOUNCEMENT/5/count'))
        .thenThrow(Exception('net'));

    expect(() => repo.getLikeCount(LikeTargetType.announcement, 5),
        throwsA(isA<Exception>()));
  });
}
