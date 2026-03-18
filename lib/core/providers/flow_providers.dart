import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/emergency_notice.dart';
import '../../domain/models/guardian.dart';
import '../../domain/models/office_approval_record.dart';
import '../../domain/models/pickup_event.dart';
import '../../domain/models/pickup_permission.dart';
import '../../domain/models/pickup_queue_entry.dart';
import '../../domain/models/release_event.dart';
import '../../domain/models/school.dart';
import '../../domain/models/school_announcement.dart';
import '../../domain/models/student.dart';
import '../../domain/models/user_profile.dart';
import '../models/announcement.dart';
import '../models/app_role.dart';
import '../models/audit_event.dart';
import '../models/auth_gate_state.dart';
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

final authGateStateProvider = Provider<AuthGateState>((ref) {
  final authState = ref.watch(currentUserIdStreamProvider);
  if (authState.isLoading) {
    return const AuthGateState.loading();
  }

  final uid = authState.asData?.value;
  if (uid == null) {
    return const AuthGateState.signedOut();
  }

  final profileState = ref.watch(currentUserProfileStreamProvider);
  if (profileState.isLoading) {
    return const AuthGateState.loading();
  }

  final profile = profileState.asData?.value;
  if (profile == null) {
    return const AuthGateState.profileUnavailable();
  }

  return AuthGateState.authenticated(profile);
});

final resolvedRoleProvider = Provider<AppRole?>((ref) {
  return ref.watch(authGateStateProvider).role;
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

final studentsFutureProvider = FutureProvider<List<Student>>((ref) {
  return ref
      .watch(studentRepositoryProvider)
      .fetchStudents(ref.watch(currentSchoolIdProvider));
});

final guardiansFutureProvider = FutureProvider<List<Guardian>>((ref) {
  return ref
      .watch(guardianRepositoryProvider)
      .fetchGuardians(ref.watch(currentSchoolIdProvider));
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

final pickupEventsStreamProvider = StreamProvider<List<PickupEvent>>((ref) {
  return ref
      .watch(pickupEventRepositoryProvider)
      .watchPickupEvents(ref.watch(currentSchoolIdProvider));
});

final releaseEventsStreamProvider = StreamProvider<List<ReleaseEvent>>((ref) {
  return ref
      .watch(releaseEventRepositoryProvider)
      .watchReleaseEvents(ref.watch(currentSchoolIdProvider));
});

final officeApprovalsStreamProvider =
    StreamProvider<List<OfficeApprovalRecord>>((ref) {
      return ref
          .watch(officeApprovalRepositoryProvider)
          .watchApprovals(ref.watch(currentSchoolIdProvider));
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

final currentGuardianProvider = Provider<Guardian?>((ref) {
  final profile = ref.watch(currentUserProfileProvider);
  final guardians =
      ref.watch(guardiansFutureProvider).asData?.value ?? const [];

  if (profile == null || profile.role != AppRole.parent) {
    return null;
  }

  final byLinkedId = guardians
      .where((guardian) => guardian.id == profile.linkedGuardianId)
      .firstOrNull;
  if (byLinkedId != null) {
    return byLinkedId;
  }

  return guardians
      .where(
        (guardian) =>
            guardian.email == profile.email ||
            guardian.displayName == profile.displayName,
      )
      .firstOrNull;
});

final familyStudentsProvider = Provider<List<Student>>((ref) {
  final guardian = ref.watch(currentGuardianProvider);
  final students = ref.watch(studentsFutureProvider).asData?.value ?? const [];
  if (guardian == null) {
    return const [];
  }

  return students
      .where((student) => guardian.studentIds.contains(student.id))
      .toList(growable: false);
});

final familyGuardiansProvider = Provider<List<Guardian>>((ref) {
  final students = ref.watch(familyStudentsProvider);
  final guardians =
      ref.watch(guardiansFutureProvider).asData?.value ?? const [];
  final guardianIds = students.expand((student) => student.guardianIds).toSet();

  return guardians
      .where((guardian) => guardianIds.contains(guardian.id))
      .toList(growable: false);
});

final familyQueueEntriesProvider = Provider<List<PickupQueueEntry>>((ref) {
  final studentIds = ref
      .watch(familyStudentsProvider)
      .map((item) => item.id)
      .toSet();
  final queueEntries =
      ref.watch(queueEntriesStreamProvider).asData?.value ?? const [];
  return queueEntries
      .where((entry) => studentIds.contains(entry.studentId))
      .toList(growable: false);
});

final liveQueueEntriesProvider = Provider<List<PickupQueueEntry>>((ref) {
  final queueEntries =
      ref.watch(queueEntriesStreamProvider).asData?.value ?? const [];
  return queueEntries
      .where((entry) => !entry.isReleased)
      .toList(growable: false);
});

final flaggedQueueEntriesProvider = Provider<List<PickupQueueEntry>>((ref) {
  return ref
      .watch(liveQueueEntriesProvider)
      .where((entry) => entry.hasException)
      .toList(growable: false);
});

final pendingOfficeApprovalsProvider = Provider<List<OfficeApprovalRecord>>((
  ref,
) {
  final approvals =
      ref.watch(officeApprovalsStreamProvider).asData?.value ?? const [];
  return approvals.where((record) => record.isPending).toList(growable: false);
});

final officeApprovalByQueueEntryProvider =
    Provider.family<OfficeApprovalRecord?, String>((ref, queueEntryId) {
      final approvals =
          ref.watch(officeApprovalsStreamProvider).asData?.value ?? const [];
      return approvals
          .where((record) => record.queueEntryId == queueEntryId)
          .firstOrNull;
    });

final familyHistoryProvider = Provider<List<AuditEvent>>((ref) {
  final studentNames = ref
      .watch(familyStudentsProvider)
      .map((student) => student.displayName)
      .toSet();
  final pickupEvents =
      ref.watch(pickupEventsStreamProvider).asData?.value ?? const [];
  final releaseEvents =
      ref.watch(releaseEventsStreamProvider).asData?.value ?? const [];
  final students = ref.watch(studentsFutureProvider).asData?.value ?? const [];

  final studentById = {
    for (final student in students) student.id: student.displayName,
  };

  final history = <({DateTime time, AuditEvent event})>[
    ...pickupEvents
        .where((event) {
          final name = studentById[event.studentId];
          return name != null && studentNames.contains(name);
        })
        .map(
          (event) => (
            time: event.occurredAt,
            event: AuditEvent(
              studentName: studentById[event.studentId] ?? event.studentId,
              action: event.type.name,
              actorName: event.actorName ?? 'System',
              timestampLabel: formatTimestamp(event.occurredAt),
              notes: event.notes ?? 'Pickup event recorded.',
            ),
          ),
        ),
    ...releaseEvents
        .where((event) {
          final name = studentById[event.studentId];
          return name != null && studentNames.contains(name);
        })
        .map(
          (event) => (
            time: event.releasedAt,
            event: AuditEvent(
              studentName: studentById[event.studentId] ?? event.studentId,
              action: 'released',
              actorName: event.staffName,
              timestampLabel: formatTimestamp(event.releasedAt),
              notes: event.notes ?? 'Student released.',
            ),
          ),
        ),
  ];

  history.sort((left, right) => right.time.compareTo(left.time));
  return history.map((item) => item.event).toList(growable: false);
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
                timestampLabel: formatTimestamp(entry.occurredAt),
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
          queueEntryId: entry.id,
          studentId: entry.studentId,
          guardianId: entry.guardianId,
          studentName: entry.studentName,
          guardianName: entry.guardianName,
          homeroom: entry.homeroom,
          pickupZone: entry.pickupZone,
          etaLabel: entry.etaLabel,
          presenceState: toPresenceState(entry.eventType),
          isNfcVerified: entry.isNfcVerified,
          exceptionFlag: entry.exceptionFlag,
        ),
      )
      .toList(growable: false);
});

final familyPickupQueueProvider = Provider<List<PickupRequest>>((ref) {
  final entries = ref.watch(familyQueueEntriesProvider);
  return entries
      .map(
        (entry) => PickupRequest(
          queueEntryId: entry.id,
          studentId: entry.studentId,
          guardianId: entry.guardianId,
          studentName: entry.studentName,
          guardianName: entry.guardianName,
          homeroom: entry.homeroom,
          pickupZone: entry.pickupZone,
          etaLabel: entry.etaLabel,
          presenceState: toPresenceState(entry.eventType),
          isNfcVerified: entry.isNfcVerified,
          exceptionFlag: entry.exceptionFlag,
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
          sentAtLabel: formatTimestamp(notice.sentAt),
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
          sentAtLabel: formatTimestamp(announcement.sentAt),
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
              '${formatWindow(permission.startsAt)} to ${formatWindow(permission.endsAt)}',
          isActive: permission.isActive,
        ),
      )
      .toList(growable: false);
});

final familyDelegatesProvider = Provider<List<GuardianDelegate>>((ref) {
  final guardian = ref.watch(currentGuardianProvider);
  if (guardian == null) {
    return const [];
  }

  final permissions =
      ref.watch(pickupPermissionsStreamProvider).asData?.value ?? const [];

  return permissions
      .where((permission) => permission.guardianId == guardian.id)
      .map(
        (permission) => GuardianDelegate(
          name: permission.delegateName,
          relationship: permission.relationship,
          windowLabel:
              '${formatWindow(permission.startsAt)} to ${formatWindow(permission.endsAt)}',
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
      .where((request) => request.canVerify)
      .toList(growable: false);
});

final activeDelegatesProvider = Provider<List<GuardianDelegate>>((ref) {
  return ref
      .watch(guardianDelegatesProvider)
      .where((delegate) => delegate.isActive)
      .toList(growable: false);
});

final authSupportsCredentialSignInProvider = Provider<bool>((ref) {
  return ref.watch(authRepositoryProvider).supportsCredentialSignIn;
});

final authSupportsDemoSignInProvider = Provider<bool>((ref) {
  return ref.watch(authRepositoryProvider).supportsDemoSignIn;
});

PresenceState toPresenceState(PickupEventType eventType) {
  return switch (eventType) {
    PickupEventType.pending => PresenceState.pending,
    PickupEventType.approaching => PresenceState.approaching,
    PickupEventType.verified => PresenceState.verified,
    PickupEventType.released => PresenceState.released,
  };
}

String formatTimestamp(DateTime value) {
  final hour = value.hour == 0
      ? 12
      : (value.hour > 12 ? value.hour - 12 : value.hour);
  final minute = value.minute.toString().padLeft(2, '0');
  final suffix = value.hour >= 12 ? 'PM' : 'AM';
  return '${_monthName(value.month)} ${value.day}, ${value.year} • $hour:$minute $suffix';
}

String formatWindow(DateTime value) {
  final hour = value.hour == 0
      ? 12
      : (value.hour > 12 ? value.hour - 12 : value.hour);
  final minute = value.minute.toString().padLeft(2, '0');
  final suffix = value.hour >= 12 ? 'PM' : 'AM';
  return '${_monthName(value.month)} ${value.day}, $hour:$minute $suffix';
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

extension _FirstOrNullExtension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
