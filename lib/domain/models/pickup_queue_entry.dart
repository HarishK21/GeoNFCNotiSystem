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
    this.exceptionFlag,
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
  final String? exceptionFlag;

  bool get canMarkApproaching => eventType == PickupEventType.pending;
  bool get canVerify => eventType == PickupEventType.approaching;
  bool get canRelease => eventType == PickupEventType.verified;
  bool get isReleased => eventType == PickupEventType.released;
  bool get hasException => exceptionFlag != null && exceptionFlag!.isNotEmpty;

  PickupQueueEntry copyWith({
    String? id,
    String? schoolId,
    String? studentId,
    String? studentName,
    String? guardianId,
    String? guardianName,
    String? homeroom,
    String? pickupZone,
    String? etaLabel,
    PickupEventType? eventType,
    bool? isNfcVerified,
    String? exceptionFlag,
    bool clearExceptionFlag = false,
  }) {
    return PickupQueueEntry(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      guardianId: guardianId ?? this.guardianId,
      guardianName: guardianName ?? this.guardianName,
      homeroom: homeroom ?? this.homeroom,
      pickupZone: pickupZone ?? this.pickupZone,
      etaLabel: etaLabel ?? this.etaLabel,
      eventType: eventType ?? this.eventType,
      isNfcVerified: isNfcVerified ?? this.isNfcVerified,
      exceptionFlag: clearExceptionFlag
          ? null
          : (exceptionFlag ?? this.exceptionFlag),
    );
  }

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
        orElse: () => PickupEventType.pending,
      ),
      isNfcVerified: map['isNfcVerified'] as bool? ?? false,
      exceptionFlag: map['exceptionFlag'] as String?,
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
      'exceptionFlag': exceptionFlag,
    };
  }
}
