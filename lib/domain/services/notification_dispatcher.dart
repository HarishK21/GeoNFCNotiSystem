import '../models/emergency_notice.dart';
import '../models/pickup_event.dart';
import '../models/pickup_queue_entry.dart';
import '../models/push_notification_job.dart';
import '../models/release_event.dart';
import '../repositories/push_notification_repository.dart';

class NotificationDispatcher {
  const NotificationDispatcher(this._repository);

  final PushNotificationRepository _repository;

  Future<void> queueForPickupEvent({
    required PickupQueueEntry entry,
    required PickupEvent event,
  }) async {
    final job = switch (event.type) {
      PickupEventType.approaching => PushNotificationJob(
        id: 'notification_${event.id}',
        schoolId: event.schoolId,
        type: PushNotificationType.guardianApproaching,
        audienceTopic: _staffTopic(event.schoolId),
        title: '${entry.studentName} is approaching',
        body:
            '${entry.guardianName} entered the pickup geofence for ${entry.pickupZone}.',
        createdAt: event.occurredAt,
        status: PushNotificationStatus.queued,
        payload: {
          'queueEntryId': entry.id,
          'studentId': entry.studentId,
          'guardianId': entry.guardianId,
          'pickupZone': entry.pickupZone,
          'eventId': event.id,
        },
      ),
      PickupEventType.verified => PushNotificationJob(
        id: 'notification_${event.id}',
        schoolId: event.schoolId,
        type: PushNotificationType.guardianVerified,
        audienceTopic: _staffTopic(event.schoolId),
        title: '${entry.studentName} is verified',
        body:
            '${entry.guardianName} completed on-site verification. Release can proceed when other checks pass.',
        createdAt: event.occurredAt,
        status: PushNotificationStatus.queued,
        payload: {
          'queueEntryId': entry.id,
          'studentId': entry.studentId,
          'guardianId': entry.guardianId,
          'pickupZone': entry.pickupZone,
          'eventId': event.id,
        },
      ),
      _ => null,
    };

    if (job == null) {
      return;
    }
    await _repository.enqueueJob(job);
  }

  Future<void> queueForReleaseEvent({
    required PickupQueueEntry entry,
    required ReleaseEvent releaseEvent,
  }) async {
    await _repository.enqueueJob(
      PushNotificationJob(
        id: 'notification_${releaseEvent.id}',
        schoolId: releaseEvent.schoolId,
        type: PushNotificationType.releaseCompleted,
        audienceTopic: _guardianTopic(
          releaseEvent.schoolId,
          releaseEvent.guardianId,
        ),
        title: '${entry.studentName} was released',
        body:
            '${entry.studentName} has been released to ${entry.guardianName}.',
        createdAt: releaseEvent.releasedAt,
        status: PushNotificationStatus.queued,
        payload: {
          'queueEntryId': entry.id,
          'studentId': entry.studentId,
          'guardianId': entry.guardianId,
          'releaseEventId': releaseEvent.id,
        },
      ),
    );
  }

  Future<void> queueForEmergencyNotice(EmergencyNotice notice) async {
    if (!notice.isActive) {
      return;
    }

    await _repository.enqueueJob(
      PushNotificationJob(
        id: 'notification_emergency_${notice.id}',
        schoolId: notice.schoolId,
        type: PushNotificationType.emergencyNotice,
        audienceTopic: _emergencyTopic(notice.schoolId),
        title: notice.title,
        body: notice.body,
        createdAt: notice.sentAt,
        status: PushNotificationStatus.queued,
        payload: {'noticeId': notice.id, 'severity': notice.severity.name},
      ),
    );
  }
}

String _staffTopic(String schoolId) => 'school_${schoolId}_staff';

String _guardianTopic(String schoolId, String guardianId) {
  return 'school_${schoolId}_guardian_$guardianId';
}

String _emergencyTopic(String schoolId) => 'school_${schoolId}_emergency';
