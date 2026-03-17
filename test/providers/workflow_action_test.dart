import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:geo_tap_guardian/core/models/app_role.dart';
import 'package:geo_tap_guardian/core/providers/app_providers.dart';
import 'package:geo_tap_guardian/domain/models/pickup_event.dart';

void main() {
  test('parent can create a temporary permission in mock mode', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final permissionsSubscription = container.listen(
      pickupPermissionsStreamProvider,
      (previous, next) {},
    );
    final auditSubscription = container.listen(
      auditTrailStreamProvider,
      (previous, next) {},
    );
    addTearDown(permissionsSubscription.close);
    addTearDown(auditSubscription.close);

    await container
        .read(authActionControllerProvider.notifier)
        .signInAsDemoRole(AppRole.parent);
    await _waitFor(
      () =>
          container.read(currentUserProfileStreamProvider).asData?.value !=
          null,
    );
    await container.read(guardiansFutureProvider.future);
    await container.read(studentsFutureProvider.future);
    await _waitFor(
      () => container.read(pickupPermissionsStreamProvider).hasValue,
    );
    await _waitFor(() => container.read(auditTrailStreamProvider).hasValue);

    expect(container.read(familyDelegatesProvider), hasLength(1));

    await container
        .read(workflowActionControllerProvider.notifier)
        .createTemporaryPermission(
          studentId: 'student_maya',
          delegateName: 'Sam Brooks',
          delegatePhone: '+1-555-0133',
          relationship: 'Uncle',
          startsAt: DateTime.parse('2026-03-17T15:00:00Z'),
          endsAt: DateTime.parse('2026-03-17T16:00:00Z'),
        );

    await _waitFor(() => container.read(familyDelegatesProvider).length == 2);

    expect(container.read(familyDelegatesProvider), hasLength(2));
    expect(
      container
          .read(auditTrailProvider)
          .any(
            (event) =>
                event.action == 'Delegate created' &&
                event.studentName == 'Maya Brooks',
          ),
      isTrue,
    );
  });

  test(
    'staff verify and release actions update queue and release data',
    () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final queueSubscription = container.listen(
        queueEntriesStreamProvider,
        (previous, next) {},
      );
      final releaseSubscription = container.listen(
        releaseEventsStreamProvider,
        (previous, next) {},
      );
      addTearDown(queueSubscription.close);
      addTearDown(releaseSubscription.close);

      await container
          .read(authActionControllerProvider.notifier)
          .signInAsDemoRole(AppRole.staff);
      await _waitFor(
        () =>
            container.read(currentUserProfileStreamProvider).asData?.value !=
            null,
      );
      await _waitFor(() => container.read(queueEntriesStreamProvider).hasValue);
      await _waitFor(
        () => container.read(releaseEventsStreamProvider).hasValue,
      );
      final store = container.read(mockDataStoreProvider);

      var mayaEntry = container
          .read(queueEntriesStreamProvider)
          .asData!
          .value
          .firstWhere((entry) => entry.studentId == 'student_maya');
      expect(mayaEntry.eventType, PickupEventType.approaching);

      await container
          .read(workflowActionControllerProvider.notifier)
          .verifyPickup(mayaEntry);
      final verifyState = container.read(workflowActionControllerProvider);
      expect(
        verifyState.hasError,
        isFalse,
        reason: 'Verify action failed: ${verifyState.error}',
      );

      mayaEntry = store.queueEntries.firstWhere(
        (entry) => entry.studentId == 'student_maya',
      );
      expect(mayaEntry.eventType, PickupEventType.verified);
      expect(mayaEntry.isNfcVerified, isTrue);

      await container
          .read(workflowActionControllerProvider.notifier)
          .releaseStudent(mayaEntry);
      final releaseState = container.read(workflowActionControllerProvider);
      expect(
        releaseState.hasError,
        isFalse,
        reason: 'Release action failed: ${releaseState.error}',
      );

      final updatedMaya = store.queueEntries.firstWhere(
        (entry) => entry.studentId == 'student_maya',
      );
      final releaseEvents = store.releaseEvents;

      expect(updatedMaya.eventType, PickupEventType.released);
      expect(
        releaseEvents.any((event) => event.studentId == 'student_maya'),
        isTrue,
      );
      expect(
        container
            .read(liveQueueEntriesProvider)
            .where((entry) => entry.studentId == 'student_maya'),
        isEmpty,
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
  throw StateError('Timed out while waiting for workflow updates.');
}
