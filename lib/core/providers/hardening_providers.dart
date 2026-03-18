import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/app_role.dart';
import '../../domain/models/audit_trail_entry.dart';
import '../../domain/models/pickup_event.dart';
import '../../domain/models/pickup_permission.dart';
import '../../domain/models/pickup_queue_entry.dart';
import '../../domain/models/release_event.dart';
import '../../domain/models/student.dart';
import '../../domain/services/notification_dispatcher.dart';
import '../../domain/services/pickup_authorization_service.dart';
import '../../domain/services/queue_reconciliation_service.dart';
import 'flow_providers.dart';
import 'repository_providers.dart';

final pickupAuthorizationServiceProvider = Provider<PickupAuthorizationService>(
  (ref) {
    return const PickupAuthorizationService();
  },
);

final queueReconciliationServiceProvider = Provider<QueueReconciliationService>(
  (ref) {
    return QueueReconciliationService(
      ref.watch(pickupAuthorizationServiceProvider),
    );
  },
);

final notificationDispatcherProvider = Provider<NotificationDispatcher>((ref) {
  return NotificationDispatcher(ref.watch(pushNotificationRepositoryProvider));
});

final workflowHardeningBootstrapProvider = Provider<void>((ref) {
  final environment = ref.watch(appEnvironmentProvider);
  final authGate = ref.watch(authGateStateProvider);
  final shouldRun = environment.isMockMode || authGate.role == AppRole.staff;
  if (!shouldRun) {
    return;
  }

  var running = false;
  var rerunRequested = false;

  Future<void> scheduleReconciliation() async {
    if (running) {
      rerunRequested = true;
      return;
    }

    running = true;
    try {
      do {
        rerunRequested = false;
        await _runQueueReconciliation(ref);
      } while (rerunRequested);
    } finally {
      running = false;
    }
  }

  unawaited(scheduleReconciliation());
  unawaited(_dispatchEmergencyNotifications(ref));

  ref.listen(queueEntriesStreamProvider, (previous, next) {
    unawaited(scheduleReconciliation());
  });
  ref.listen(pickupPermissionsStreamProvider, (previous, next) {
    unawaited(scheduleReconciliation());
  });
  ref.listen(pickupEventsStreamProvider, (previous, next) {
    unawaited(scheduleReconciliation());
  });
  ref.listen(releaseEventsStreamProvider, (previous, next) {
    unawaited(scheduleReconciliation());
  });
  ref.listen(studentsFutureProvider, (previous, next) {
    unawaited(scheduleReconciliation());
  });
  ref.listen(emergencyNoticesStreamProvider, (previous, next) {
    unawaited(_dispatchEmergencyNotifications(ref));
  });
});

Future<void> _runQueueReconciliation(Ref ref) async {
  final schoolId = ref.read(currentSchoolIdProvider);
  final List<PickupQueueEntry> queueEntries =
      ref.read(queueEntriesStreamProvider).asData?.value ??
      await ref.read(queueRepositoryProvider).watchQueue(schoolId).first;
  final List<Student> students =
      ref.read(studentsFutureProvider).asData?.value ??
      await ref.read(studentRepositoryProvider).fetchStudents(schoolId);
  final List<PickupPermission> permissions =
      ref.read(pickupPermissionsStreamProvider).asData?.value ??
      await ref
          .read(pickupPermissionRepositoryProvider)
          .watchPermissions(schoolId)
          .first;
  final List<PickupEvent> pickupEvents =
      ref.read(pickupEventsStreamProvider).asData?.value ??
      await ref
          .read(pickupEventRepositoryProvider)
          .watchPickupEvents(schoolId)
          .first;
  final List<ReleaseEvent> releaseEvents =
      ref.read(releaseEventsStreamProvider).asData?.value ??
      await ref
          .read(releaseEventRepositoryProvider)
          .watchReleaseEvents(schoolId)
          .first;

  final changes = ref
      .read(queueReconciliationServiceProvider)
      .reconcileSchoolQueue(
        queueEntries: queueEntries,
        students: students,
        permissions: permissions,
        pickupEvents: pickupEvents,
        releaseEvents: releaseEvents,
        at: DateTime.now(),
      );

  for (final change in changes) {
    await ref.read(queueRepositoryProvider).saveQueueEntry(change.updatedEntry);
    await ref
        .read(auditRepositoryProvider)
        .appendAuditEntry(
          AuditTrailEntry(
            id: 'audit_reconcile_${change.updatedEntry.id}_${DateTime.now().microsecondsSinceEpoch}',
            schoolId: change.updatedEntry.schoolId,
            studentName: change.updatedEntry.studentName,
            action: 'Queue reconciled',
            actorName: 'GeoTap Guardian reconciliation',
            occurredAt: DateTime.now(),
            notes: change.notes,
          ),
        );
  }
}

Future<void> _dispatchEmergencyNotifications(Ref ref) async {
  final notices = ref.read(emergencyNoticesStreamProvider).asData?.value;
  if (notices == null) {
    return;
  }

  final dispatcher = ref.read(notificationDispatcherProvider);
  for (final notice in notices.where((item) => item.isActive)) {
    await dispatcher.queueForEmergencyNotice(notice);
  }
}
