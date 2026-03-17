import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/device_geofence_defaults.dart';
import '../../data/platform/method_channel_geofencing_service.dart';
import '../../data/platform/method_channel_nfc_service.dart';
import '../../data/platform/stub_device_services.dart';
import '../../domain/models/geofence_target.dart';
import '../../domain/models/geofence_trigger_event.dart';
import '../../domain/models/geofencing_status.dart';
import '../../domain/models/nfc_status.dart';
import '../../domain/models/nfc_verification_event.dart';
import '../../domain/models/nfc_verification_target.dart';
import '../../domain/models/pickup_event.dart';
import '../../domain/models/pickup_queue_entry.dart';
import '../../domain/services/geofencing_service.dart';
import '../../domain/services/nfc_service.dart';
import '../models/app_role.dart';
import 'action_providers.dart';
import 'flow_providers.dart';
import 'repository_providers.dart';

final geofencingServiceProvider = Provider<GeofencingService>((ref) {
  if (defaultTargetPlatform == TargetPlatform.android) {
    return MethodChannelGeofencingService();
  }
  return StubGeofencingService();
});

final nfcServiceProvider = Provider<NfcService>((ref) {
  if (defaultTargetPlatform == TargetPlatform.android) {
    return MethodChannelNfcService();
  }
  return StubNfcService();
});

final deviceDebugEnabledProvider = Provider<bool>((ref) {
  final environment = ref.watch(appEnvironmentProvider);
  return kDebugMode || environment.isMockMode;
});

final geofencingStatusProvider = FutureProvider<GeofencingStatus>((ref) {
  return ref.watch(geofencingServiceProvider).getStatus();
});

final nfcStatusProvider = FutureProvider<NfcStatus>((ref) {
  return ref.watch(nfcServiceProvider).getStatus();
});

final activeGeofenceTargetsProvider = Provider<List<GeofenceTarget>>((ref) {
  final profile = ref.watch(currentUserProfileProvider);
  final guardian = ref.watch(currentGuardianProvider);
  final students = ref.watch(familyStudentsProvider);

  if (profile == null || profile.role != AppRole.parent || guardian == null) {
    return const [];
  }

  final defaults = geofenceDefaultsForSchool(profile.schoolId);
  return students
      .map(
        (student) => GeofenceTarget(
          id: 'geofence_${guardian.id}_${student.id}',
          schoolId: profile.schoolId,
          studentId: student.id,
          guardianId: guardian.id,
          studentName: student.displayName,
          pickupZone: student.pickupZone,
          latitude: defaults.latitude,
          longitude: defaults.longitude,
          radiusMeters: defaults.radiusMeters,
        ),
      )
      .toList(growable: false);
});

final deviceIntegrationBootstrapProvider = Provider<void>((ref) {
  final geofencingService = ref.watch(geofencingServiceProvider);
  final nfcService = ref.watch(nfcServiceProvider);

  final geofenceSubscription = geofencingService.watchEvents().listen(
    (event) => unawaited(_handleGeofenceEvent(ref, event)),
    onError: (Object error, StackTrace stackTrace) {},
  );
  final nfcSubscription = nfcService.watchEvents().listen(
    (event) => unawaited(_handleNfcEvent(ref, event)),
    onError: (Object error, StackTrace stackTrace) {},
  );

  unawaited(_syncGeofenceTargets(ref, ref.read(activeGeofenceTargetsProvider)));
  ref.listen<List<GeofenceTarget>>(activeGeofenceTargetsProvider, (
    previous,
    next,
  ) {
    unawaited(_syncGeofenceTargets(ref, next));
  });

  final resolvedRole = ref.read(resolvedRoleProvider);
  if (resolvedRole != AppRole.staff) {
    unawaited(nfcService.stopVerificationSession());
    ref.invalidate(nfcStatusProvider);
  }
  ref.listen<AppRole?>(resolvedRoleProvider, (previous, next) {
    if (next != AppRole.staff) {
      unawaited(nfcService.stopVerificationSession());
      ref.invalidate(nfcStatusProvider);
    }
  });

  ref.onDispose(() {
    geofenceSubscription.cancel();
    nfcSubscription.cancel();
  });
});

final deviceActionControllerProvider =
    AsyncNotifierProvider<DeviceActionController, void>(
      DeviceActionController.new,
    );

class DeviceActionController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> requestGeofencePermission() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(geofencingServiceProvider).requestPermission();
      ref.invalidate(geofencingStatusProvider);
    });
  }

  Future<void> refreshGeofencingStatus() async {
    ref.invalidate(geofencingStatusProvider);
  }

  Future<void> refreshNfcStatus() async {
    ref.invalidate(nfcStatusProvider);
  }

  Future<void> simulateApproaching(GeofenceTarget target) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(geofencingServiceProvider).simulateEnter(target);
    });
  }

  Future<void> startNfcVerificationSession(NfcVerificationTarget target) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(nfcServiceProvider).startVerificationSession(target);
      ref.invalidate(nfcStatusProvider);
    });
  }

  Future<void> stopNfcVerificationSession() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(nfcServiceProvider).stopVerificationSession();
      ref.invalidate(nfcStatusProvider);
    });
  }

  Future<void> simulateVerified(NfcVerificationTarget target) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(nfcServiceProvider).simulateScan(target);
    });
  }

  Future<void> resetQueueState(String studentId) async {
    final queueEntry = ref
        .read(queueEntriesStreamProvider)
        .asData
        ?.value
        .where((entry) => entry.studentId == studentId)
        .firstOrNull;
    if (queueEntry == null) {
      throw StateError('No queue entry was found for $studentId.');
    }

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(workflowActionControllerProvider.notifier)
          .resetQueueState(queueEntry);
    });
  }
}

Future<void> _syncGeofenceTargets(Ref ref, List<GeofenceTarget> targets) async {
  try {
    final service = ref.read(geofencingServiceProvider);
    if (targets.isEmpty) {
      await service.clearTargets();
    } else {
      await service.syncTargets(targets);
    }
  } catch (_) {
    // Platform services stay best-effort so mock mode and tests remain safe.
  } finally {
    ref.invalidate(geofencingStatusProvider);
  }
}

Future<void> _handleGeofenceEvent(Ref ref, GeofenceTriggerEvent event) async {
  final role = ref.read(resolvedRoleProvider);
  if (role != AppRole.parent) {
    return;
  }

  final queueEntries =
      ref.read(queueEntriesStreamProvider).asData?.value ?? const [];
  final queueEntry = _findQueueEntry(
    queueEntries,
    studentId: event.studentId,
    guardianId: event.guardianId,
  );
  if (queueEntry == null || !queueEntry.canMarkApproaching) {
    return;
  }

  await ref
      .read(workflowActionControllerProvider.notifier)
      .markApproachingFromDevice(
        queueEntry,
        source: PickupEventSource.geofence,
        actorName: event.isSimulated
            ? 'Debug geofence simulator'
            : 'Android geofence',
        notes: event.isSimulated
            ? 'Approaching simulated from debug controls.'
            : 'Guardian entered the configured school geofence.',
      );
}

Future<void> _handleNfcEvent(Ref ref, NfcVerificationEvent event) async {
  final role = ref.read(resolvedRoleProvider);
  if (role != AppRole.staff) {
    return;
  }

  final queueEntries =
      ref.read(queueEntriesStreamProvider).asData?.value ?? const [];
  final queueEntry = _findQueueEntry(
    queueEntries,
    studentId: event.studentId,
    guardianId: event.guardianId,
  );
  if (queueEntry == null || !queueEntry.canVerify) {
    return;
  }

  await ref
      .read(workflowActionControllerProvider.notifier)
      .verifyPickup(
        queueEntry,
        source: PickupEventSource.nfc,
        actorName: event.isSimulated ? 'Debug NFC simulator' : 'Android NFC',
        notes: event.isSimulated
            ? 'Verified from debug NFC simulation.'
            : 'Verified on-site after NFC tag scan ${event.tagId}.',
      );
  ref.invalidate(nfcStatusProvider);
}

T? _firstOrNull<T>(Iterable<T> items) => items.isEmpty ? null : items.first;

PickupQueueEntry? _findQueueEntry(
  List<PickupQueueEntry> queueEntries, {
  required String studentId,
  required String guardianId,
}) {
  return _firstOrNull(
        queueEntries.where(
          (entry) =>
              entry.studentId == studentId && entry.guardianId == guardianId,
        ),
      ) ??
      _firstOrNull(queueEntries.where((entry) => entry.studentId == studentId));
}

extension _FirstOrNullExtension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
