import 'package:flutter_test/flutter_test.dart';

import 'package:geo_tap_guardian/domain/models/emergency_notice.dart';
import 'package:geo_tap_guardian/domain/models/pickup_event.dart';
import 'package:geo_tap_guardian/domain/models/pickup_queue_entry.dart';
import 'package:geo_tap_guardian/domain/models/push_notification_job.dart';
import 'package:geo_tap_guardian/domain/models/release_event.dart';
import 'package:geo_tap_guardian/domain/repositories/push_notification_repository.dart';
import 'package:geo_tap_guardian/domain/services/notification_dispatcher.dart';

void main() {
  test(
    'pickup notification jobs include queue linkage for backend workers',
    () async {
      final repository = _FakePushNotificationRepository();
      final dispatcher = NotificationDispatcher(repository);
      final entry = _entry();
      final event = PickupEvent(
        id: 'pickup_1',
        schoolId: entry.schoolId,
        studentId: entry.studentId,
        guardianId: entry.guardianId,
        type: PickupEventType.approaching,
        source: PickupEventSource.geofence,
        pickupZone: entry.pickupZone,
        occurredAt: DateTime.utc(2026, 3, 17, 15, 0),
      );

      await dispatcher.queueForPickupEvent(entry: entry, event: event);

      expect(repository.jobs, hasLength(1));
      expect(
        repository.jobs.single.type,
        PushNotificationType.guardianApproaching,
      );
      expect(repository.jobs.single.payload['queueEntryId'], entry.id);
      expect(repository.jobs.single.attemptCount, 0);
    },
  );

  test(
    'release notification jobs keep the queue entry id for delivery auditing',
    () async {
      final repository = _FakePushNotificationRepository();
      final dispatcher = NotificationDispatcher(repository);
      final entry = _entry();
      final release = ReleaseEvent(
        id: 'release_1',
        schoolId: entry.schoolId,
        queueEntryId: entry.id,
        studentId: entry.studentId,
        guardianId: entry.guardianId,
        staffId: 'staff_1',
        staffName: 'Ms. Carson',
        releasedAt: DateTime.utc(2026, 3, 17, 15, 5),
        verificationMethod: 'nfc-verified-release',
      );

      await dispatcher.queueForReleaseEvent(
        entry: entry,
        releaseEvent: release,
      );

      expect(repository.jobs, hasLength(1));
      expect(
        repository.jobs.single.type,
        PushNotificationType.releaseCompleted,
      );
      expect(repository.jobs.single.payload['queueEntryId'], entry.id);
    },
  );

  test('emergency notices are queued for backend delivery', () async {
    final repository = _FakePushNotificationRepository();
    final dispatcher = NotificationDispatcher(repository);

    await dispatcher.queueForEmergencyNotice(
      EmergencyNotice(
        id: 'notice_1',
        schoolId: 'school_1',
        title: 'Hold releases',
        body: 'Pause until all-clear.',
        severity: EmergencySeverity.critical,
        sentAt: DateTime.utc(2026, 3, 17, 15, 10),
        isActive: true,
      ),
    );

    expect(repository.jobs.single.type, PushNotificationType.emergencyNotice);
    expect(repository.jobs.single.status, PushNotificationStatus.queued);
  });
}

class _FakePushNotificationRepository implements PushNotificationRepository {
  final jobs = <PushNotificationJob>[];

  @override
  Future<void> enqueueJob(PushNotificationJob job) async {
    jobs.add(job);
  }

  @override
  Stream<List<PushNotificationJob>> watchJobs(String schoolId) async* {
    yield jobs.where((job) => job.schoolId == schoolId).toList(growable: false);
  }
}

PickupQueueEntry _entry() {
  return const PickupQueueEntry(
    id: 'queue_1',
    schoolId: 'school_1',
    studentId: 'student_1',
    studentName: 'Maya Brooks',
    guardianId: 'guardian_1',
    guardianName: 'Andrea Brooks',
    homeroom: 'Grade 2 - Cedar',
    pickupZone: 'North Loop',
    etaLabel: 'Ready',
    eventType: PickupEventType.verified,
    isNfcVerified: true,
  );
}
