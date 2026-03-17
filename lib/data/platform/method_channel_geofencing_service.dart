import 'package:flutter/services.dart';

import '../../domain/models/geofence_target.dart';
import '../../domain/models/geofence_trigger_event.dart';
import '../../domain/models/geofencing_status.dart';
import '../../domain/services/geofencing_service.dart';

class MethodChannelGeofencingService implements GeofencingService {
  static const _methodChannel = MethodChannel(
    'geo_tap_guardian/geofencing/methods',
  );
  static const _eventChannel = EventChannel(
    'geo_tap_guardian/geofencing/events',
  );

  Stream<GeofenceTriggerEvent>? _events;

  @override
  Stream<GeofenceTriggerEvent> watchEvents() {
    _events ??= _eventChannel.receiveBroadcastStream().map((event) {
      return GeofenceTriggerEvent.fromMap(
        Map<String, dynamic>.from(event as Map),
      );
    });
    return _events!;
  }

  @override
  Future<GeofencingStatus> getStatus() async {
    try {
      final result = await _methodChannel.invokeMethod<Map<Object?, Object?>>(
        'getStatus',
      );
      if (result == null) {
        return const GeofencingStatus.unsupported();
      }
      return GeofencingStatus.fromMap(Map<String, dynamic>.from(result));
    } on MissingPluginException {
      return const GeofencingStatus.unsupported();
    }
  }

  @override
  Future<void> requestPermission() async {
    try {
      await _methodChannel.invokeMethod<void>('requestPermission');
    } on MissingPluginException {
      return;
    }
  }

  @override
  Future<void> syncTargets(List<GeofenceTarget> targets) async {
    try {
      await _methodChannel.invokeMethod<void>('syncTargets', {
        'targets': targets
            .map((target) => target.toMap())
            .toList(growable: false),
      });
    } on MissingPluginException {
      return;
    }
  }

  @override
  Future<void> clearTargets() async {
    try {
      await _methodChannel.invokeMethod<void>('clearTargets');
    } on MissingPluginException {
      return;
    }
  }

  @override
  Future<void> simulateEnter(GeofenceTarget target) async {
    try {
      await _methodChannel.invokeMethod<void>('simulateEnter', target.toMap());
    } on MissingPluginException {
      return;
    }
  }
}
