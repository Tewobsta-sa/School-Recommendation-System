import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:school_rec/features/reports/data/report_dtos.dart';

void main() {
  group('Report DTOs', () {
    test('Report.fromJson parses core fields and reporter', () {
      // Arrange
      const jsonStr =
          '{"id":3,"reporterId":2,"targetType":"REVIEW","targetId":9,"reason":"Spam","status":"PENDING","createdAt":"2026-05-01T10:00:00.000Z","reporter":{"fullName":"Alice"}}';

      // Act
      final r = Report.fromJson(json.decode(jsonStr) as Map<String, dynamic>);

      // Assert
      expect(r.id, 3);
      expect(r.targetType, ReportTargetType.review);
      expect(r.reporterName, 'Alice');
    });

    test('ReportInput and ModeratorActionInput toJson formats correctly', () {
      // Arrange
      const in1 = ReportInput(
          targetType: ReportTargetType.school, targetId: 5, reason: 'Abuse');

      // Act & Assert
      expect(in1.toJson()['targetType'], 'SCHOOL');

      const act = ModeratorActionInput(
          actionType: ModeratorActionType.removeContent, notes: 'Removed');
      expect(act.toJson()['actionType'], 'REMOVE_CONTENT');
      expect(act.toJson()['notes'], 'Removed');
    });
  });
}

// enum ReportTargetType { review, school, announcement, forumPost }

// extension ReportTargetTypeX on ReportTargetType {
//   String toWire() {
//     switch (this) {
//       case ReportTargetType.review:
//         return 'REVIEW';
//       case ReportTargetType.school:
//         return 'SCHOOL';
//       case ReportTargetType.announcement:
//         return 'ANNOUNCEMENT';
//       case ReportTargetType.forumPost:
//         return 'FORUM_POST';
//     }
//   }

//   String label() {
//     switch (this) {
//       case ReportTargetType.review:
//         return 'Review';
//       case ReportTargetType.school:
//         return 'School';
//       case ReportTargetType.announcement:
//         return 'Announcement';
//       case ReportTargetType.forumPost:
//         return 'Forum post';
//     }
//   }

//   static ReportTargetType fromWire(String? s) {
//     switch (s) {
//       case 'REVIEW':
//         return ReportTargetType.review;
//       case 'SCHOOL':
//         return ReportTargetType.school;
//       case 'ANNOUNCEMENT':
//         return ReportTargetType.announcement;
//       case 'FORUM_POST':
//       default:
//         return ReportTargetType.forumPost;
//     }
//   }
// }

// enum ReportStatus { pending, reviewed, resolved }

// extension ReportStatusX on ReportStatus {
//   String toWire() {
//     switch (this) {
//       case ReportStatus.pending:
//         return 'PENDING';
//       case ReportStatus.reviewed:
//         return 'REVIEWED';
//       case ReportStatus.resolved:
//         return 'RESOLVED';
//     }
//   }

//   String label() {
//     switch (this) {
//       case ReportStatus.pending:
//         return 'Pending';
//       case ReportStatus.reviewed:
//         return 'Reviewed';
//       case ReportStatus.resolved:
//         return 'Resolved';
//     }
//   }

//   static ReportStatus fromWire(String? s) {
//     switch (s) {
//       case 'REVIEWED':
//         return ReportStatus.reviewed;
//       case 'RESOLVED':
//         return ReportStatus.resolved;
//       case 'PENDING':
//       default:
//         return ReportStatus.pending;
//     }
//   }
// }

// enum ModeratorActionType { dismiss, removeContent, warnUser, banUser }

// extension ModeratorActionTypeX on ModeratorActionType {
//   String toWire() {
//     switch (this) {
//       case ModeratorActionType.dismiss:
//         return 'DISMISS';
//       case ModeratorActionType.removeContent:
//         return 'REMOVE_CONTENT';
//       case ModeratorActionType.warnUser:
//         return 'WARN_USER';
//       case ModeratorActionType.banUser:
//         return 'BAN_USER';
//     }
//   }

//   String label() {
//     switch (this) {
//       case ModeratorActionType.dismiss:
//         return 'Dismiss';
//       case ModeratorActionType.removeContent:
//         return 'Remove content';
//       case ModeratorActionType.warnUser:
//         return 'Warn user';
//       case ModeratorActionType.banUser:
//         return 'Ban user';
//     }
//   }
// }

// class Report {
//   final int id;
//   final int reporterId;
//   final ReportTargetType targetType;
//   final int targetId;
//   final String reason;
//   final ReportStatus status;
//   final DateTime createdAt;
//   final String? reporterName;

//   const Report({
//     required this.id,
//     required this.reporterId,
//     required this.targetType,
//     required this.targetId,
//     required this.reason,
//     required this.status,
//     required this.createdAt,
//     required this.reporterName,
//   });

//   factory Report.fromJson(Map<String, dynamic> json) {
//     int parseInt(dynamic v) {
//       if (v is num) return v.toInt();
//       if (v is String) return int.tryParse(v) ?? 0;
//       return 0;
//     }

//     DateTime parseDate(dynamic v) {
//       if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
//       return DateTime.now();
//     }

//     final reporter = (json['reporter'] as Map?)?.cast<String, dynamic>();
//     return Report(
//       id: parseInt(json['id']),
//       reporterId: parseInt(json['reporterId']),
//       targetType: ReportTargetTypeX.fromWire(json['targetType'] as String?),
//       targetId: parseInt(json['targetId']),
//       reason: (json['reason'] ?? '') as String,
//       status: ReportStatusX.fromWire(json['status'] as String?),
//       createdAt: parseDate(json['createdAt']),
//       reporterName: reporter?['fullName'] as String?,
//     );
//   }
// }

// class ReportInput {
//   final ReportTargetType targetType;
//   final int targetId;
//   final String reason;
//   const ReportInput({
//     required this.targetType,
//     required this.targetId,
//     required this.reason,
//   });

//   Map<String, dynamic> toJson() => {
//         'targetType': targetType.toWire(),
//         'targetId': targetId,
//         'reason': reason,
//       };
// }

// class ModeratorActionInput {
//   final ModeratorActionType actionType;
//   final String? notes;
//   const ModeratorActionInput({required this.actionType, this.notes});

//   Map<String, dynamic> toJson() => {
//         'actionType': actionType.toWire(),
//         if (notes != null && notes!.isNotEmpty) 'notes': notes,
//       };
// }

// class ReportRequest {
//   final ReportTargetType targetType;
//   final int targetId;
//   final String reason;

//   const ReportRequest({
//     required this.targetType,
//     required this.targetId,
//     required this.reason,
//   });

//   Map<String, dynamic> toJson() => {
//         'targetType': targetType.toWire(),
//         'targetId': targetId,
//         'reason': reason,
//       };
// }
