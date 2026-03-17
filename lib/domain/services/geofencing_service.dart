import '../models/geofence_target.dart';
import '../models/geofence_trigger_event.dart';
import '../models/geofencing_status.dart';

abstract class GeofencingService {
  Stream<GeofenceTriggerEvent> watchEvents();
  Future<GeofencingStatus> getStatus();
  Future<void> requestPermission();
  Future<void> syncTargets(List<GeofenceTarget> targets);
  Future<void> clearTargets();
  Future<void> simulateEnter(GeofenceTarget target);
}
