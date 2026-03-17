enum PickupEventType { pending, approaching, verified, released }

enum PickupEventSource { manual, geofence, nfc }

class PickupEvent {
  const PickupEvent({
    required this.id,
    required this.schoolId,
    required this.studentId,
    required this.guardianId,
    required this.type,
    required this.source,
    required this.pickupZone,
    required this.occurredAt,
    this.actorName,
    this.notes,
  });

  final String id;
  final String schoolId;
  final String studentId;
  final String guardianId;
  final PickupEventType type;
  final PickupEventSource source;
  final String pickupZone;
  final DateTime occurredAt;
  final String? actorName;
  final String? notes;

  bool get isNfcVerified =>
      type == PickupEventType.verified || type == PickupEventType.released;

  factory PickupEvent.fromMap(Map<String, dynamic> map, {String? id}) {
    return PickupEvent(
      id: id ?? map['id'] as String,
      schoolId: map['schoolId'] as String,
      studentId: map['studentId'] as String,
      guardianId: map['guardianId'] as String,
      type: PickupEventType.values.firstWhere(
        (value) => value.name == map['type'],
        orElse: () => PickupEventType.pending,
      ),
      source: PickupEventSource.values.firstWhere(
        (value) => value.name == map['source'],
        orElse: () => PickupEventSource.manual,
      ),
      pickupZone: map['pickupZone'] as String,
      occurredAt: DateTime.parse(map['occurredAt'] as String),
      actorName: map['actorName'] as String?,
      notes: map['notes'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'schoolId': schoolId,
      'studentId': studentId,
      'guardianId': guardianId,
      'type': type.name,
      'source': source.name,
      'pickupZone': pickupZone,
      'occurredAt': occurredAt.toIso8601String(),
      'actorName': actorName,
      'notes': notes,
    };
  }
}
