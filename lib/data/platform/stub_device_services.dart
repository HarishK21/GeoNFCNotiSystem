import 'dart:async';

import '../../domain/models/geofence_target.dart';
import '../../domain/models/geofence_trigger_event.dart';
import '../../domain/models/geofencing_status.dart';
import '../../domain/models/nfc_status.dart';
import '../../domain/models/nfc_verification_event.dart';
import '../../domain/models/nfc_verification_target.dart';
import '../../domain/services/geofencing_service.dart';
import '../../domain/services/nfc_service.dart';

class StubGeofencingService implements GeofencingService {
  final _controller = StreamController<GeofenceTriggerEvent>.broadcast();
  var _targets = <GeofenceTarget>[];

  @override
  Future<void> clearTargets() async {
    _targets = <GeofenceTarget>[];
  }

  @override
  Future<GeofencingStatus> getStatus() async {
    return GeofencingStatus(
      supported: false,
      permissionGranted: false,
      locationServicesEnabled: false,
      activeTargetCount: _targets.length,
      detail:
          'Using a compile-safe geofencing stub on this platform. Debug simulation still works.',
    );
  }

  @override
  Future<void> requestPermission() async {}

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
    _targets = List<GeofenceTarget>.from(targets);
  }

  @override
  Stream<GeofenceTriggerEvent> watchEvents() {
    return _controller.stream;
  }
}

class StubNfcService implements NfcService {
  final _controller = StreamController<NfcVerificationEvent>.broadcast();
  NfcVerificationTarget? _target;
  var _listening = false;

  @override
  Future<NfcStatus> getStatus() async {
    return NfcStatus(
      supported: false,
      enabled: false,
      listening: _listening,
      targetStudentId: _target?.studentId,
      targetLabel: _target?.studentName,
      detail:
          'Using a compile-safe NFC stub on this platform. Debug simulation still works.',
    );
  }

  @override
  Future<void> simulateScan(NfcVerificationTarget target) async {
    _controller.add(
      NfcVerificationEvent(
        schoolId: target.schoolId,
        studentId: target.studentId,
        guardianId: target.guardianId,
        studentName: target.studentName,
        tagId: 'debug-stub-tag',
        occurredAt: DateTime.now(),
        isSimulated: true,
      ),
    );
  }

  @override
  Future<void> startVerificationSession(NfcVerificationTarget target) async {
    _target = target;
    _listening = true;
  }

  @override
  Future<void> stopVerificationSession() async {
    _target = null;
    _listening = false;
  }

  @override
  Stream<NfcVerificationEvent> watchEvents() {
    return _controller.stream;
  }
}
