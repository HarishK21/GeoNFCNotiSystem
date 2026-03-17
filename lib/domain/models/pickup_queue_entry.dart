import 'pickup_event.dart';

class PickupQueueEntry {
  const PickupQueueEntry({
    required this.id,
    required this.schoolId,
    required this.studentId,
    required this.studentName,
    required this.guardianId,
    required this.guardianName,
    required this.homeroom,
    required this.pickupZone,
    required this.etaLabel,
    required this.eventType,
    required this.isNfcVerified,
  });

  final String id;
  final String schoolId;
  final String studentId;
  final String studentName;
  final String guardianId;
  final String guardianName;
  final String homeroom;
  final String pickupZone;
  final String etaLabel;
  final PickupEventType eventType;
  final bool isNfcVerified;

  factory PickupQueueEntry.fromMap(Map<String, dynamic> map, {String? id}) {
    return PickupQueueEntry(
      id: id ?? map['id'] as String,
      schoolId: map['schoolId'] as String,
      studentId: map['studentId'] as String,
      studentName: map['studentName'] as String,
      guardianId: map['guardianId'] as String,
      guardianName: map['guardianName'] as String,
      homeroom: map['homeroom'] as String,
      pickupZone: map['pickupZone'] as String,
      etaLabel: map['etaLabel'] as String,
      eventType: PickupEventType.values.firstWhere(
        (value) => value.name == map['eventType'],
        orElse: () => PickupEventType.queued,
      ),
      isNfcVerified: map['isNfcVerified'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'schoolId': schoolId,
      'studentId': studentId,
      'studentName': studentName,
      'guardianId': guardianId,
      'guardianName': guardianName,
      'homeroom': homeroom,
      'pickupZone': pickupZone,
      'etaLabel': etaLabel,
      'eventType': eventType.name,
      'isNfcVerified': isNfcVerified,
    };
  }
}
