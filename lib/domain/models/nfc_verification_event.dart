class NfcVerificationEvent {
  const NfcVerificationEvent({
    required this.schoolId,
    required this.studentId,
    required this.guardianId,
    required this.studentName,
    required this.tagId,
    required this.occurredAt,
    required this.isSimulated,
  });

  final String schoolId;
  final String studentId;
  final String guardianId;
  final String studentName;
  final String tagId;
  final DateTime occurredAt;
  final bool isSimulated;

  factory NfcVerificationEvent.fromMap(Map<String, dynamic> map) {
    return NfcVerificationEvent(
      schoolId: map['schoolId'] as String,
      studentId: map['studentId'] as String,
      guardianId: map['guardianId'] as String,
      studentName: map['studentName'] as String? ?? map['studentId'] as String,
      tagId: map['tagId'] as String? ?? 'unknown-tag',
      occurredAt: DateTime.fromMillisecondsSinceEpoch(
        map['occurredAtEpochMs'] as int,
      ),
      isSimulated: map['isSimulated'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'schoolId': schoolId,
      'studentId': studentId,
      'guardianId': guardianId,
      'studentName': studentName,
      'tagId': tagId,
      'occurredAtEpochMs': occurredAt.millisecondsSinceEpoch,
      'isSimulated': isSimulated,
    };
  }
}
