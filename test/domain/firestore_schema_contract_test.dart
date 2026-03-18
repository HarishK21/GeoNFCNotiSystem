import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:geo_tap_guardian/core/models/app_role.dart';
import 'package:geo_tap_guardian/domain/models/audit_trail_entry.dart';
import 'package:geo_tap_guardian/domain/models/emergency_notice.dart';
import 'package:geo_tap_guardian/domain/models/guardian.dart';
import 'package:geo_tap_guardian/domain/models/pickup_event.dart';
import 'package:geo_tap_guardian/domain/models/pickup_permission.dart';
import 'package:geo_tap_guardian/domain/models/pickup_queue_entry.dart';
import 'package:geo_tap_guardian/domain/models/push_notification_job.dart';
import 'package:geo_tap_guardian/domain/models/release_event.dart';
import 'package:geo_tap_guardian/domain/models/school.dart';
import 'package:geo_tap_guardian/domain/models/school_announcement.dart';
import 'package:geo_tap_guardian/domain/models/student.dart';
import 'package:geo_tap_guardian/domain/models/user_profile.dart';

void main() {
  test(
    'firestore schema doc lists the expected collections and lifecycle notes',
    () {
      final schemaDoc = File('docs/firestore_schema.md').readAsStringSync();

      for (final heading in const [
        '`userProfiles/{uid}`',
        '`schools/{schoolId}`',
        '`schools/{schoolId}/students/{studentId}`',
        '`schools/{schoolId}/guardians/{guardianId}`',
        '`schools/{schoolId}/pickupPermissions/{permissionId}`',
        '`schools/{schoolId}/pickupEvents/{pickupEventId}`',
        '`schools/{schoolId}/releaseEvents/{releaseEventId}`',
        '`schools/{schoolId}/announcements/{announcementId}`',
        '`schools/{schoolId}/emergencyNotices/{noticeId}`',
        '`schools/{schoolId}/queue/{queueEntryId}`',
        '`schools/{schoolId}/auditTrail/{auditEntryId}`',
        '`schools/{schoolId}/notificationJobs/{jobId}`',
        'pending -> approaching -> verified -> released',
      ]) {
        expect(schemaDoc, contains(heading));
      }
    },
  );

  test(
    'firestore rules scaffold covers the documented school collections and release guardrails',
    () {
      final rulesFile = File('firestore.rules');
      expect(rulesFile.existsSync(), isTrue);

      final rules = rulesFile.readAsStringSync();
      for (final snippet in const [
        'match /userProfiles/{uid}',
        'match /schools/{schoolId}',
        'match /pickupPermissions/{permissionId}',
        'match /pickupEvents/{pickupEventId}',
        'match /releaseEvents/{releaseEventId}',
        'match /queue/{queueEntryId}',
        'match /auditTrail/{auditEntryId}',
        'match /notificationJobs/{jobId}',
        "request.resource.data.type == 'approaching'",
        "request.resource.data.type in ['verified', 'released']",
        "request.resource.data.verificationMethod == 'nfc-verified-release'",
        "request.resource.data.eventType == 'released'",
        "request.resource.data.officeApprovalRequired == false",
      ]) {
        expect(rules, contains(snippet));
      }
    },
  );

  test('model serialization stays aligned to the documented schema fields', () {
    expect(
      UserProfile(
        uid: 'user_1',
        role: AppRole.staff,
        schoolId: 'school_1',
        displayName: 'Ms. Carson',
        email: 'mcarson@example.com',
        phone: '+1-555-0100',
        linkedGuardianId: 'guardian_1',
      ).toMap().keys,
      containsAll(const [
        'uid',
        'role',
        'schoolId',
        'displayName',
        'email',
        'phone',
        'linkedGuardianId',
      ]),
    );

    expect(
      School(
        id: 'school_1',
        name: 'Springfield Academy',
        timezone: 'America/Toronto',
        pickupZones: const ['North Loop'],
      ).toMap().keys,
      containsAll(const ['id', 'name', 'timezone', 'pickupZones']),
    );

    expect(
      Student(
        id: 'student_1',
        schoolId: 'school_1',
        displayName: 'Maya Brooks',
        gradeLevel: 'Grade 2',
        homeroom: 'Cedar',
        pickupZone: 'North Loop',
        guardianIds: const ['guardian_1'],
      ).toMap().keys,
      containsAll(const [
        'id',
        'schoolId',
        'displayName',
        'gradeLevel',
        'homeroom',
        'pickupZone',
        'guardianIds',
      ]),
    );

    expect(
      Guardian(
        id: 'guardian_1',
        schoolId: 'school_1',
        displayName: 'Andrea Brooks',
        email: 'andrea@example.com',
        phone: '+1-555-0101',
        studentIds: const ['student_1'],
      ).toMap().keys,
      containsAll(const [
        'id',
        'schoolId',
        'displayName',
        'email',
        'phone',
        'studentIds',
      ]),
    );

    expect(
      PickupPermission(
        id: 'permission_1',
        schoolId: 'school_1',
        studentId: 'student_1',
        guardianId: 'guardian_1',
        delegateName: 'Jordan Brooks',
        delegatePhone: '+1-555-0190',
        relationship: 'Grandparent',
        approvedBy: 'Front Office',
        startsAt: DateTime.utc(2026, 3, 17, 15),
        endsAt: DateTime.utc(2026, 3, 17, 16),
        isActive: true,
      ).toMap().keys,
      containsAll(const [
        'id',
        'schoolId',
        'studentId',
        'guardianId',
        'delegateName',
        'delegatePhone',
        'relationship',
        'approvedBy',
        'startsAt',
        'endsAt',
        'isActive',
      ]),
    );

    expect(
      PickupEvent(
        id: 'pickup_1',
        schoolId: 'school_1',
        studentId: 'student_1',
        guardianId: 'guardian_1',
        type: PickupEventType.approaching,
        source: PickupEventSource.geofence,
        pickupZone: 'North Loop',
        occurredAt: DateTime.utc(2026, 3, 17, 15, 5),
        actorName: 'Android geofence',
        notes: 'Guardian entered geofence.',
      ).toMap().keys,
      containsAll(const [
        'id',
        'schoolId',
        'studentId',
        'guardianId',
        'type',
        'source',
        'pickupZone',
        'occurredAt',
        'actorName',
        'notes',
      ]),
    );

    expect(
      ReleaseEvent(
        id: 'release_1',
        schoolId: 'school_1',
        studentId: 'student_1',
        guardianId: 'guardian_1',
        staffId: 'staff_1',
        staffName: 'Ms. Carson',
        releasedAt: DateTime.utc(2026, 3, 17, 15, 10),
        verificationMethod: 'app-confirmed',
        notes: 'Released after NFC verification.',
      ).toMap().keys,
      containsAll(const [
        'id',
        'schoolId',
        'studentId',
        'guardianId',
        'staffId',
        'staffName',
        'releasedAt',
        'verificationMethod',
        'notes',
      ]),
    );

    expect(
      SchoolAnnouncement(
        id: 'announcement_1',
        schoolId: 'school_1',
        title: 'Dismissal update',
        body: 'Pickup moves to North Loop.',
        audience: 'All families',
        sentAt: DateTime.utc(2026, 3, 17, 14),
        requiresAcknowledgement: false,
      ).toMap().keys,
      containsAll(const [
        'id',
        'schoolId',
        'title',
        'body',
        'audience',
        'sentAt',
        'requiresAcknowledgement',
      ]),
    );

    expect(
      EmergencyNotice(
        id: 'notice_1',
        schoolId: 'school_1',
        title: 'Hold releases',
        body: 'Pause all release actions until all-clear.',
        severity: EmergencySeverity.warning,
        sentAt: DateTime.utc(2026, 3, 17, 14, 15),
        isActive: true,
      ).toMap().keys,
      containsAll(const [
        'id',
        'schoolId',
        'title',
        'body',
        'severity',
        'sentAt',
        'isActive',
      ]),
    );

    expect(
      PickupQueueEntry(
        id: 'queue_1',
        schoolId: 'school_1',
        studentId: 'student_1',
        studentName: 'Maya Brooks',
        guardianId: 'guardian_1',
        guardianName: 'Andrea Brooks',
        homeroom: 'Grade 2 - Cedar',
        pickupZone: 'North Loop',
        etaLabel: 'Approaching',
        eventType: PickupEventType.approaching,
        isNfcVerified: false,
        exceptionFlag: 'ID check required',
        exceptionCode: 'officeApprovalRequired',
        officeApprovalRequired: true,
      ).toMap().keys,
      containsAll(const [
        'id',
        'schoolId',
        'studentId',
        'studentName',
        'guardianId',
        'guardianName',
        'homeroom',
        'pickupZone',
        'etaLabel',
        'eventType',
        'isNfcVerified',
        'exceptionFlag',
        'exceptionCode',
        'officeApprovalRequired',
      ]),
    );

    expect(
      AuditTrailEntry(
        id: 'audit_1',
        schoolId: 'school_1',
        studentName: 'Maya Brooks',
        action: 'verified',
        actorName: 'Debug NFC simulator',
        occurredAt: DateTime.utc(2026, 3, 17, 15, 6),
        notes: 'Queue state changed after NFC scan.',
      ).toMap().keys,
      containsAll(const [
        'id',
        'schoolId',
        'studentName',
        'action',
        'actorName',
        'occurredAt',
        'notes',
      ]),
    );

    expect(
      PushNotificationJob(
        id: 'notification_1',
        schoolId: 'school_1',
        type: PushNotificationType.releaseCompleted,
        audienceTopic: 'school_school_1_guardian_guardian_1',
        title: 'Maya Brooks was released',
        body: 'Maya Brooks has been released.',
        createdAt: DateTime.utc(2026, 3, 17, 15, 12),
        status: PushNotificationStatus.queued,
        payload: const {'studentId': 'student_1'},
      ).toMap().keys,
      containsAll(const [
        'id',
        'schoolId',
        'type',
        'audienceTopic',
        'title',
        'body',
        'createdAt',
        'status',
        'payload',
      ]),
    );
  });
}
