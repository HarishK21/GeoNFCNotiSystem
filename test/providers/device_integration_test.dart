import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:geo_tap_guardian/core/models/app_role.dart';
import 'package:geo_tap_guardian/core/providers/app_providers.dart';
import 'package:geo_tap_guardian/domain/models/geofence_target.dart';
import 'package:geo_tap_guardian/domain/models/geofence_trigger_event.dart';
import 'package:geo_tap_guardian/domain/models/geofencing_status.dart';
import 'package:geo_tap_guardian/domain/models/nfc_status.dart';
import 'package:geo_tap_guardian/domain/models/nfc_verification_event.dart';
import 'package:geo_tap_guardian/domain/models/nfc_verification_target.dart';
import 'package:geo_tap_guardian/domain/models/pickup_event.dart';
import 'package:geo_tap_guardian/domain/models/pickup_queue_entry.dart';
import 'package:geo_tap_guardian/domain/services/geofencing_service.dart';
import 'package:geo_tap_guardian/domain/services/nfc_service.dart';

void main() {
  test(
    'debug geofence simulation moves a parent queue entry to approaching and logs audit data',
    () async {
      final geofencing = FakeGeofencingService();
      final nfc = FakeNfcService();
      final container = ProviderContainer(
        overrides: [
          geofencingServiceProvider.overrideWithValue(geofencing),
          nfcServiceProvider.overrideWithValue(nfc),
        ],
      );
      addTearDown(() async {
        container.dispose();
        await geofencing.dispose();
        await nfc.dispose();
      });

      final queueSubscription = container.listen(
        queueEntriesStreamProvider,
        (previous, next) {},
      );
      addTearDown(queueSubscription.close);

      container.read(deviceIntegrationBootstrapProvider);
      await container
          .read(authActionControllerProvider.notifier)
          .signInAsDemoRole(AppRole.parent);
      await _waitFor(
        () =>
            container.read(currentUserProfileStreamProvider).asData?.value !=
            null,
        description: 'parent profile resolution',
      );
      await container.read(guardiansFutureProvider.future);
      await container.read(studentsFutureProvider.future);
      await _waitFor(
        () => container.read(queueEntriesStreamProvider).hasValue,
        description: 'parent queue hydration',
      );
      expect(container.read(activeGeofenceTargetsProvider), isNotEmpty);
      await _waitFor(
        () => geofencing.syncedTargets.isNotEmpty,
        description: 'geofence target sync',
      );

      await container
          .read(deviceActionControllerProvider.notifier)
          .resetQueueState('student_maya');
      await _waitFor(
        () =>
            _queueEntryFor(container, 'student_maya').eventType ==
            PickupEventType.pending,
        description: 'queue reset to pending',
      );

      final target = geofencing.syncedTargets.singleWhere(
        (item) => item.studentId == 'student_maya',
      );
      await container
          .read(deviceActionControllerProvider.notifier)
          .simulateApproaching(target);
      await _waitFor(
        () =>
            _queueEntryFor(container, 'student_maya').eventType ==
            PickupEventType.approaching,
        description: 'geofence transition to approaching',
      );

      final store = container.read(mockDataStoreProvider);
      final pickupEvent = store.pickupEvents.lastWhere(
        (event) =>
            event.studentId == 'student_maya' &&
            event.type == PickupEventType.approaching,
      );
      final auditEntry = store.auditTrail.lastWhere(
        (entry) => entry.studentName == 'Maya Brooks',
      );

      expect(pickupEvent.source, PickupEventSource.geofence);
      expect(pickupEvent.actorName, 'Debug geofence simulator');
      expect(auditEntry.action, 'approaching');
      expect(auditEntry.notes, contains('Approaching simulated'));
    },
  );

  test(
    'debug NFC verification moves a staff queue entry to verified and unlocks release flow data',
    () async {
      final geofencing = FakeGeofencingService();
      final nfc = FakeNfcService();
      final container = ProviderContainer(
        overrides: [
          geofencingServiceProvider.overrideWithValue(geofencing),
          nfcServiceProvider.overrideWithValue(nfc),
        ],
      );
      addTearDown(() async {
        container.dispose();
        await geofencing.dispose();
        await nfc.dispose();
      });

      final queueSubscription = container.listen(
        queueEntriesStreamProvider,
        (previous, next) {},
      );
      addTearDown(queueSubscription.close);

      container.read(deviceIntegrationBootstrapProvider);
      await container
          .read(authActionControllerProvider.notifier)
          .signInAsDemoRole(AppRole.staff);
      await _waitFor(
        () =>
            container.read(currentUserProfileStreamProvider).asData?.value !=
            null,
        description: 'staff profile resolution',
      );
      await _waitFor(
        () => container.read(queueEntriesStreamProvider).hasValue,
        description: 'staff queue hydration',
      );

      final queueEntry = _queueEntryFor(container, 'student_maya');
      expect(queueEntry.eventType, PickupEventType.approaching);

      final target = NfcVerificationTarget(
        schoolId: queueEntry.schoolId,
        studentId: queueEntry.studentId,
        guardianId: queueEntry.guardianId,
        studentName: queueEntry.studentName,
        guardianName: queueEntry.guardianName,
      );

      await container
          .read(deviceActionControllerProvider.notifier)
          .startNfcVerificationSession(target);
      await _waitFor(() => nfc.listening, description: 'NFC session start');

      await container
          .read(deviceActionControllerProvider.notifier)
          .simulateVerified(target);
      await _waitFor(
        () =>
            _queueEntryFor(container, 'student_maya').eventType ==
            PickupEventType.verified,
        description: 'NFC transition to verified',
      );

      final store = container.read(mockDataStoreProvider);
      final pickupEvent = store.pickupEvents.lastWhere(
        (event) =>
            event.studentId == 'student_maya' &&
            event.type == PickupEventType.verified,
      );
      final updatedQueueEntry = _queueEntryFor(container, 'student_maya');
      final nfcStatus = await container.read(nfcStatusProvider.future);

      expect(pickupEvent.source, PickupEventSource.nfc);
      expect(pickupEvent.actorName, 'Debug NFC simulator');
      expect(updatedQueueEntry.canRelease, isTrue);
      expect(nfcStatus.listening, isFalse);
    },
  );

  test(
    'NFC verification with the wrong guardian id is rejected without changing the queue',
    () async {
      final geofencing = FakeGeofencingService();
      final nfc = FakeNfcService();
      final container = ProviderContainer(
        overrides: [
          geofencingServiceProvider.overrideWithValue(geofencing),
          nfcServiceProvider.overrideWithValue(nfc),
        ],
      );
      addTearDown(() async {
        container.dispose();
        await geofencing.dispose();
        await nfc.dispose();
      });

      final queueSubscription = container.listen(
        queueEntriesStreamProvider,
        (previous, next) {},
      );
      addTearDown(queueSubscription.close);

      container.read(deviceIntegrationBootstrapProvider);
      await container
          .read(authActionControllerProvider.notifier)
          .signInAsDemoRole(AppRole.staff);
      await _waitFor(
        () =>
            container.read(currentUserProfileStreamProvider).asData?.value !=
            null,
        description: 'staff profile resolution for wrong-guardian NFC test',
      );
      await _waitFor(
        () => container.read(queueEntriesStreamProvider).hasValue,
        description: 'staff queue hydration for wrong-guardian NFC test',
      );

      final originalEntry = _queueEntryFor(container, 'student_maya');
      final wrongTarget = NfcVerificationTarget(
        schoolId: originalEntry.schoolId,
        studentId: originalEntry.studentId,
        guardianId: 'guardian_wrong',
        studentName: originalEntry.studentName,
        guardianName: 'Wrong Guardian',
      );

      await container
          .read(deviceActionControllerProvider.notifier)
          .simulateVerified(wrongTarget);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final store = container.read(mockDataStoreProvider);
      final unchangedEntry = _queueEntryFor(container, 'student_maya');

      expect(unchangedEntry.eventType, PickupEventType.approaching);
      expect(
        store.pickupEvents.any(
          (event) =>
              event.studentId == 'student_maya' &&
              event.type == PickupEventType.verified,
        ),
        isFalse,
      );
    },
  );
}

PickupQueueEntry _queueEntryFor(ProviderContainer container, String studentId) {
  return container
      .read(queueEntriesStreamProvider)
      .asData!
      .value
      .firstWhere((entry) => entry.studentId == studentId);
}

Future<void> _waitFor(
  bool Function() predicate, {
  required String description,
}) async {
  for (var attempt = 0; attempt < 200; attempt++) {
    if (predicate()) {
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  throw StateError('Timed out while waiting for $description.');
}

class FakeGeofencingService implements GeofencingService {
  final _controller = StreamController<GeofenceTriggerEvent>.broadcast();
  List<GeofenceTarget> syncedTargets = const [];
  var _permissionGranted = true;

  @override
  Future<void> clearTargets() async {
    syncedTargets = const [];
  }

  Future<void> dispose() async {
    await _controller.close();
  }

  @override
  Future<GeofencingStatus> getStatus() async {
    return GeofencingStatus(
      supported: true,
      permissionGranted: _permissionGranted,
      locationServicesEnabled: true,
      activeTargetCount: syncedTargets.length,
      detail: 'Fake geofencing service for integration tests.',
    );
  }

  @override
  Future<void> requestPermission() async {
    _permissionGranted = true;
  }

  @override
  Future<void> simulateEnter(GeofenceTarget target) async {
    _controller.add(
      GeofenceTriggerEvent(
        targetId: target.id,
        schoolId: target.schoolId,
        studentId: target.studentId,
        guardianId: target.guardianId,
        studentName: target.studentName,
        pickupZone: target.pickupZone,
        occurredAt: DateTime.now(),
        isSimulated: true,
      ),
    );
  }

  @override
  Future<void> syncTargets(List<GeofenceTarget> targets) async {
    syncedTargets = List<GeofenceTarget>.from(targets);
  }

  @override
  Stream<GeofenceTriggerEvent> watchEvents() => _controller.stream;
}

class FakeNfcService implements NfcService {
  final _controller = StreamController<NfcVerificationEvent>.broadcast();
  NfcVerificationTarget? _target;
  var listening = false;

  Future<void> dispose() async {
    await _controller.close();
  }

  @override
  Future<NfcStatus> getStatus() async {
    return NfcStatus(
      supported: true,
      enabled: true,
      listening: listening,
      targetStudentId: _target?.studentId,
      targetLabel: _target?.studentName,
      detail: 'Fake NFC service for integration tests.',
    );
  }

  @override
  Future<void> simulateScan(NfcVerificationTarget target) async {
    listening = false;
    _target = null;
    _controller.add(
      NfcVerificationEvent(
        schoolId: target.schoolId,
        studentId: target.studentId,
        guardianId: target.guardianId,
        studentName: target.studentName,
        tagId: 'debug-fake-tag',
        occurredAt: DateTime.now(),
        isSimulated: true,
      ),
    );
  }

  @override
  Future<void> startVerificationSession(NfcVerificationTarget target) async {
    _target = target;
    listening = true;
  }

  @override
  Future<void> stopVerificationSession() async {
    listening = false;
    _target = null;
  }

  @override
  Stream<NfcVerificationEvent> watchEvents() => _controller.stream;
}
