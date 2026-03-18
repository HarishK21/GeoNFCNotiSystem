import 'package:flutter_test/flutter_test.dart';

import 'package:geo_tap_guardian/core/models/app_role.dart';
import 'package:geo_tap_guardian/domain/models/user_profile.dart';
import 'package:geo_tap_guardian/domain/services/notification_topic_planner.dart';

void main() {
  const planner = NotificationTopicPlanner();

  test('staff profiles subscribe to staff and emergency topics', () {
    final topics = planner.topicsForProfile(
      const UserProfile(
        uid: 'staff_1',
        role: AppRole.staff,
        schoolId: 'school_1',
        displayName: 'Ms. Carson',
        email: 'mcarson@example.com',
      ),
    );

    expect(topics, contains('school_school_1_staff'));
    expect(topics, contains('school_school_1_emergency'));
  });

  test('parent profiles subscribe to guardian and emergency topics', () {
    final topics = planner.topicsForProfile(
      const UserProfile(
        uid: 'parent_1',
        role: AppRole.parent,
        schoolId: 'school_1',
        displayName: 'Andrea Brooks',
        email: 'andrea@example.com',
        linkedGuardianId: 'guardian_1',
      ),
    );

    expect(topics, contains('school_school_1_guardian_guardian_1'));
    expect(topics, contains('school_school_1_emergency'));
    expect(topics, isNot(contains('school_school_1_staff')));
  });

  test('parent profiles without linked guardian only keep emergency topic', () {
    final topics = planner.topicsForProfile(
      const UserProfile(
        uid: 'parent_1',
        role: AppRole.parent,
        schoolId: 'school_1',
        displayName: 'Andrea Brooks',
        email: 'andrea@example.com',
      ),
    );

    expect(topics, {'school_school_1_emergency'});
  });
}
