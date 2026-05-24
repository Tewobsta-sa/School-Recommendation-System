import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_rec/features/analytics/data/analytics_dtos.dart';

import '../../../fixture_reader.dart';

void main() {
  const tDashboardSummary = DashboardSummary(
    totalUsers: 100,
    totalSchools: 50,
    totalReviews: 200,
    totalAnnouncements: 10,
    totalReports: 5,
    totalForumPosts: 150,
    totalFollows: 300,
    averageRating: 4.5,
  );

  const tDashboardSummaryZeros = DashboardSummary(
    totalUsers: 0,
    totalSchools: 0,
    totalReviews: 0,
    totalAnnouncements: 0,
    totalReports: 0,
    totalForumPosts: 0,
    totalFollows: 0,
    averageRating: 0.0,
  );

  const tTopSchool = TopSchool(
    id: 1,
    schoolName: 'Alpha School',
    rating: 4.2,
    reviewCount: 10,
    verificationStatus: 'VERIFIED',
  );

  const tTopSchoolDefaults = TopSchool(
    id: 2,
    schoolName: '?',
    rating: 3.5,
    reviewCount: 0,
    verificationStatus: 'PENDING',
  );

  const tTopSchoolParsed = TopSchool(
    id: 2,
    schoolName: 'Beta School',
    rating: 3.5,
    reviewCount: 5,
    verificationStatus: 'VERIFIED',
  );

  const tMostFollowed = MostFollowed(
    schoolId: 1,
    schoolName: 'Alpha School',
    followers: 100,
  );

  const tMostFollowedParsed = MostFollowed(
    schoolId: 2,
    schoolName: null,
    followers: 50,
  );

  const tMostFollowedMissingName = MostFollowed(
    schoolId: 2,
    schoolName: null,
    followers: 50,
  );

  const tMoeRanked = MoeRankedSchool(
    id: 1,
    schoolName: 'Gamma School',
    rating: 4.7,
    reviewCount: 20,
    verificationStatus: 'VERIFIED',
    facilities: 'Library',
    moeScore: 92.5,
    schoolLevel: 'Secondary',
    schoolType: 'Public',
    passingRate: 0.85,
    nationalExamScore: 78,
  );

  const tMoeRankedParsed = MoeRankedSchool(
    id: 2,
    schoolName: 'Delta School',
    rating: 4.3,
    reviewCount: 15,
    verificationStatus: 'PENDING',
    facilities: null,
    moeScore: 88.0,
    schoolLevel: null,
    schoolType: null,
    passingRate: 0.9,
    nationalExamScore: 82,
  );

  const tDashboardFull = Dashboard(
    summary: tDashboardSummary,
    usersByRole: {'ADMIN': 2, 'USER': 10},
    schoolsByVerification: {'VERIFIED': 5, 'PENDING': 1},
    reportsByStatus: {'OPEN': 3},
    topSchools: [tTopSchool, tTopSchoolParsed],
    mostFollowed: [tMostFollowed, tMostFollowedParsed],
    moeRanking: [tMoeRanked, tMoeRankedParsed],
  );

  group('DashboardSummary', () {
    group('fromJson', () {
      test("fromJson should work when the json types match the expected types",
          () {
        // Arrange
        final Map<String, dynamic> jsonMap =
            json.decode(fixture('DashboardSummary/DashboardSummary.json'));

        // Act
        final result = DashboardSummary.fromJson(jsonMap);

        // Assert
        expect(result.totalUsers, tDashboardSummary.totalUsers);
        expect(result.totalSchools, tDashboardSummary.totalSchools);
        expect(result.totalReviews, tDashboardSummary.totalReviews);
        expect(result.totalAnnouncements, tDashboardSummary.totalAnnouncements);
        expect(result.totalReports, tDashboardSummary.totalReports);
        expect(result.totalForumPosts, tDashboardSummary.totalForumPosts);
        expect(result.totalFollows, tDashboardSummary.totalFollows);
        expect(result.averageRating, tDashboardSummary.averageRating);
      });

      test(
          "fromJson should handle string values that can be parsed as integers/doubles",
          () {
        final Map<String, dynamic> jsonMap = json
            .decode(fixture('DashboardSummary/DashboardSummary_string.json'));
        final result = DashboardSummary.fromJson(jsonMap);
        expect(result.totalUsers, tDashboardSummary.totalUsers);
        expect(result.totalSchools, tDashboardSummary.totalSchools);
        expect(result.totalReviews, tDashboardSummary.totalReviews);
        expect(result.totalAnnouncements, tDashboardSummary.totalAnnouncements);
        expect(result.totalReports, tDashboardSummary.totalReports);
        expect(result.totalForumPosts, tDashboardSummary.totalForumPosts);
        expect(result.totalFollows, tDashboardSummary.totalFollows);
        expect(result.averageRating, tDashboardSummary.averageRating);
      });

      test("fromJson should default to 0 when the string fails to parse", () {
        final Map<String, dynamic> jsonMap = json.decode(fixture(
            'DashboardSummary/DashboardSummary_string_unparsable.json'));
        final result = DashboardSummary.fromJson(jsonMap);
        expect(result.totalUsers, tDashboardSummaryZeros.totalUsers);
        expect(result.totalSchools, tDashboardSummaryZeros.totalSchools);
        expect(result.totalReviews, tDashboardSummaryZeros.totalReviews);
        expect(result.totalAnnouncements,
            tDashboardSummaryZeros.totalAnnouncements);
        expect(result.totalReports, tDashboardSummaryZeros.totalReports);
        expect(result.totalForumPosts, tDashboardSummaryZeros.totalForumPosts);
        expect(result.totalFollows, tDashboardSummaryZeros.totalFollows);
        expect(result.averageRating, tDashboardSummaryZeros.averageRating);
      });
    });
  });

  group('TopSchool', () {
    group('fromJson', () {
      test('fromJson should work when the json types match the expected types',
          () {
        // Arrange
        final Map<String, dynamic> jsonMap =
            json.decode(fixture('TopSchool/TopSchool.json'));

        // Act
        final result = TopSchool.fromJson(jsonMap);

        // Assert
        expect(result.id, tTopSchool.id);
        expect(result.schoolName, tTopSchool.schoolName);
        expect(result.rating, tTopSchool.rating);
        expect(result.reviewCount, tTopSchool.reviewCount);
        expect(result.verificationStatus, tTopSchool.verificationStatus);
      });

      test('fromJson should parse numeric strings when values are parseable',
          () {
        final Map<String, dynamic> jsonMap =
            json.decode(fixture('TopSchool/TopSchool_string_parsable.json'));

        final result = TopSchool.fromJson(jsonMap);
        expect(result.id, tTopSchoolParsed.id);
        expect(result.schoolName, tTopSchoolParsed.schoolName);
        expect(result.rating, tTopSchoolParsed.rating);
        expect(result.reviewCount, tTopSchoolParsed.reviewCount);
        expect(result.verificationStatus, tTopSchoolParsed.verificationStatus);
      });

      test(
          'fromJson should partially parse and fall back to defaults when values are not parseable',
          () {
        final Map<String, dynamic> jsonMap =
            json.decode(fixture('TopSchool/TopSchool_string.json'));

        final result = TopSchool.fromJson(jsonMap);
        expect(result.id, tTopSchoolDefaults.id);
        expect(result.schoolName, tTopSchoolDefaults.schoolName);
        expect(result.rating, tTopSchoolDefaults.rating);
        expect(result.reviewCount, tTopSchoolDefaults.reviewCount);
        expect(
            result.verificationStatus, tTopSchoolDefaults.verificationStatus);
      });
    });
  });

  group('MostFollowed', () {
    group('fromJson', () {
      test('fromJson should work with expected types', () {
        // Arrange
        final jsonMap = json.decode(fixture('MostFollowed/MostFollowed.json'));

        // Act
        final result = MostFollowed.fromJson(jsonMap);

        // Assert
        expect(result.schoolId, tMostFollowed.schoolId);
        expect(result.schoolName, tMostFollowed.schoolName);
        expect(result.followers, tMostFollowed.followers);
      });

      test('fromJson should parse numeric strings', () {
        final jsonMap =
            json.decode(fixture('MostFollowed/MostFollowed_string.json'));
        final result = MostFollowed.fromJson(jsonMap);
        expect(result.schoolId, tMostFollowedParsed.schoolId);
        expect(result.schoolName, tMostFollowedParsed.schoolName);
        expect(result.followers, tMostFollowedParsed.followers);
      });

      test('fromJson should handle missing schoolName key', () {
        final jsonMap =
            json.decode(fixture('MostFollowed/MostFollowed_missing_name.json'));
        final result = MostFollowed.fromJson(jsonMap);
        expect(result.schoolId, tMostFollowedMissingName.schoolId);
        expect(result.schoolName, tMostFollowedMissingName.schoolName);
        expect(result.followers, tMostFollowedMissingName.followers);
      });
    });
  });

  group('MoeRankedSchool', () {
    group('fromJson', () {
      test('fromJson should work with numeric types', () {
        // Arrange
        final jsonMap =
            json.decode(fixture('MoeRankedSchool/MoeRankedSchool.json'));

        // Act
        final result = MoeRankedSchool.fromJson(jsonMap);

        // Assert
        expect(result.id, tMoeRanked.id);
        expect(result.schoolName, tMoeRanked.schoolName);
        expect(result.rating, tMoeRanked.rating);
        expect(result.reviewCount, tMoeRanked.reviewCount);
        expect(result.verificationStatus, tMoeRanked.verificationStatus);
        expect(result.facilities, tMoeRanked.facilities);
        expect(result.moeScore, tMoeRanked.moeScore);
        expect(result.schoolLevel, tMoeRanked.schoolLevel);
        expect(result.schoolType, tMoeRanked.schoolType);
        expect(result.passingRate, tMoeRanked.passingRate);
        expect(result.nationalExamScore, tMoeRanked.nationalExamScore);
      });

      test('fromJson should parse numeric strings and coerce types', () {
        final jsonMap =
            json.decode(fixture('MoeRankedSchool/MoeRankedSchool_string.json'));
        final result = MoeRankedSchool.fromJson(jsonMap);
        expect(result.id, tMoeRankedParsed.id);
        expect(result.schoolName, tMoeRankedParsed.schoolName);
        expect(result.rating, tMoeRankedParsed.rating);
        expect(result.reviewCount, tMoeRankedParsed.reviewCount);
        expect(result.verificationStatus, tMoeRankedParsed.verificationStatus);
        expect(result.facilities, tMoeRankedParsed.facilities);
        expect(result.moeScore, tMoeRankedParsed.moeScore);
        expect(result.schoolLevel, tMoeRankedParsed.schoolLevel);
        expect(result.schoolType, tMoeRankedParsed.schoolType);
        expect(result.passingRate, tMoeRankedParsed.passingRate);
        expect(result.nationalExamScore, tMoeRankedParsed.nationalExamScore);
      });
    });
  });

  group('Dashboard', () {
    group('fromJson', () {
      test('fromJson should parse the full dashboard structure', () {
        // Arrange
        final jsonMap = json.decode(fixture('Dashboard/Dashboard_full.json'));

        // Act
        final result = Dashboard.fromJson(jsonMap);

        // Assert
        // summary
        expect(result.summary.totalUsers, tDashboardFull.summary.totalUsers);
        expect(
            result.summary.totalSchools, tDashboardFull.summary.totalSchools);
        expect(
            result.summary.totalReviews, tDashboardFull.summary.totalReviews);
        // maps
        expect(result.usersByRole, tDashboardFull.usersByRole);
        expect(
            result.schoolsByVerification, tDashboardFull.schoolsByVerification);
        expect(result.reportsByStatus, tDashboardFull.reportsByStatus);
        // lists lengths
        expect(result.topSchools.length, tDashboardFull.topSchools.length);
        expect(result.mostFollowed.length, tDashboardFull.mostFollowed.length);
        expect(result.moeRanking.length, tDashboardFull.moeRanking.length);
        // check some nested values
        expect(result.topSchools[0].id, tDashboardFull.topSchools[0].id);
        expect(result.topSchools[1].id, tDashboardFull.topSchools[1].id);
        expect(result.mostFollowed[0].schoolId,
            tDashboardFull.mostFollowed[0].schoolId);
        expect(result.moeRanking[0].id, tDashboardFull.moeRanking[0].id);
      });
    });
  });
}
