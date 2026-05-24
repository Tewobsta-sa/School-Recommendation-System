import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:school_rec/features/announcements/data/announcement_dtos.dart';
import 'package:school_rec/features/announcements/data/announcement_repository.dart';
import 'package:school_rec/features/announcements/data/comment_dtos.dart';
import 'package:school_rec/features/auth/data/auth_repository.dart';

import '../../../fixture_reader.dart';

@GenerateNiceMocks([
  MockSpec<Dio>(),
  MockSpec<Response<dynamic>>(),
])
import 'announcement_repository_test.mocks.dart';

void main() {
  late MockDio mockDio;
  late AnnouncementRepository repository;

  setUp(() {
    mockDio = MockDio();
    repository = AnnouncementRepository(mockDio);
  });

  void expectAnnouncement(
    Announcement actual, {
    required int id,
    required int publisherId,
    required PublisherType publisherType,
    required int? schoolId,
    required String title,
    required String content,
    required AnnouncementCategory category,
    required UrgencyLevel urgencyLevel,
    required DateTime datePosted,
    required String? imgUrl,
    required AnnouncementSchoolSummary? school,
  }) {
    expect(actual.id, id);
    expect(actual.publisherId, publisherId);
    expect(actual.publisherType, publisherType);
    expect(actual.schoolId, schoolId);
    expect(actual.title, title);
    expect(actual.content, content);
    expect(actual.category, category);
    expect(actual.urgencyLevel, urgencyLevel);
    expect(actual.datePosted, datePosted);
    expect(actual.imgUrl, imgUrl);
    expect(actual.school?.id, school?.id);
    expect(actual.school?.schoolName, school?.schoolName);
    expect(actual.school?.verificationStatus, school?.verificationStatus);
  }

  void expectComment(
    Comment actual, {
    required int id,
    required String content,
    required DateTime timestamp,
    required String authorName,
    required int repliesLength,
  }) {
    expect(actual.id, id);
    expect(actual.content, content);
    expect(actual.timestamp, timestamp);
    expect(actual.authorName, authorName);
    expect(actual.replies.length, repliesLength);
  }

  group('AnnouncementRepository', () {
    group('list', () {
      test(
          'returns parsed announcements and pagination data with default query params',
          () async {
        final mockRes = MockResponse();
        when(mockRes.statusCode).thenReturn(200);
        when(mockRes.data).thenReturn(
          json.decode(fixture('AnnouncementRepository/list_response.json')),
        );

        when(
          mockDio.get(
            '/api/announcements',
            queryParameters: {
              'page': '1',
              'limit': '20',
            },
          ),
        ).thenAnswer((_) async => mockRes);

        final result = await repository.list();

        expect(result.page, 2);
        expect(result.totalPages, 4);
        expect(result.total, 38);
        expect(result.items, hasLength(2));
        expectAnnouncement(
          result.items[0],
          id: 101,
          publisherId: 1,
          publisherType: PublisherType.moe,
          schoolId: null,
          title: 'Admissions Open',
          content: 'Applications are now open.',
          category: AnnouncementCategory.admissions,
          urgencyLevel: UrgencyLevel.high,
          datePosted: DateTime.parse('2026-05-01T12:30:00.000Z'),
          imgUrl: '/uploads/announcement-images/a.png',
          school: const AnnouncementSchoolSummary(
            id: 12,
            schoolName: 'Sunrise Academy',
            verificationStatus: 'VERIFIED',
          ),
        );
        expectAnnouncement(
          result.items[1],
          id: 202,
          publisherId: 5,
          publisherType: PublisherType.schoolAdmin,
          schoolId: 77,
          title: 'Fee Update',
          content: 'Fee schedule updated.',
          category: AnnouncementCategory.fee,
          urgencyLevel: UrgencyLevel.normal,
          datePosted: DateTime.parse('2026-05-02T10:00:00.000Z'),
          imgUrl: null,
          school: null,
        );

        verify(
          mockDio.get(
            '/api/announcements',
            queryParameters: {
              'page': '1',
              'limit': '20',
            },
          ),
        );
        verifyNoMoreInteractions(mockDio);
      });

      test('sends wire values for filters', () async {
        final mockRes = MockResponse();
        when(mockRes.statusCode).thenReturn(200);
        when(mockRes.data).thenReturn(
          json.decode(fixture('AnnouncementRepository/list_response.json')),
        );

        when(
          mockDio.get(
            '/api/announcements',
            queryParameters: {
              'page': '3',
              'limit': '15',
              'category': 'POLICY',
              'urgencyLevel': 'EMERGENCY',
              'schoolId': '44',
              'followedOnly': 'true',
            },
          ),
        ).thenAnswer((_) async => mockRes);

        final result = await repository.list(
          page: 3,
          limit: 15,
          category: AnnouncementCategory.policy,
          urgencyLevel: UrgencyLevel.emergency,
          schoolId: 44,
          followedOnly: true,
        );

        expect(result.items, hasLength(2));
        verify(
          mockDio.get(
            '/api/announcements',
            queryParameters: {
              'page': '3',
              'limit': '15',
              'category': 'POLICY',
              'urgencyLevel': 'EMERGENCY',
              'schoolId': '44',
              'followedOnly': 'true',
            },
          ),
        );
        verifyNoMoreInteractions(mockDio);
      });

      test('throws ApiException when status is not 200', () async {
        final mockRes = MockResponse();
        when(mockRes.statusCode).thenReturn(500);
        when(mockRes.data).thenReturn(
          json.decode(fixture('AnnouncementRepository/error_response.json')),
        );

        when(
          mockDio.get(
            '/api/announcements',
            queryParameters: {
              'page': '1',
              'limit': '20',
            },
          ),
        ).thenAnswer((_) async => mockRes);

        expect(repository.list(), throwsA(isA<ApiException>()));
        verify(
          mockDio.get(
            '/api/announcements',
            queryParameters: {
              'page': '1',
              'limit': '20',
            },
          ),
        );
        verifyNoMoreInteractions(mockDio);
      });

      test('throws when Dio fails', () async {
        when(
          mockDio.get(
            '/api/announcements',
            queryParameters: {
              'page': '1',
              'limit': '20',
            },
          ),
        ).thenThrow(Exception('net'));

        expect(() => repository.list(), throwsA(isA<Exception>()));
      });
    });

    group('createForSchool', () {
      test('posts to the school endpoint and parses the created announcement',
          () async {
        final mockRes = MockResponse();
        when(mockRes.statusCode).thenReturn(201);
        when(mockRes.data).thenReturn(
          json.decode(
              fixture('AnnouncementRepository/announcement_response.json')),
        );

        const input = AnnouncementInput(
          title: 'Admissions Open',
          content: 'Applications are now open.',
          category: AnnouncementCategory.admissions,
          urgencyLevel: UrgencyLevel.high,
          schoolId: 12,
        );

        when(
          mockDio.post(
            '/api/announcements/school',
            data: input.toJson(),
          ),
        ).thenAnswer((_) async => mockRes);

        final result = await repository.createForSchool(input);

        expectAnnouncement(
          result,
          id: 101,
          publisherId: 1,
          publisherType: PublisherType.moe,
          schoolId: null,
          title: 'Admissions Open',
          content: 'Applications are now open.',
          category: AnnouncementCategory.admissions,
          urgencyLevel: UrgencyLevel.high,
          datePosted: DateTime.parse('2026-05-01T12:30:00.000Z'),
          imgUrl: '/uploads/announcement-images/a.png',
          school: const AnnouncementSchoolSummary(
            id: 12,
            schoolName: 'Sunrise Academy',
            verificationStatus: 'VERIFIED',
          ),
        );
        verify(
          mockDio.post(
            '/api/announcements/school',
            data: input.toJson(),
          ),
        );
        verifyNoMoreInteractions(mockDio);
      });
    });

    group('createForMoe', () {
      test('posts to the moe endpoint and parses the created announcement',
          () async {
        final mockRes = MockResponse();
        when(mockRes.statusCode).thenReturn(201);
        when(mockRes.data).thenReturn(
          json.decode(
              fixture('AnnouncementRepository/announcement_response.json')),
        );

        const input = AnnouncementInput(
          title: 'Admissions Open',
          content: 'Applications are now open.',
          category: AnnouncementCategory.admissions,
          urgencyLevel: UrgencyLevel.high,
          schoolId: null,
        );

        when(
          mockDio.post(
            '/api/announcements/moe',
            data: input.toJson(),
          ),
        ).thenAnswer((_) async => mockRes);

        final result = await repository.createForMoe(input);

        expectAnnouncement(
          result,
          id: 101,
          publisherId: 1,
          publisherType: PublisherType.moe,
          schoolId: null,
          title: 'Admissions Open',
          content: 'Applications are now open.',
          category: AnnouncementCategory.admissions,
          urgencyLevel: UrgencyLevel.high,
          datePosted: DateTime.parse('2026-05-01T12:30:00.000Z'),
          imgUrl: '/uploads/announcement-images/a.png',
          school: const AnnouncementSchoolSummary(
            id: 12,
            schoolName: 'Sunrise Academy',
            verificationStatus: 'VERIFIED',
          ),
        );
        verify(
          mockDio.post(
            '/api/announcements/moe',
            data: input.toJson(),
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

        when(mockDio.delete('/api/announcements/101'))
            .thenAnswer((_) async => mockRes);

        await repository.delete(101);

        verify(mockDio.delete('/api/announcements/101'));
        verifyNoMoreInteractions(mockDio);
      });
    });

    group('getById', () {
      test('returns a parsed announcement', () async {
        final mockRes = MockResponse();
        when(mockRes.statusCode).thenReturn(200);
        when(mockRes.data).thenReturn(
          json.decode(
              fixture('AnnouncementRepository/announcement_response.json')),
        );

        when(mockDio.get('/api/announcements/101'))
            .thenAnswer((_) async => mockRes);

        final result = await repository.getById(101);

        expectAnnouncement(
          result,
          id: 101,
          publisherId: 1,
          publisherType: PublisherType.moe,
          schoolId: null,
          title: 'Admissions Open',
          content: 'Applications are now open.',
          category: AnnouncementCategory.admissions,
          urgencyLevel: UrgencyLevel.high,
          datePosted: DateTime.parse('2026-05-01T12:30:00.000Z'),
          imgUrl: '/uploads/announcement-images/a.png',
          school: const AnnouncementSchoolSummary(
            id: 12,
            schoolName: 'Sunrise Academy',
            verificationStatus: 'VERIFIED',
          ),
        );
        verify(mockDio.get('/api/announcements/101'));
        verifyNoMoreInteractions(mockDio);
      });
    });

    group('uploadImage', () {
      test('uploads image and returns parsed announcement', () async {
        final mockRes = MockResponse();
        when(mockRes.statusCode).thenReturn(200);
        when(mockRes.data).thenReturn(
          json.decode(
              fixture('AnnouncementRepository/announcement_response.json')),
        );

        final bytes = Uint8List.fromList([1, 2, 3]);

        when(
          mockDio.post(
            '/api/announcements/101/image',
            data: anyNamed('data'),
            options: anyNamed('options'),
          ),
        ).thenAnswer((_) async => mockRes);

        final result = await repository.uploadImage(
          id: 101,
          filename: 'banner.png',
          bytes: bytes,
        );

        expectAnnouncement(
          result,
          id: 101,
          publisherId: 1,
          publisherType: PublisherType.moe,
          schoolId: null,
          title: 'Admissions Open',
          content: 'Applications are now open.',
          category: AnnouncementCategory.admissions,
          urgencyLevel: UrgencyLevel.high,
          datePosted: DateTime.parse('2026-05-01T12:30:00.000Z'),
          imgUrl: '/uploads/announcement-images/a.png',
          school: const AnnouncementSchoolSummary(
            id: 12,
            schoolName: 'Sunrise Academy',
            verificationStatus: 'VERIFIED',
          ),
        );
        verify(
          mockDio.post(
            '/api/announcements/101/image',
            data: anyNamed('data'),
            options: anyNamed('options'),
          ),
        );
        verifyNoMoreInteractions(mockDio);
      });
    });

    group('deleteImage', () {
      test('succeeds on 204', () async {
        final mockRes = MockResponse();
        when(mockRes.statusCode).thenReturn(204);
        when(mockRes.data).thenReturn(null);

        when(mockDio.delete('/api/announcements/101/image'))
            .thenAnswer((_) async => mockRes);

        await repository.deleteImage(101);

        verify(mockDio.delete('/api/announcements/101/image'));
        verifyNoMoreInteractions(mockDio);
      });
    });

    group('getAnnouncementComments', () {
      test('returns parsed comments with replies', () async {
        final mockRes = MockResponse();
        when(mockRes.statusCode).thenReturn(200);
        when(mockRes.data).thenReturn(
          json.decode(fixture('AnnouncementRepository/comments_response.json')),
        );

        when(mockDio.get('/api/forum/announcement/101'))
            .thenAnswer((_) async => mockRes);

        final result = await repository.getAnnouncementComments(101);

        expect(result, hasLength(1));
        expectComment(
          result[0],
          id: 1,
          content: 'First comment',
          timestamp: DateTime.parse('2026-05-03T10:00:00.000Z'),
          authorName: 'Amina',
          repliesLength: 1,
        );
        expectComment(
          result[0].replies[0],
          id: 2,
          content: 'Reply',
          timestamp: DateTime.parse('2026-05-03T11:00:00.000Z'),
          authorName: 'Biru',
          repliesLength: 0,
        );
        verify(mockDio.get('/api/forum/announcement/101'));
        verifyNoMoreInteractions(mockDio);
      });
    });

    group('postAnnouncementComment', () {
      test('posts comment payload to the forum endpoint', () async {
        final mockRes = MockResponse();
        when(mockRes.statusCode).thenReturn(201);
        when(mockRes.data).thenReturn(null);

        when(
          mockDio.post(
            '/api/forum/announcement/101',
            data: {'content': 'Nice update'},
          ),
        ).thenAnswer((_) async => mockRes);

        await repository.postAnnouncementComment(101, 'Nice update');

        verify(
          mockDio.post(
            '/api/forum/announcement/101',
            data: {'content': 'Nice update'},
          ),
        );
        verifyNoMoreInteractions(mockDio);
      });
    });
  });
}
