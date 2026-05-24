import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:school_rec/features/auth/data/auth_dtos.dart';

import '../../../fixture_reader.dart';

void main() {
  group('UserRoleX', () {
    test('label returns human friendly text', () {
      expect(UserRole.parent.label(), 'Parent');
      expect(UserRole.schoolAdmin.label(), 'School admin');
      expect(UserRole.moeOfficer.label(), 'MoE officer');
      expect(UserRole.moderator.label(), 'Moderator');
    });

    test('round-trips toWire/fromWire', () {
      for (final r in UserRole.values) {
        expect(UserRoleX.fromWire(r.toWire()), r);
      }
    });

    test('fromWire throws for unknown string', () {
      expect(() => UserRoleX.fromWire('UNKNOWN'), throwsArgumentError);
    });
  });

  group('AppUser.fromJson', () {
    test('parses id when provided as num (double)', () {
      // Arrange
      final jsonMap = json.decode(fixture('Auth/AppUser_num_id.json'))
          as Map<String, dynamic>;

      // Act
      final user = AppUser.fromJson(jsonMap);

      // Assert
      expect(user.id, 7);
      expect(user.role, UserRole.parent);
    });

    test('copyWith updates fields', () {
      // Arrange
      final jsonMap = json.decode(fixture('Auth/AppUser_full.json'))
          as Map<String, dynamic>;
      final user = AppUser.fromJson(jsonMap);

      // Act
      final updated = user.copyWith(fullName: 'New', phone: '111');

      // Assert
      expect(updated.fullName, 'New');
      expect(updated.phone, '111');
      expect(updated.id, user.id);
    });

    test('LoginResult holds token and user', () {
      // Arrange
      final jsonMap = json.decode(fixture('Auth/AppUser_login.json'))
          as Map<String, dynamic>;
      final user = AppUser.fromJson(jsonMap);

      // Act
      final lr = LoginResult(token: 'tok', user: user);

      // Assert
      expect(lr.token, 'tok');
      expect(lr.user.id, 11);
    });

    test('throws TypeError when id is missing', () {
      // Arrange
      final jsonMap = json.decode(fixture('Auth/AppUser_missing_id.json'))
          as Map<String, dynamic>;

      // Assert
      expect(() => AppUser.fromJson(jsonMap), throwsA(isA<TypeError>()));
    });

    test('throws TypeError when id is a string', () {
      // Arrange
      final jsonMap = json.decode(fixture('Auth/AppUser_id_string.json'))
          as Map<String, dynamic>;

      // Assert
      expect(() => AppUser.fromJson(jsonMap), throwsA(isA<TypeError>()));
    });
  });
}
