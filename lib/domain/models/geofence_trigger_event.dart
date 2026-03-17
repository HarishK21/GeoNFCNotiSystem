class GeofenceTriggerEvent {
  const GeofenceTriggerEvent({
    required this.targetId,
    required this.schoolId,
    required this.studentId,
    required this.guardianId,
    required this.studentName,
    required this.pickupZone,
    required this.occurredAt,
    required this.isSimulated,
  });

  final String targetId;
  final String schoolId;
  final String studentId;
  final String guardianId;
  final String studentName;
  final String pickupZone;
  final DateTime occurredAt;
  final bool isSimulated;

  factory GeofenceTriggerEvent.fromMap(Map<String, dynamic> map) {
    return GeofenceTriggerEvent(
      targetId: map['targetId'] as String,
      schoolId: map['schoolId'] as String,
      studentId: map['studentId'] as String,
      guardianId: map['guardianId'] as String,
      studentName: map['studentName'] as String? ?? map['studentId'] as String,
      pickupZone: map['pickupZone'] as String? ?? 'Pickup Zone',
      occurredAt: DateTime.fromMillisecondsSinceEpoch(
        map['occurredAtEpochMs'] as int,
      ),
      isSimulated: map['isSimulated'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'targetId': targetId,
      'schoolId': schoolId,
      'studentId': studentId,
      'guardianId': guardianId,
      'studentName': studentName,
      'pickupZone': pickupZone,
      'occurredAtEpochMs': occurredAt.millisecondsSinceEpoch,
      'isSimulated': isSimulated,
    };
  }
}
