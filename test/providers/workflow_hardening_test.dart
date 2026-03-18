import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:geo_tap_guardian/core/models/app_role.dart';
import 'package:geo_tap_guardian/core/providers/app_providers.dart';
import 'package:geo_tap_guardian/domain/models/office_approval_status.dart';
import 'package:geo_tap_guardian/domain/models/pickup_event.dart';
import 'package:geo_tap_guardian/domain/models/pickup_exception_code.dart';
import 'package:geo_tap_guardian/domain/models/pickup_permission.dart';
import 'package:geo_tap_guardian/domain/models/pickup_workflow_exception.dart';
import 'package:geo_tap_guardian/domain/models/push_notification_job.dart';

void main() {
  test(
    'parent users cannot release students even when the queue item is verified',
    () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final queueSubscription = container.listen(
        queueEntriesStreamProvider,
        (previous, next) {},
      );
      addTearDown(queueSubscription.close);

      await container
          .read(authActionControllerProvider.notifier)
          .signInAsDemoRole(AppRole.parent);
      await _waitFor(
        () =>
            container.read(currentUserProfileStreamProvider).asData?.value !=
            null,
      );
      await _waitFor(() => container.read(queueEntriesStreamProvider).hasValue);

      final queueRepository = container.read(queueRepositoryProvider);
      final store = container.read(mockDataStoreProvider);
      final verifiedEntry = store.queueEntries
          .firstWhere((entry) => entry.studentId == 'student_maya')
          .copyWith(
            eventType: PickupEventType.verified,
            isNfcVerified: true,
            etaLabel: 'Ready',
          );
      await queueRepository.saveQueueEntry(verifiedEntry);

      await expectLater(
        container
            .read(workflowActionControllerProvider.notifier)
            .releaseStudent(verifiedEntry),
        throwsA(isA<PickupWorkflowException>()),
      );

      expect(
        store.auditTrail.any(
          (entry) =>
              entry.studentName == 'Maya Brooks' &&
              entry.action == 'Release blocked' &&
              entry.notes.contains('Only staff users can release students'),
        ),
        isTrue,
      );
    },
  );

  test(
    'release is blocked for an unauthorized guardian and writes a denial audit',
    () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final queueSubscription = container.listen(
        queueEntriesStreamProvider,
        (previous, next) {},
      );
      addTearDown(queueSubscription.close);

      await container
          .read(authActionControllerProvider.notifier)
          .signInAsDemoRole(AppRole.staff);
      await _waitFor(
        () =>
            container.read(currentUserProfileStreamProvider).asData?.value !=
            null,
      );
      await _waitFor(() => container.read(queueEntriesStreamProvider).hasValue);

      final queueRepository = container.read(queueRepositoryProvider);
      final store = container.read(mockDataStoreProvider);
      final unauthorizedEntry = store.queueEntries
          .firstWhere((entry) => entry.studentId == 'student_maya')
          .copyWith(
            guardianId: 'visitor_casey',
            guardianName: 'Casey Visitor',
            eventType: PickupEventType.verified,
            isNfcVerified: true,
            etaLabel: 'Ready',
            clearExceptionFlag: true,
          );
      await queueRepository.saveQueueEntry(unauthorizedEntry);

      await expectLater(
        container
            .read(workflowActionControllerProvider.notifier)
            .releaseStudent(unauthorizedEntry),
        throwsA(isA<PickupWorkflowException>()),
      );

      final updatedEntry = store.queueEntries.firstWhere(
        (entry) => entry.studentId == 'student_maya',
      );

      expect(updatedEntry.officeApprovalRequired, isTrue);
      expect(
        updatedEntry.exceptionCode,
        PickupExceptionCode.unauthorizedGuardian.name,
      );
      expect(
        store.releaseEvents.any((event) => event.studentId == 'student_maya'),
        isFalse,
      );
      expect(
        store.auditTrail.any(
          (entry) =>
              entry.studentName == 'Maya Brooks' &&
              entry.action == 'Release blocked' &&
              entry.notes.contains('not authorized'),
        ),
        isTrue,
      );
      final approval = store.officeApprovals.firstWhere(
        (record) => record.queueEntryId == unauthorizedEntry.id,
      );
      expect(approval.status, OfficeApprovalStatus.pending);
      expect(
        approval.reasonCode,
        PickupExceptionCode.unauthorizedGuardian.name,
      );
    },
  );

  test(
    'approving an office approval clears the queue block and allows release',
    () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final queueSubscription = container.listen(
        queueEntriesStreamProvider,
        (previous, next) {},
      );
      final approvalSubscription = container.listen(
        officeApprovalsStreamProvider,
        (previous, next) {},
      );
      addTearDown(queueSubscription.close);
      addTearDown(approvalSubscription.close);

      await container
          .read(authActionControllerProvider.notifier)
          .signInAsDemoRole(AppRole.staff);
      await _waitFor(
        () =>
            container.read(currentUserProfileStreamProvider).asData?.value !=
            null,
      );
      await _waitFor(() => container.read(queueEntriesStreamProvider).hasValue);

      final queueRepository = container.read(queueRepositoryProvider);
      final store = container.read(mockDataStoreProvider);
      final unauthorizedEntry = store.queueEntries
          .firstWhere((entry) => entry.studentId == 'student_maya')
          .copyWith(
            guardianId: 'visitor_casey',
            guardianName: 'Casey Visitor',
            eventType: PickupEventType.verified,
            isNfcVerified: true,
            etaLabel: 'Ready',
            clearExceptionFlag: true,
          );
      await queueRepository.saveQueueEntry(unauthorizedEntry);

      await expectLater(
        container
            .read(workflowActionControllerProvider.notifier)
            .releaseStudent(unauthorizedEntry),
        throwsA(isA<PickupWorkflowException>()),
      );

      final pendingApproval = store.officeApprovals.firstWhere(
        (record) => record.queueEntryId == unauthorizedEntry.id,
      );

      await container
          .read(workflowActionControllerProvider.notifier)
          .approveOfficeApproval(pendingApproval);

      final refreshedEntry = store.queueEntries.firstWhere(
        (entry) => entry.studentId == 'student_maya',
      );
      expect(refreshedEntry.officeApprovalRequired, isFalse);
      expect(refreshedEntry.exceptionFlag, isNull);

      await container
          .read(workflowActionControllerProvider.notifier)
          .releaseStudent(refreshedEntry);

      expect(
        store.releaseEvents.any(
          (event) => event.queueEntryId == unauthorizedEntry.id,
        ),
        isTrue,
      );
      expect(
        store.officeApprovals
            .firstWhere((record) => record.queueEntryId == unauthorizedEntry.id)
            .status,
        OfficeApprovalStatus.resolved,
      );
    },
  );

  test('denied office approval keeps release blocked', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final queueSubscription = container.listen(
      queueEntriesStreamProvider,
      (previous, next) {},
    );
    addTearDown(queueSubscription.close);

    await container
        .read(authActionControllerProvider.notifier)
        .signInAsDemoRole(AppRole.staff);
    await _waitFor(
      () =>
          container.read(currentUserProfileStreamProvider).asData?.value !=
          null,
    );
    await _waitFor(() => container.read(queueEntriesStreamProvider).hasValue);

    final queueRepository = container.read(queueRepositoryProvider);
    final store = container.read(mockDataStoreProvider);
    final unauthorizedEntry = store.queueEntries
        .firstWhere((entry) => entry.studentId == 'student_maya')
        .copyWith(
          guardianId: 'visitor_casey',
          guardianName: 'Casey Visitor',
          eventType: PickupEventType.verified,
          isNfcVerified: true,
          etaLabel: 'Ready',
          clearExceptionFlag: true,
        );
    await queueRepository.saveQueueEntry(unauthorizedEntry);

    await expectLater(
      container
          .read(workflowActionControllerProvider.notifier)
          .releaseStudent(unauthorizedEntry),
      throwsA(isA<PickupWorkflowException>()),
    );

    final pendingApproval = store.officeApprovals.firstWhere(
      (record) => record.queueEntryId == unauthorizedEntry.id,
    );

    await container
        .read(workflowActionControllerProvider.notifier)
        .denyOfficeApproval(
          pendingApproval,
          notes: 'Denied after custody check.',
        );

    final deniedEntry = store.queueEntries.firstWhere(
      (entry) => entry.studentId == 'student_maya',
    );
    expect(deniedEntry.officeApprovalRequired, isTrue);
    expect(
      deniedEntry.exceptionCode,
      PickupExceptionCode.officeApprovalDenied.name,
    );

    await expectLater(
      container
          .read(workflowActionControllerProvider.notifier)
          .releaseStudent(deniedEntry),
      throwsA(isA<PickupWorkflowException>()),
    );
  });

  test(
    'active delegation allows release and queues a release-completed notification',
    () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final queueSubscription = container.listen(
        queueEntriesStreamProvider,
        (previous, next) {},
      );
      final permissionSubscription = container.listen(
        pickupPermissionsStreamProvider,
        (previous, next) {},
      );
      addTearDown(queueSubscription.close);
      addTearDown(permissionSubscription.close);

      await container
          .read(authActionControllerProvider.notifier)
          .signInAsDemoRole(AppRole.staff);
      await _waitFor(
        () =>
            container.read(currentUserProfileStreamProvider).asData?.value !=
            null,
      );
      await _waitFor(() => container.read(queueEntriesStreamProvider).hasValue);

      final now = DateTime.now().toUtc();
      final permission = PickupPermission(
        id: 'permission_sam',
        schoolId: 'school_springfield',
        studentId: 'student_maya',
        guardianId: 'guardian_andrea',
        delegateName: 'Sam Brooks',
        delegatePhone: '+1-555-0133',
        relationship: 'Uncle',
        approvedBy: 'Andrea Brooks',
        startsAt: now.subtract(const Duration(minutes: 30)),
        endsAt: now.add(const Duration(minutes: 30)),
        isActive: true,
      );
      await container
          .read(pickupPermissionRepositoryProvider)
          .createPermission(permission);
      await _waitFor(
        () =>
            container
                .read(pickupPermissionsStreamProvider)
                .asData
                ?.value
                .any((item) => item.id == 'permission_sam') ==
            true,
      );

      final queueRepository = container.read(queueRepositoryProvider);
      final store = container.read(mockDataStoreProvider);
      final delegatedEntry = store.queueEntries
          .firstWhere((entry) => entry.studentId == 'student_maya')
          .copyWith(
            guardianId: 'delegate_sam',
            guardianName: 'Sam Brooks',
            eventType: PickupEventType.verified,
            isNfcVerified: true,
            etaLabel: 'Ready',
            clearExceptionFlag: true,
          );
      await queueRepository.saveQueueEntry(delegatedEntry);

      await container
          .read(workflowActionControllerProvider.notifier)
          .releaseStudent(delegatedEntry);

      final updatedEntry = store.queueEntries.firstWhere(
        (entry) => entry.studentId == 'student_maya',
      );

      expect(updatedEntry.eventType, PickupEventType.released);
      expect(
        store.releaseEvents.any((event) => event.studentId == 'student_maya'),
        isTrue,
      );
      expect(
        store.notificationJobs.any(
          (job) => job.type == PushNotificationType.releaseCompleted,
        ),
        isTrue,
      );
    },
  );

  test(
    'bootstrap reconciliation repairs stale queue state and queues emergency notifications',
    () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final queueSubscription = container.listen(
        queueEntriesStreamProvider,
        (previous, next) {},
      );
      final emergencySubscription = container.listen(
        emergencyNoticesStreamProvider,
        (previous, next) {},
      );
      final permissionSubscription = container.listen(
        pickupPermissionsStreamProvider,
        (previous, next) {},
      );
      final pickupEventSubscription = container.listen(
        pickupEventsStreamProvider,
        (previous, next) {},
      );
      final releaseEventSubscription = container.listen(
        releaseEventsStreamProvider,
        (previous, next) {},
      );
      addTearDown(queueSubscription.close);
      addTearDown(emergencySubscription.close);
      addTearDown(permissionSubscription.close);
      addTearDown(pickupEventSubscription.close);
      addTearDown(releaseEventSubscription.close);

      container.read(workflowHardeningBootstrapProvider);
      await container.read(studentsFutureProvider.future);
      await _waitFor(
        () => container.read(pickupPermissionsStreamProvider).hasValue,
      );
      await _waitFor(() => container.read(pickupEventsStreamProvider).hasValue);
      await _waitFor(
        () => container.read(releaseEventsStreamProvider).hasValue,
      );
      await _waitFor(() => container.read(queueEntriesStreamProvider).hasValue);
      await _waitFor(
        () =>
            container
                .read(mockDataStoreProvider)
                .queueEntries
                .firstWhere((entry) => entry.studentId == 'student_noah')
                .eventType ==
            PickupEventType.released,
      );

      final store = container.read(mockDataStoreProvider);
      expect(
        store.auditTrail.any(
          (entry) =>
              entry.studentName == 'Noah Patel' &&
              entry.action == 'Queue reconciled',
        ),
        isTrue,
      );
      expect(
        store.notificationJobs.any(
          (job) => job.type == PushNotificationType.emergencyNotice,
        ),
        isTrue,
      );
    },
  );
}

Future<void> _waitFor(bool Function() predicate) async {
  for (var attempt = 0; attempt < 200; attempt++) {
    if (predicate()) {
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  throw StateError('Timed out while waiting for hardened workflow updates.');
}
