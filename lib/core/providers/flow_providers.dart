import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/emergency_notice.dart';
import '../../domain/models/pickup_event.dart';
import '../../domain/models/pickup_permission.dart';
import '../../domain/models/pickup_queue_entry.dart';
import '../../domain/models/school.dart';
import '../../domain/models/school_announcement.dart';
import '../../domain/models/user_profile.dart';
import '../models/app_role.dart';
import '../models/announcement.dart';
import '../models/audit_event.dart';
import '../models/guardian_delegate.dart';
import '../models/pickup_request.dart';
import '../models/presence_state.dart';
import 'repository_providers.dart';

final currentUserIdStreamProvider = StreamProvider<String?>((ref) {
  return ref.watch(authRepositoryProvider).watchCurrentUserId();
});

final currentUserProfileStreamProvider = StreamProvider<UserProfile?>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  final repository = ref.watch(userProfileRepositoryProvider);
  final uid =
      ref.watch(currentUserIdStreamProvider).asData?.value ??
      authRepository.getCurrentUserId();

  if (uid == null) {
    return Stream<UserProfile?>.value(null);
  }

  return repository.watchProfile(uid);
});

final currentUserProfileProvider = Provider<UserProfile?>((ref) {
  return ref.watch(currentUserProfileStreamProvider).asData?.value;
});

final resolvedRoleProvider = Provider<AppRole?>((ref) {
  return ref.watch(currentUserProfileProvider)?.role;
});

final currentSchoolIdProvider = Provider<String>((ref) {
  return ref.watch(currentUserProfileProvider)?.schoolId ??
      ref.watch(mockDataStoreProvider).school.id;
});

final activeSchoolProvider = FutureProvider<School?>((ref) {
  return ref
      .watch(schoolRepositoryProvider)
      .fetchSchool(ref.watch(currentSchoolIdProvider));
});

final queueEntriesStreamProvider = StreamProvider<List<PickupQueueEntry>>((
  ref,
) {
  return ref
      .watch(queueRepositoryProvider)
      .watchQueue(ref.watch(currentSchoolIdProvider));
});

final pickupPermissionsStreamProvider = StreamProvider<List<PickupPermission>>((
  ref,
) {
  return ref
      .watch(pickupPermissionRepositoryProvider)
      .watchPermissions(ref.watch(currentSchoolIdProvider));
});

final schoolAnnouncementsStreamProvider =
    StreamProvider<List<SchoolAnnouncement>>((ref) {
      return ref
          .watch(noticeRepositoryProvider)
          .watchAnnouncements(ref.watch(currentSchoolIdProvider));
    });

final emergencyNoticesStreamProvider = StreamProvider<List<EmergencyNotice>>((
  ref,
) {
  return ref
      .watch(noticeRepositoryProvider)
      .watchEmergencyNotices(ref.watch(currentSchoolIdProvider));
});

final auditTrailStreamProvider = StreamProvider<List<AuditEvent>>((ref) {
  return ref
      .watch(auditRepositoryProvider)
      .watchAuditTrail(ref.watch(currentSchoolIdProvider))
      .map(
        (entries) => entries
            .map(
              (entry) => AuditEvent(
                studentName: entry.studentName,
                action: entry.action,
                actorName: entry.actorName,
                timestampLabel: _formatTimestamp(entry.occurredAt),
                notes: entry.notes,
              ),
            )
            .toList(growable: false),
      );
});

final pickupQueueProvider = Provider<List<PickupRequest>>((ref) {
  final entries =
      ref.watch(queueEntriesStreamProvider).asData?.value ?? const [];

  return entries
      .map(
        (entry) => PickupRequest(
          studentName: entry.studentName,
          guardianName: entry.guardianName,
          homeroom: entry.homeroom,
          pickupZone: entry.pickupZone,
          etaLabel: entry.etaLabel,
          presenceState: _toPresenceState(entry.eventType),
          isNfcVerified: entry.isNfcVerified,
        ),
      )
      .toList(growable: false);
});

final announcementsProvider = Provider<List<Announcement>>((ref) {
  final announcements =
      ref.watch(schoolAnnouncementsStreamProvider).asData?.value ?? const [];
  final emergencyNotices =
      ref.watch(emergencyNoticesStreamProvider).asData?.value ?? const [];

  final items = <({DateTime timestamp, Announcement model})>[
    ...emergencyNotices.map(
      (notice) => (
        timestamp: notice.sentAt,
        model: Announcement(
          title: notice.title,
          body: notice.body,
          sentAtLabel: _formatTimestamp(notice.sentAt),
          audience: 'Emergency Notice',
          requiresAcknowledgement: notice.isActive,
        ),
      ),
    ),
    ...announcements.map(
      (announcement) => (
        timestamp: announcement.sentAt,
        model: Announcement(
          title: announcement.title,
          body: announcement.body,
          sentAtLabel: _formatTimestamp(announcement.sentAt),
          audience: announcement.audience,
          requiresAcknowledgement: announcement.requiresAcknowledgement,
        ),
      ),
    ),
  ];

  items.sort((left, right) => right.timestamp.compareTo(left.timestamp));
  return items.map((item) => item.model).toList(growable: false);
});

final guardianDelegatesProvider = Provider<List<GuardianDelegate>>((ref) {
  final permissions =
      ref.watch(pickupPermissionsStreamProvider).asData?.value ?? const [];

  return permissions
      .map(
        (permission) => GuardianDelegate(
          name: permission.delegateName,
          relationship: permission.relationship,
          windowLabel:
              '${_formatWindow(permission.startsAt)} to ${_formatWindow(permission.endsAt)}',
          isActive: permission.isActive,
        ),
      )
      .toList(growable: false);
});

final auditTrailProvider = Provider<List<AuditEvent>>((ref) {
  return ref.watch(auditTrailStreamProvider).asData?.value ?? const [];
});

final releaseReadyQueueProvider = Provider<List<PickupRequest>>((ref) {
  return ref
      .watch(pickupQueueProvider)
      .where((request) => request.canRelease)
      .toList(growable: false);
});

final pendingVerificationQueueProvider = Provider<List<PickupRequest>>((ref) {
  return ref
      .watch(pickupQueueProvider)
      .where((request) => !request.canRelease)
      .toList(growable: false);
});

final activeDelegatesProvider = Provider<List<GuardianDelegate>>((ref) {
  return ref
      .watch(guardianDelegatesProvider)
      .where((delegate) => delegate.isActive)
      .toList(growable: false);
});

PresenceState _toPresenceState(PickupEventType eventType) {
  return switch (eventType) {
    PickupEventType.queued => PresenceState.queued,
    PickupEventType.approaching => PresenceState.approaching,
    PickupEventType.verified => PresenceState.verified,
  };
}

String _formatTimestamp(DateTime value) {
  final hour = value.hour == 0
      ? 12
      : (value.hour > 12 ? value.hour - 12 : value.hour);
  final minute = value.minute.toString().padLeft(2, '0');
  final suffix = value.hour >= 12 ? 'PM' : 'AM';
  return '${_monthName(value.month)} ${value.day}, ${value.year} • $hour:$minute $suffix';
}

String _formatWindow(DateTime value) {
  final hour = value.hour == 0
      ? 12
      : (value.hour > 12 ? value.hour - 12 : value.hour);
  final minute = value.minute.toString().padLeft(2, '0');
  final suffix = value.hour >= 12 ? 'PM' : 'AM';
  return '${_monthShort(value.month)} ${value.day}, $hour:$minute $suffix';
}

String _monthName(int month) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return months[month - 1];
}

String _monthShort(int month) => _monthName(month);
