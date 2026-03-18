import 'package:flutter_test/flutter_test.dart';

import 'package:geo_tap_guardian/core/models/app_role.dart';
import 'package:geo_tap_guardian/domain/models/emergency_notice.dart';
import 'package:geo_tap_guardian/domain/models/geofence_trigger_event.dart';
import 'package:geo_tap_guardian/domain/models/nfc_verification_event.dart';
import 'package:geo_tap_guardian/domain/models/office_approval_record.dart';
import 'package:geo_tap_guardian/domain/models/office_approval_status.dart';
import 'package:geo_tap_guardian/domain/models/pickup_queue_entry.dart';
import 'package:geo_tap_guardian/domain/models/pickup_permission.dart';
import 'package:geo_tap_guardian/domain/models/push_notification_job.dart';
import 'package:geo_tap_guardian/domain/models/release_event.dart';
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
      'linkedGuardianId': 'guardian_1',
    });

    expect(profile.uid, 'user_1');
    expect(profile.role, AppRole.staff);
    expect(profile.phone, '+1-555-0100');
    expect(profile.linkedGuardianId, 'guardian_1');
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

  test(
    'pickup queue entry parsing resolves released state and exception flag',
    () {
      final entry = PickupQueueEntry.fromMap({
        'id': 'queue_1',
        'schoolId': 'school_1',
        'studentId': 'student_1',
        'studentName': 'Maya Brooks',
        'guardianId': 'guardian_1',
        'guardianName': 'Andrea Brooks',
        'homeroom': 'Grade 2 - Cedar',
        'pickupZone': 'North Loop',
        'etaLabel': 'Released',
        'eventType': 'released',
        'isNfcVerified': true,
        'exceptionFlag': 'ID check completed',
        'exceptionCode': 'officeApprovalRequired',
        'officeApprovalRequired': true,
      });

      expect(entry.eventType.name, 'released');
      expect(entry.isReleased, isTrue);
      expect(entry.exceptionFlag, 'ID check completed');
      expect(entry.exceptionCode, 'officeApprovalRequired');
      expect(entry.officeApprovalRequired, isTrue);
    },
  );

  test(
    'geofence trigger event parsing resolves simulated approach payload',
    () {
      final event = GeofenceTriggerEvent.fromMap({
        'targetId': 'geofence_guardian_andrea_student_maya',
        'schoolId': 'school_1',
        'studentId': 'student_1',
        'guardianId': 'guardian_1',
        'studentName': 'Maya Brooks',
        'pickupZone': 'North Loop',
        'occurredAtEpochMs': DateTime.utc(
          2026,
          3,
          17,
          15,
          12,
        ).millisecondsSinceEpoch,
        'isSimulated': true,
      });

      expect(event.targetId, 'geofence_guardian_andrea_student_maya');
      expect(event.studentName, 'Maya Brooks');
      expect(event.isSimulated, isTrue);
      expect(event.occurredAt.toUtc().hour, 15);
    },
  );

  test('nfc verification event parsing resolves tag and timing', () {
    final event = NfcVerificationEvent.fromMap({
      'schoolId': 'school_1',
      'studentId': 'student_1',
      'guardianId': 'guardian_1',
      'studentName': 'Maya Brooks',
      'tagId': '04AABB11',
      'occurredAtEpochMs': DateTime.utc(
        2026,
        3,
        17,
        15,
        14,
      ).millisecondsSinceEpoch,
      'isSimulated': false,
    });

    expect(event.studentId, 'student_1');
    expect(event.tagId, '04AABB11');
    expect(event.isSimulated, isFalse);
    expect(event.occurredAt.toUtc().minute, 14);
  });

  test('push notification job parsing resolves type and payload', () {
    final job = PushNotificationJob.fromMap({
      'id': 'notification_pickup_1',
      'schoolId': 'school_1',
      'type': 'guardianApproaching',
      'audienceTopic': 'school_school_1_staff',
      'title': 'Maya Brooks is approaching',
      'body': 'Andrea Brooks entered the pickup geofence.',
      'createdAt': '2026-03-17T15:15:00Z',
      'status': 'queued',
      'payload': {'studentId': 'student_1', 'guardianId': 'guardian_1'},
      'attemptCount': 0,
      'lastAttemptAt': null,
      'deliveredAt': null,
      'lastError': null,
    });

    expect(job.type, PushNotificationType.guardianApproaching);
    expect(job.status, PushNotificationStatus.queued);
    expect(job.payload['studentId'], 'student_1');
    expect(job.attemptCount, 0);
  });

  test('release event parsing keeps queue entry linkage', () {
    final event = ReleaseEvent.fromMap({
      'id': 'release_1',
      'schoolId': 'school_1',
      'queueEntryId': 'queue_1',
      'studentId': 'student_1',
      'guardianId': 'guardian_1',
      'staffId': 'staff_1',
      'staffName': 'Ms. Carson',
      'releasedAt': '2026-03-17T15:20:00Z',
      'verificationMethod': 'nfc-verified-release',
      'notes': 'Released after approval.',
    });

    expect(event.queueEntryId, 'queue_1');
    expect(event.verificationMethod, 'nfc-verified-release');
  });

  test('office approval parsing resolves status and audit fields', () {
    final approval = OfficeApprovalRecord.fromMap({
      'id': 'queue_1',
      'schoolId': 'school_1',
      'queueEntryId': 'queue_1',
      'studentId': 'student_1',
      'guardianId': 'guardian_1',
      'studentName': 'Maya Brooks',
      'guardianName': 'Andrea Brooks',
      'status': 'approved',
      'reasonCode': 'unauthorizedGuardian',
      'reasonMessage': 'Office approval required.',
      'requestedAt': '2026-03-17T15:00:00Z',
      'requestedByUid': 'staff_1',
      'requestedByName': 'Ms. Carson',
      'reviewedAt': '2026-03-17T15:05:00Z',
      'reviewedByUid': 'office_1',
      'reviewedByName': 'Front Desk',
      'reviewNotes': 'Approved after ID check.',
      'resolvedAt': null,
      'resolvedByUid': null,
      'resolvedByName': null,
    });

    expect(approval.status, OfficeApprovalStatus.approved);
    expect(approval.reviewedByName, 'Front Desk');
    expect(approval.isApproved, isTrue);
  });
}
