import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/app_role.dart';
import '../../domain/models/audit_trail_entry.dart';
import '../../domain/models/pickup_event.dart';
import '../../domain/models/pickup_exception_code.dart';
import '../../domain/models/pickup_permission.dart';
import '../../domain/models/pickup_queue_entry.dart';
import '../../domain/models/pickup_workflow_exception.dart';
import '../../domain/models/release_event.dart';
import '../../domain/models/student.dart';
import '../../domain/services/queue_state_machine.dart';
import 'flow_providers.dart';
import 'hardening_providers.dart';
import 'repository_providers.dart';

final queueStateMachineProvider = Provider<QueueStateMachine>((ref) {
  return const QueueStateMachine();
});

final authActionControllerProvider =
    AsyncNotifierProvider<AuthActionController, void>(AuthActionController.new);

class AuthActionController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> signInAsDemoRole(AppRole role) async {
    final repository = ref.read(authRepositoryProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => repository.signInAsDemoRole(role));
  }

  Future<void> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    final repository = ref.read(authRepositoryProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () =>
          repository.signInWithEmailPassword(email: email, password: password),
    );
  }

  Future<void> signOut() async {
    final repository = ref.read(authRepositoryProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(repository.signOut);
  }
}

final workflowActionControllerProvider =
    AsyncNotifierProvider<WorkflowActionController, void>(
      WorkflowActionController.new,
    );

class WorkflowActionController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> markApproaching(PickupQueueEntry entry) async {
    await _transition(
      entry,
      PickupEventType.approaching,
      source: PickupEventSource.manual,
    );
  }

  Future<void> verifyPickup(
    PickupQueueEntry entry, {
    PickupEventSource source = PickupEventSource.nfc,
    String? actorName,
    String? notes,
  }) async {
    final role = ref.read(resolvedRoleProvider);
    if (role != AppRole.staff) {
      const message = 'Only staff users can verify on-site pickup status.';
      await _recordBlockedTransition(
        entry,
        action: 'Verification blocked',
        notes: message,
        actorName: actorName,
      );
      throw const PickupWorkflowException(
        code: PickupWorkflowErrorCode.unauthorizedRole,
        message: message,
      );
    }

    await _transition(
      entry,
      PickupEventType.verified,
      source: source,
      actorName: actorName,
      notes: notes,
    );
  }

  Future<void> releaseStudent(
    PickupQueueEntry entry, {
    PickupEventSource source = PickupEventSource.manual,
    String? actorName,
    String? notes,
  }) async {
    await _transition(
      entry,
      PickupEventType.released,
      source: source,
      actorName: actorName,
      notes: notes,
    );
  }

  Future<void> markApproachingFromDevice(
    PickupQueueEntry entry, {
    required PickupEventSource source,
    required String actorName,
    required String notes,
  }) async {
    await _transition(
      entry,
      PickupEventType.approaching,
      source: source,
      actorName: actorName,
      notes: notes,
    );
  }

  Future<void> flagException(PickupQueueEntry entry, String flag) async {
    final updatedEntry = entry.copyWith(
      exceptionFlag: flag,
      exceptionCode: PickupExceptionCode.manualFlag.name,
      officeApprovalRequired: false,
    );
    await _saveQueueAndAudit(
      updatedEntry: updatedEntry,
      auditAction: 'Exception flagged',
      auditNotes: flag,
    );
  }

  Future<void> clearException(PickupQueueEntry entry) async {
    final updatedEntry = entry.copyWith(clearExceptionFlag: true);
    await _saveQueueAndAudit(
      updatedEntry: updatedEntry,
      auditAction: 'Exception cleared',
      auditNotes: 'Exception cleared for ${entry.studentName}.',
    );
  }

  Future<void> resetQueueState(
    PickupQueueEntry entry, {
    String actorName = 'Debug controls',
    String notes = 'Queue state reset to pending.',
  }) async {
    final updatedEntry = entry.copyWith(
      eventType: PickupEventType.pending,
      isNfcVerified: false,
      etaLabel: 'Pending',
      clearExceptionFlag: true,
    );
    final pickupEvent = PickupEvent(
      id: _generateId('pickup'),
      schoolId: updatedEntry.schoolId,
      studentId: updatedEntry.studentId,
      guardianId: updatedEntry.guardianId,
      type: PickupEventType.pending,
      source: PickupEventSource.manual,
      pickupZone: updatedEntry.pickupZone,
      occurredAt: DateTime.now(),
      actorName: actorName,
      notes: notes,
    );

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(queueRepositoryProvider).saveQueueEntry(updatedEntry);
      await ref.read(pickupEventRepositoryProvider).logPickupEvent(pickupEvent);
      await ref
          .read(auditRepositoryProvider)
          .appendAuditEntry(
            AuditTrailEntry(
              id: _generateId('audit'),
              schoolId: updatedEntry.schoolId,
              studentName: updatedEntry.studentName,
              action: 'Reset to pending',
              actorName: actorName,
              occurredAt: DateTime.now(),
              notes: notes,
            ),
          );
    });
  }

  Future<void> createTemporaryPermission({
    required String studentId,
    required String delegateName,
    required String delegatePhone,
    required String relationship,
    required DateTime startsAt,
    required DateTime endsAt,
  }) async {
    final profile = ref.read(currentUserProfileProvider);
    final role = ref.read(resolvedRoleProvider);
    if (profile == null) {
      throw StateError('No signed-in profile is available.');
    }
    if (role != AppRole.parent) {
      throw const PickupWorkflowException(
        code: PickupWorkflowErrorCode.unauthorizedRole,
        message: 'Only parent users can create temporary pickup permissions.',
      );
    }
    final guardianId =
        profile.linkedGuardianId ?? ref.read(currentGuardianProvider)?.id;
    if (guardianId == null || guardianId.isEmpty) {
      throw StateError('No guardian record is linked to this signed-in user.');
    }
    final studentName = _studentNameFor(studentId);

    final permission = PickupPermission(
      id: _generateId('permission'),
      schoolId: profile.schoolId,
      studentId: studentId,
      guardianId: guardianId,
      delegateName: delegateName,
      delegatePhone: delegatePhone,
      relationship: relationship,
      approvedBy: profile.displayName,
      startsAt: startsAt,
      endsAt: endsAt,
      isActive: true,
    );

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(pickupPermissionRepositoryProvider)
          .createPermission(permission);
      await ref
          .read(auditRepositoryProvider)
          .appendAuditEntry(
            AuditTrailEntry(
              id: _generateId('audit'),
              schoolId: profile.schoolId,
              studentName: studentName,
              action: 'Delegate created',
              actorName: profile.displayName,
              occurredAt: DateTime.now(),
              notes: 'Temporary permission created for $delegateName.',
            ),
          );
    });
  }

  Future<void> _transition(
    PickupQueueEntry entry,
    PickupEventType nextStatus, {
    required PickupEventSource source,
    String? actorName,
    String? notes,
  }) async {
    var currentEntry = await _reconcileEntry(entry);

    final machine = ref.read(queueStateMachineProvider);
    final validationError = machine.validateTransition(
      currentEntry.eventType,
      nextStatus,
    );
    if (validationError != null) {
      await _recordBlockedTransition(
        currentEntry,
        action: '${nextStatus.name} blocked',
        notes: validationError,
        actorName: actorName,
      );
      throw PickupWorkflowException(
        code: PickupWorkflowErrorCode.invalidStateTransition,
        message: validationError,
      );
    }

    if (nextStatus == PickupEventType.released) {
      currentEntry = await _guardReleaseAllowed(
        currentEntry,
        actorName: actorName,
      );
    }

    final isVerified =
        nextStatus == PickupEventType.verified ||
        nextStatus == PickupEventType.released;
    final updatedEntry = currentEntry.copyWith(
      eventType: nextStatus,
      isNfcVerified: isVerified,
      etaLabel: _etaLabelFor(nextStatus),
    );
    final pickupEvent = PickupEvent(
      id: _generateId('pickup'),
      schoolId: updatedEntry.schoolId,
      studentId: updatedEntry.studentId,
      guardianId: updatedEntry.guardianId,
      type: nextStatus,
      source: source,
      pickupZone: updatedEntry.pickupZone,
      occurredAt: DateTime.now(),
      actorName: actorName ?? _actorName,
      notes: notes ?? 'Queue status changed to ${nextStatus.name}.',
    );
    final releaseEvent = nextStatus == PickupEventType.released
        ? ReleaseEvent(
            id: _generateId('release'),
            schoolId: updatedEntry.schoolId,
            studentId: updatedEntry.studentId,
            guardianId: updatedEntry.guardianId,
            staffId: ref.read(currentUserProfileProvider)?.uid ?? 'staff',
            staffName: actorName ?? _actorName,
            releasedAt: DateTime.now(),
            verificationMethod: 'nfc-verified-release',
            notes: notes ?? 'Release confirmed from staff workflow.',
          )
        : null;

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(queueRepositoryProvider).saveQueueEntry(updatedEntry);
      await ref.read(pickupEventRepositoryProvider).logPickupEvent(pickupEvent);

      if (releaseEvent != null) {
        await ref
            .read(releaseEventRepositoryProvider)
            .createReleaseEvent(releaseEvent);
      }

      await ref
          .read(auditRepositoryProvider)
          .appendAuditEntry(
            AuditTrailEntry(
              id: _generateId('audit'),
              schoolId: updatedEntry.schoolId,
              studentName: updatedEntry.studentName,
              action: nextStatus.name,
              actorName: actorName ?? _actorName,
              occurredAt: DateTime.now(),
              notes: notes ?? 'Queue status changed to ${nextStatus.name}.',
            ),
          );

      await _dispatchNotifications(
        updatedEntry: updatedEntry,
        pickupEvent: pickupEvent,
        releaseEvent: releaseEvent,
      );
    });
  }

  Future<void> _saveQueueAndAudit({
    required PickupQueueEntry updatedEntry,
    required String auditAction,
    required String auditNotes,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(queueRepositoryProvider).saveQueueEntry(updatedEntry);
      await ref
          .read(auditRepositoryProvider)
          .appendAuditEntry(
            AuditTrailEntry(
              id: _generateId('audit'),
              schoolId: updatedEntry.schoolId,
              studentName: updatedEntry.studentName,
              action: auditAction,
              actorName: _actorName,
              occurredAt: DateTime.now(),
              notes: auditNotes,
            ),
          );
    });
  }

  Future<PickupQueueEntry> _guardReleaseAllowed(
    PickupQueueEntry entry, {
    String? actorName,
  }) async {
    final role = ref.read(resolvedRoleProvider);
    if (role != AppRole.staff) {
      const message = 'Only staff users can release students.';
      await _recordBlockedTransition(
        entry,
        action: 'Release blocked',
        notes: message,
        actorName: actorName,
      );
      throw const PickupWorkflowException(
        code: PickupWorkflowErrorCode.unauthorizedRole,
        message: message,
      );
    }

    if (!entry.isNfcVerified || entry.eventType != PickupEventType.verified) {
      const message =
          'Release requires a verified queue item with completed on-site verification.';
      await _recordBlockedTransition(
        entry,
        action: 'Release blocked',
        notes: message,
        actorName: actorName,
      );
      throw const PickupWorkflowException(
        code: PickupWorkflowErrorCode.invalidStateTransition,
        message: message,
      );
    }

    final students = await _loadStudents();
    final permissions = await _loadPickupPermissions();
    final student = students
        .where((item) => item.id == entry.studentId)
        .firstOrNull;
    final decision = ref
        .read(pickupAuthorizationServiceProvider)
        .evaluate(
          entry: entry,
          student: student,
          permissions: permissions,
          at: DateTime.now(),
        );
    if (decision.isAuthorized) {
      return entry;
    }

    final flaggedEntry = entry.copyWith(
      exceptionFlag:
          decision.message ??
          'Office approval is required before this student can be released.',
      exceptionCode: decision.exceptionCode?.name,
      officeApprovalRequired: decision.requiresOfficeApproval,
    );
    if (!_queueEntriesEqual(entry, flaggedEntry)) {
      await ref.read(queueRepositoryProvider).saveQueueEntry(flaggedEntry);
    }
    await _recordBlockedTransition(
      flaggedEntry,
      action: 'Release blocked',
      notes:
          decision.message ??
          'Office approval is required before this student can be released.',
      actorName: actorName,
    );
    throw PickupWorkflowException(
      code: switch (decision.exceptionCode) {
        PickupExceptionCode.expiredDelegation =>
          PickupWorkflowErrorCode.expiredDelegation,
        PickupExceptionCode.unauthorizedGuardian =>
          PickupWorkflowErrorCode.unauthorizedGuardian,
        _ => PickupWorkflowErrorCode.officeApprovalRequired,
      },
      message:
          decision.message ??
          'Office approval is required before this student can be released.',
    );
  }

  Future<PickupQueueEntry> _reconcileEntry(PickupQueueEntry entry) async {
    final environment = ref.read(appEnvironmentProvider);
    final role = ref.read(resolvedRoleProvider);
    if (!environment.isMockMode && role != AppRole.staff) {
      return entry;
    }

    final students = await _loadStudents();
    final permissions = await _loadPickupPermissions();
    final pickupEvents = await _loadPickupEvents();
    final releaseEvents = await _loadReleaseEvents();
    final student = students
        .where((item) => item.id == entry.studentId)
        .firstOrNull;

    final change = ref
        .read(queueReconciliationServiceProvider)
        .reconcileEntry(
          entry: entry,
          student: student,
          permissions: permissions,
          pickupEvents: pickupEvents,
          releaseEvents: releaseEvents,
          at: DateTime.now(),
        );
    if (change == null) {
      return entry;
    }

    await ref.read(queueRepositoryProvider).saveQueueEntry(change.updatedEntry);
    await ref
        .read(auditRepositoryProvider)
        .appendAuditEntry(
          AuditTrailEntry(
            id: _generateId('audit'),
            schoolId: change.updatedEntry.schoolId,
            studentName: change.updatedEntry.studentName,
            action: 'Queue reconciled',
            actorName: 'GeoTap Guardian reconciliation',
            occurredAt: DateTime.now(),
            notes: change.notes,
          ),
        );
    return change.updatedEntry;
  }

  Future<void> _recordBlockedTransition(
    PickupQueueEntry entry, {
    required String action,
    required String notes,
    String? actorName,
  }) {
    return ref
        .read(auditRepositoryProvider)
        .appendAuditEntry(
          AuditTrailEntry(
            id: _generateId('audit'),
            schoolId: entry.schoolId,
            studentName: entry.studentName,
            action: action,
            actorName: actorName ?? _actorName,
            occurredAt: DateTime.now(),
            notes: notes,
          ),
        );
  }

  Future<void> _dispatchNotifications({
    required PickupQueueEntry updatedEntry,
    required PickupEvent pickupEvent,
    required ReleaseEvent? releaseEvent,
  }) async {
    final dispatcher = ref.read(notificationDispatcherProvider);
    try {
      await dispatcher.queueForPickupEvent(
        entry: updatedEntry,
        event: pickupEvent,
      );
      if (releaseEvent != null) {
        await dispatcher.queueForReleaseEvent(
          entry: updatedEntry,
          releaseEvent: releaseEvent,
        );
      }
    } catch (_) {
      // Notification jobs are best-effort and should not roll back queue state.
    }
  }

  String get _actorName =>
      ref.read(currentUserProfileProvider)?.displayName ?? 'GeoTap Guardian';

  String _generateId(String prefix) {
    return '${prefix}_${DateTime.now().microsecondsSinceEpoch}';
  }

  String _studentNameFor(String studentId) {
    final students = ref.read(studentsFutureProvider).asData?.value ?? const [];
    return students
            .where((student) => student.id == studentId)
            .map((student) => student.displayName)
            .firstOrNull ??
        studentId;
  }

  Future<List<PickupEvent>> _loadPickupEvents() async {
    final current = ref.read(pickupEventsStreamProvider).asData?.value;
    if (current != null) {
      return current;
    }
    return ref
        .read(pickupEventRepositoryProvider)
        .watchPickupEvents(ref.read(currentSchoolIdProvider))
        .first;
  }

  Future<List<PickupPermission>> _loadPickupPermissions() async {
    final current = ref.read(pickupPermissionsStreamProvider).asData?.value;
    if (current != null) {
      return current;
    }
    return ref
        .read(pickupPermissionRepositoryProvider)
        .watchPermissions(ref.read(currentSchoolIdProvider))
        .first;
  }

  Future<List<ReleaseEvent>> _loadReleaseEvents() async {
    final current = ref.read(releaseEventsStreamProvider).asData?.value;
    if (current != null) {
      return current;
    }
    return ref
        .read(releaseEventRepositoryProvider)
        .watchReleaseEvents(ref.read(currentSchoolIdProvider))
        .first;
  }

  Future<List<Student>> _loadStudents() async {
    final current = ref.read(studentsFutureProvider).asData?.value;
    if (current != null) {
      return current;
    }
    return ref
        .read(studentRepositoryProvider)
        .fetchStudents(ref.read(currentSchoolIdProvider));
  }

  String _etaLabelFor(PickupEventType status) {
    return switch (status) {
      PickupEventType.pending => 'Pending',
      PickupEventType.approaching => 'Approaching',
      PickupEventType.verified => 'Ready',
      PickupEventType.released => 'Released',
    };
  }
}

bool _queueEntriesEqual(PickupQueueEntry left, PickupQueueEntry right) {
  return left.toMap().toString() == right.toMap().toString();
}

extension _FirstOrNullExtension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
