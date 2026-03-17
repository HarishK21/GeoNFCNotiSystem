import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/app_role.dart';
import '../../domain/models/audit_trail_entry.dart';
import '../../domain/models/pickup_event.dart';
import '../../domain/models/pickup_permission.dart';
import '../../domain/models/pickup_queue_entry.dart';
import '../../domain/models/release_event.dart';
import '../../domain/repositories/audit_repository.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/pickup_event_repository.dart';
import '../../domain/repositories/pickup_permission_repository.dart';
import '../../domain/repositories/queue_repository.dart';
import '../../domain/repositories/release_event_repository.dart';
import '../../domain/services/queue_state_machine.dart';
import 'flow_providers.dart';
import 'repository_providers.dart';

final queueStateMachineProvider = Provider<QueueStateMachine>((ref) {
  return const QueueStateMachine();
});

final authActionControllerProvider =
    AsyncNotifierProvider<AuthActionController, void>(
      AuthActionController.new,
    );

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
      () => repository.signInWithEmailPassword(email: email, password: password),
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
    await _transition(entry, PickupEventType.approaching);
  }

  Future<void> verifyPickup(PickupQueueEntry entry) async {
    await _transition(entry, PickupEventType.verified);
  }

  Future<void> releaseStudent(PickupQueueEntry entry) async {
    await _transition(entry, PickupEventType.released);
  }

  Future<void> flagException(PickupQueueEntry entry, String flag) async {
    final updatedEntry = entry.copyWith(exceptionFlag: flag);
    await _saveQueueAndAudit(
      updatedEntry,
      auditAction: 'Exception flagged',
      auditNotes: flag,
    );
  }

  Future<void> clearException(PickupQueueEntry entry) async {
    final updatedEntry = entry.copyWith(clearExceptionFlag: true);
    await _saveQueueAndAudit(
      updatedEntry,
      auditAction: 'Exception cleared',
      auditNotes: 'Exception cleared for ${entry.studentName}.',
    );
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
    if (profile == null) {
      throw StateError('No signed-in profile is available.');
    }

    final permission = PickupPermission(
      id: _generateId('permission'),
      schoolId: profile.schoolId,
      studentId: studentId,
      guardianId: profile.linkedGuardianId ?? '',
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
      await ref.read(pickupPermissionRepositoryProvider).createPermission(
        permission,
      );
      await ref.read(auditRepositoryProvider).appendAuditEntry(
        AuditTrailEntry(
          id: _generateId('audit'),
          schoolId: profile.schoolId,
          studentName: studentId,
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
    PickupEventType nextStatus,
  ) async {
    final machine = ref.read(queueStateMachineProvider);
    final validationError = machine.validateTransition(entry.eventType, nextStatus);
    if (validationError != null) {
      throw StateError(validationError);
    }

    final isVerified =
        nextStatus == PickupEventType.verified ||
        nextStatus == PickupEventType.released;
    final updatedEntry = entry.copyWith(
      eventType: nextStatus,
      isNfcVerified: isVerified,
      etaLabel: _etaLabelFor(nextStatus),
    );

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(queueRepositoryProvider).saveQueueEntry(updatedEntry);
      await ref.read(pickupEventRepositoryProvider).logPickupEvent(
        PickupEvent(
          id: _generateId('pickup'),
          schoolId: updatedEntry.schoolId,
          studentId: updatedEntry.studentId,
          guardianId: updatedEntry.guardianId,
          type: nextStatus,
          source: nextStatus == PickupEventType.verified
              ? PickupEventSource.nfc
              : PickupEventSource.manual,
          pickupZone: updatedEntry.pickupZone,
          occurredAt: DateTime.now(),
          actorName: _actorName,
          notes: 'Queue status changed to ${nextStatus.name}.',
        ),
      );

      if (nextStatus == PickupEventType.released) {
        await ref.read(releaseEventRepositoryProvider).createReleaseEvent(
          ReleaseEvent(
            id: _generateId('release'),
            schoolId: updatedEntry.schoolId,
            studentId: updatedEntry.studentId,
            guardianId: updatedEntry.guardianId,
            staffId: ref.read(currentUserProfileProvider)?.uid ?? 'staff',
            staffName: _actorName,
            releasedAt: DateTime.now(),
            verificationMethod: 'app-confirmed',
            notes: 'Release confirmed from staff workflow.',
          ),
        );
      }

      await ref.read(auditRepositoryProvider).appendAuditEntry(
        AuditTrailEntry(
          id: _generateId('audit'),
          schoolId: updatedEntry.schoolId,
          studentName: updatedEntry.studentName,
          action: nextStatus.name,
          actorName: _actorName,
          occurredAt: DateTime.now(),
          notes: 'Queue status changed to ${nextStatus.name}.',
        ),
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
      await ref.read(auditRepositoryProvider).appendAuditEntry(
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

  String get _actorName =>
      ref.read(currentUserProfileProvider)?.displayName ?? 'GeoTap Guardian';

  String _generateId(String prefix) {
    return '${prefix}_${DateTime.now().microsecondsSinceEpoch}';
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
