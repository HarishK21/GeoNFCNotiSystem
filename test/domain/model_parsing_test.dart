import 'package:flutter_test/flutter_test.dart';

import 'package:geo_tap_guardian/core/models/app_role.dart';
import 'package:geo_tap_guardian/domain/models/emergency_notice.dart';
import 'package:geo_tap_guardian/domain/models/pickup_permission.dart';
import 'package:geo_tap_guardian/domain/models/user_profile.dart';

void main() {
  test('user profile parsing resolves role and optional phone', () {
    final profile = UserProfile.fromMap({
      'uid': 'user_1',
      'role': 'staff',
      'schoolId': 'school_1',
      'displayName': 'Ms. Carson',
      'email': 'mcarson@example.com',
      'phone': '+1-555-0100',
    });

    expect(profile.uid, 'user_1');
    expect(profile.role, AppRole.staff);
    expect(profile.phone, '+1-555-0100');
  });

  test('pickup permission parsing resolves time window and status', () {
    final permission = PickupPermission.fromMap({
      'id': 'permission_1',
      'schoolId': 'school_1',
      'studentId': 'student_1',
      'guardianId': 'guardian_1',
      'delegateName': 'Jordan Brooks',
      'delegatePhone': '+1-555-0101',
      'relationship': 'Grandparent',
      'approvedBy': 'Front Office',
      'startsAt': '2026-03-17T15:00:00Z',
      'endsAt': '2026-03-17T16:00:00Z',
      'isActive': true,
    });

    expect(permission.delegateName, 'Jordan Brooks');
    expect(permission.startsAt.toUtc().hour, 15);
    expect(permission.isActive, isTrue);
  });

  test('emergency notice parsing resolves severity', () {
    final notice = EmergencyNotice.fromMap({
      'id': 'notice_1',
      'schoolId': 'school_1',
      'title': 'Pickup paused',
      'body': 'Hold all releases until the all-clear.',
      'severity': 'critical',
      'sentAt': '2026-03-17T15:10:00Z',
      'isActive': true,
    });

    expect(notice.severity, EmergencySeverity.critical);
    expect(notice.isActive, isTrue);
  });
}
