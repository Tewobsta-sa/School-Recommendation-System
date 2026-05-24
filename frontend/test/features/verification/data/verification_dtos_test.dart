import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:school_rec/features/verification/data/verification_dtos.dart';

void main() {
  group('Verification DTOs', () {
    test('VerificationRequestStatus wire/label/fromWire', () {
      // Arrange & Act: call mapping helpers
      expect(VerificationRequestStatus.pending.toWire(), 'PENDING');
      expect(VerificationRequestStatus.approved.toWire(), 'APPROVED');
      expect(VerificationRequestStatus.rejected.toWire(), 'REJECTED');

      // Assert: labels and fromWire
      expect(VerificationRequestStatus.pending.label(), 'Pending');
      expect(VerificationRequestStatus.approved.label(), 'Approved');

      expect(VerificationRequestStatusX.fromWire('APPROVED'),
          VerificationRequestStatus.approved);
      expect(VerificationRequestStatusX.fromWire('UNKNOWN'),
          VerificationRequestStatus.pending);
    });

    test('VerificationDocument.fromJson handles object and string forms', () {
      // Arrange
      final obj = VerificationDocument.fromJson(
          {'url': '/files/a.pdf', 'originalName': 'a.pdf', 'size': 123});
      // Assert basic document fields
      expect(obj.url, '/files/a.pdf');
      expect(obj.originalName, 'a.pdf');
      expect(obj.size, 123);

      // Arrange: encoded JSON where documents are strings
      final jsonMap = json.decode(
          '{"id":1, "schoolId":2, "submittedById":3, "status":"PENDING", "documents": ["/files/a.pdf"], "submittedAt": "2026-05-01T10:00:00.000Z"}');
      // Act
      final req = VerificationRequest.fromJson(jsonMap as Map<String, dynamic>);
      // Assert
      expect(req.documents, isNotEmpty);
      expect(req.documents.first.url, '/files/a.pdf');
    });
  });
}
