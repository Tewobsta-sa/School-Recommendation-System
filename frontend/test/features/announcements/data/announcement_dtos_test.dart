import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:school_rec/features/announcements/data/announcement_dtos.dart';

import '../../../fixture_reader.dart';

void main() {
  final tDatePosted = DateTime.parse('2026-05-01T12:30:00.000Z');
  final tDatePosted2 = DateTime.parse('2026-05-02T10:00:00.000Z');

  const tSchoolSummary = AnnouncementSchoolSummary(
    id: 12,
    schoolName: 'Sunrise Academy',
    verificationStatus: 'VERIFIED',
  );

  const tSchoolSummaryParsed = AnnouncementSchoolSummary(
    id: 0,
    schoolName: '',
    verificationStatus: null,
  );

  final tAnnouncement = Announcement(
    id: 101,
    publisherId: 1,
    publisherType: PublisherType.moe,
    schoolId: null,
    title: 'Admissions Open',
    content: 'Applications are now open.',
    category: AnnouncementCategory.admissions,
    urgencyLevel: UrgencyLevel.high,
    datePosted: tDatePosted,
    imgUrl: '/uploads/announcement-images/a.png',
    school: tSchoolSummary,
  );

  final tAnnouncementParsedDefaults = Announcement(
    id: 202,
    publisherId: 5,
    publisherType: PublisherType.schoolAdmin,
    schoolId: 77,
    title: '',
    content: '',
    category: AnnouncementCategory.other,
    urgencyLevel: UrgencyLevel.normal,
    datePosted: tDatePosted2,
    imgUrl: null,
    school: tSchoolSummaryParsed,
  );

  group('AnnouncementCategoryX', () {
    test('toWire should map enum values correctly', () {
      expect(AnnouncementCategory.admissions.toWire(), 'ADMISSIONS');
      expect(AnnouncementCategory.policy.toWire(), 'POLICY');
      expect(AnnouncementCategory.fee.toWire(), 'FEE');
      expect(AnnouncementCategory.other.toWire(), 'OTHER');
    });

    test('label should map enum values correctly', () {
      expect(AnnouncementCategory.admissions.label(), 'Admissions');
      expect(AnnouncementCategory.policy.label(), 'Policy');
      expect(AnnouncementCategory.fee.label(), 'Fee');
      expect(AnnouncementCategory.other.label(), 'Other');
    });

    test('fromWire should map unknown values to other', () {
      expect(AnnouncementCategoryX.fromWire('ADMISSIONS'),
          AnnouncementCategory.admissions);
      expect(AnnouncementCategoryX.fromWire('POLICY'),
          AnnouncementCategory.policy);
      expect(AnnouncementCategoryX.fromWire('FEE'), AnnouncementCategory.fee);
      expect(
          AnnouncementCategoryX.fromWire('OTHER'), AnnouncementCategory.other);
      expect(AnnouncementCategoryX.fromWire('UNKNOWN'),
          AnnouncementCategory.other);
      expect(AnnouncementCategoryX.fromWire(null), AnnouncementCategory.other);
    });
  });

  group('UrgencyLevelX', () {
    test('toWire should map enum values correctly', () {
      expect(UrgencyLevel.normal.toWire(), 'NORMAL');
      expect(UrgencyLevel.high.toWire(), 'HIGH');
      expect(UrgencyLevel.emergency.toWire(), 'EMERGENCY');
    });

    test('label should map enum values correctly', () {
      expect(UrgencyLevel.normal.label(), 'Normal');
      expect(UrgencyLevel.high.label(), 'High');
      expect(UrgencyLevel.emergency.label(), 'Emergency');
    });

    test('fromWire should map unknown values to normal', () {
      expect(UrgencyLevelX.fromWire('NORMAL'), UrgencyLevel.normal);
      expect(UrgencyLevelX.fromWire('HIGH'), UrgencyLevel.high);
      expect(UrgencyLevelX.fromWire('EMERGENCY'), UrgencyLevel.emergency);
      expect(UrgencyLevelX.fromWire('UNKNOWN'), UrgencyLevel.normal);
      expect(UrgencyLevelX.fromWire(null), UrgencyLevel.normal);
    });
  });

  group('PublisherTypeX', () {
    test('toWire should map enum values correctly', () {
      expect(PublisherType.moe.toWire(), 'MOE');
      expect(PublisherType.schoolAdmin.toWire(), 'SCHOOL_ADMIN');
    });

    test('label should map enum values correctly', () {
      expect(PublisherType.moe.label(), 'Ministry');
      expect(PublisherType.schoolAdmin.label(), 'School');
    });

    test('fromWire should map unknown values to schoolAdmin', () {
      expect(PublisherTypeX.fromWire('MOE'), PublisherType.moe);
      expect(
          PublisherTypeX.fromWire('SCHOOL_ADMIN'), PublisherType.schoolAdmin);
      expect(PublisherTypeX.fromWire('UNKNOWN'), PublisherType.schoolAdmin);
      expect(PublisherTypeX.fromWire(null), PublisherType.schoolAdmin);
    });
  });

  group('AnnouncementSchoolSummary', () {
    group('fromJson', () {
      test('should parse expected JSON', () {
        // Arrange
        final Map<String, dynamic> jsonMap = json.decode(fixture(
            'AnnouncementSchoolSummary/AnnouncementSchoolSummary.json'));

        // Act
        final result = AnnouncementSchoolSummary.fromJson(jsonMap);

        // Assert
        expect(result.id, tSchoolSummary.id);
        expect(result.schoolName, tSchoolSummary.schoolName);
        expect(result.verificationStatus, tSchoolSummary.verificationStatus);
      });
    });
  });

  group('Announcement', () {
    group('fromJson', () {
      test('should parse expected JSON', () {
        // Arrange
        final Map<String, dynamic> jsonMap =
            json.decode(fixture('Announcement/Announcement.json'));

        // Act
        final result = Announcement.fromJson(jsonMap);

        // Assert
        expect(result.id, tAnnouncement.id);
        expect(result.publisherId, tAnnouncement.publisherId);
        expect(result.publisherType, tAnnouncement.publisherType);
        expect(result.schoolId, tAnnouncement.schoolId);
        expect(result.title, tAnnouncement.title);
        expect(result.content, tAnnouncement.content);
        expect(result.category, tAnnouncement.category);
        expect(result.urgencyLevel, tAnnouncement.urgencyLevel);
        expect(result.datePosted, tAnnouncement.datePosted);
        expect(result.imgUrl, tAnnouncement.imgUrl);
        expect(result.school?.id, tAnnouncement.school?.id);
        expect(result.school?.schoolName, tAnnouncement.school?.schoolName);
        expect(result.school?.verificationStatus,
            tAnnouncement.school?.verificationStatus);
      });

      test(
          'should parse strings and fall back to defaults for unknown enum values',
          () {
        // Arrange
        final Map<String, dynamic> jsonMap = json.decode(
            fixture('Announcement/Announcement_string_and_defaults.json'));

        // Act
        final result = Announcement.fromJson(jsonMap);

        // Assert
        expect(result.id, tAnnouncementParsedDefaults.id);
        expect(result.publisherId, tAnnouncementParsedDefaults.publisherId);
        expect(result.publisherType, tAnnouncementParsedDefaults.publisherType);
        expect(result.schoolId, tAnnouncementParsedDefaults.schoolId);
        expect(result.title, tAnnouncementParsedDefaults.title);
        expect(result.content, tAnnouncementParsedDefaults.content);
        expect(result.category, tAnnouncementParsedDefaults.category);
        expect(result.urgencyLevel, tAnnouncementParsedDefaults.urgencyLevel);
        expect(result.datePosted, tAnnouncementParsedDefaults.datePosted);
        expect(result.imgUrl, tAnnouncementParsedDefaults.imgUrl);
        expect(result.school?.id, tAnnouncementParsedDefaults.school?.id);
        expect(result.school?.schoolName,
            tAnnouncementParsedDefaults.school?.schoolName);
        expect(result.school?.verificationStatus,
            tAnnouncementParsedDefaults.school?.verificationStatus);
      });

      test('should default bad ints to zero while keeping valid strings', () {
        // Arrange
        final Map<String, dynamic> jsonMap =
            json.decode(fixture('Announcement/Announcement_bad_ints.json'));

        // Act
        final result = Announcement.fromJson(jsonMap);

        // Assert
        expect(result.id, 0);
        expect(result.publisherId, 0);
        expect(result.publisherType, PublisherType.moe);
        expect(result.schoolId, null);
        expect(result.title, 'Broken Payload');
        expect(result.content, 'Still a string');
        expect(result.category, AnnouncementCategory.admissions);
        expect(result.urgencyLevel, UrgencyLevel.high);
        expect(result.school?.id, 0);
        expect(result.school?.schoolName, 'Broken School');
        expect(result.school?.verificationStatus, 'PENDING');
      });
    });
  });

  group('AnnouncementInput', () {
    test('toJson should include schoolId when present', () {
      // Arrange
      const input = AnnouncementInput(
        title: 'Policy Update',
        content: 'Updated policy text',
        category: AnnouncementCategory.policy,
        urgencyLevel: UrgencyLevel.normal,
        schoolId: 9,
      );

      // Act
      final result = input.toJson();

      // Assert
      expect(result, {
        'title': 'Policy Update',
        'content': 'Updated policy text',
        'category': 'POLICY',
        'urgencyLevel': 'NORMAL',
        'schoolId': 9,
      });
    });

    test('toJson should omit schoolId when null', () {
      // Arrange
      const input = AnnouncementInput(
        title: 'Fee Notice',
        content: 'Fee schedule updated',
        category: AnnouncementCategory.fee,
        urgencyLevel: UrgencyLevel.high,
        schoolId: null,
      );

      // Act
      final result = input.toJson();

      // Assert
      expect(result, {
        'title': 'Fee Notice',
        'content': 'Fee schedule updated',
        'category': 'FEE',
        'urgencyLevel': 'HIGH',
      });
      expect(result.containsKey('schoolId'), false);
    });
  });
}
