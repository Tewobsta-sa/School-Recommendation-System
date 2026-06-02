// DTOs for `/api/announcements/*`. Mirrors Prisma `Announcement`.

enum AnnouncementCategory { admissions, policy, fee, other }

extension AnnouncementCategoryX on AnnouncementCategory {
  String toWire() {
    switch (this) {
      case AnnouncementCategory.admissions:
        return 'ADMISSIONS';
      case AnnouncementCategory.policy:
        return 'POLICY';
      case AnnouncementCategory.fee:
        return 'FEE';
      case AnnouncementCategory.other:
        return 'OTHER';
    }
  }

  String label() {
    switch (this) {
      case AnnouncementCategory.admissions:
        return 'Admissions';
      case AnnouncementCategory.policy:
        return 'Policy';
      case AnnouncementCategory.fee:
        return 'Fee';
      case AnnouncementCategory.other:
        return 'Other';
    }
  }

  static AnnouncementCategory fromWire(String? s) {
    switch (s) {
      case 'ADMISSIONS':
        return AnnouncementCategory.admissions;
      case 'POLICY':
        return AnnouncementCategory.policy;
      case 'FEE':
        return AnnouncementCategory.fee;
      case 'OTHER':
      default:
        return AnnouncementCategory.other;
    }
  }
}

enum UrgencyLevel { normal, high, emergency }

extension UrgencyLevelX on UrgencyLevel {
  String toWire() {
    switch (this) {
      case UrgencyLevel.normal:
        return 'NORMAL';
      case UrgencyLevel.high:
        return 'HIGH';
      case UrgencyLevel.emergency:
        return 'EMERGENCY';
    }
  }

  String label() {
    switch (this) {
      case UrgencyLevel.normal:
        return 'Normal';
      case UrgencyLevel.high:
        return 'High';
      case UrgencyLevel.emergency:
        return 'Emergency';
    }
  }

  static UrgencyLevel fromWire(String? s) {
    switch (s) {
      case 'HIGH':
        return UrgencyLevel.high;
      case 'EMERGENCY':
        return UrgencyLevel.emergency;
      case 'NORMAL':
      default:
        return UrgencyLevel.normal;
    }
  }
}

enum PublisherType { moe, schoolAdmin }

extension PublisherTypeX on PublisherType {
  String toWire() =>
      this == PublisherType.moe ? 'MOE' : 'SCHOOL_ADMIN';

  String label() => this == PublisherType.moe ? 'Ministry' : 'School';

  static PublisherType fromWire(String? s) =>
      s == 'MOE' ? PublisherType.moe : PublisherType.schoolAdmin;
}

/// Slim join row the backend includes on announcement payloads
/// so we don't have to round-trip /api/schools/:id to print "Sunrise
/// Academy" next to a ministry-wide post.
class AnnouncementSchoolSummary {
  final int id;
  final String schoolName;
  final String? verificationStatus;
  const AnnouncementSchoolSummary({
    required this.id,
    required this.schoolName,
    required this.verificationStatus,
  });

  factory AnnouncementSchoolSummary.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic v) {
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }
    return AnnouncementSchoolSummary(
      id: parseInt(json['id']),
      schoolName: (json['schoolName'] ?? '') as String,
      verificationStatus: json['verificationStatus'] as String?,
    );
  }
}

class Announcement {
  final int id;
  final int publisherId;
  final PublisherType publisherType;
  final int? schoolId;
  final String title;
  final String content;
  final AnnouncementCategory category;
  final UrgencyLevel urgencyLevel;
  final DateTime datePosted;
  final String? imgUrl;
  final AnnouncementSchoolSummary? school;

  const Announcement({
    required this.id,
    required this.publisherId,
    required this.publisherType,
    required this.schoolId,
    required this.title,
    required this.content,
    required this.category,
    required this.urgencyLevel,
    required this.datePosted,
    required this.imgUrl,
    required this.school,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic v) {
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }
    int? parseIntOrNull(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString());
    }
    DateTime parseDate(dynamic v) {
      if (v == null) return DateTime.now();
      if (v is DateTime) return v;
      if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
      return DateTime.now();
    }
    final schoolJson = (json['school'] as Map?)?.cast<String, dynamic>();
    return Announcement(
      id: parseInt(json['id']),
      publisherId: parseInt(json['publisherId']),
      publisherType:
          PublisherTypeX.fromWire(json['publisherType'] as String?),
      schoolId: parseIntOrNull(json['schoolId']),
      title: (json['title'] ?? '') as String,
      content: (json['content'] ?? '') as String,
      category: AnnouncementCategoryX.fromWire(json['category'] as String?),
      urgencyLevel:
          UrgencyLevelX.fromWire(json['urgencyLevel'] as String?),
      datePosted: parseDate(json['datePosted'] ?? json['createdAt']),
      imgUrl: json['imgUrl'] as String?,
      school: schoolJson == null
          ? null
          : AnnouncementSchoolSummary.fromJson(schoolJson),
    );
  }
}

class AnnouncementInput {
  final String title;
  final String content;
  final AnnouncementCategory category;
  final UrgencyLevel urgencyLevel;
  final int? schoolId;

  const AnnouncementInput({
    required this.title,
    required this.content,
    required this.category,
    required this.urgencyLevel,
    required this.schoolId,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'content': content,
        'category': category.toWire(),
        'urgencyLevel': urgencyLevel.toWire(),
        if (schoolId != null) 'schoolId': schoolId,
      };
}
