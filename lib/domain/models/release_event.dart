class ReleaseEvent {
  const ReleaseEvent({
    required this.id,
    required this.schoolId,
    required this.queueEntryId,
    required this.studentId,
    required this.guardianId,
    required this.staffId,
    required this.staffName,
    required this.releasedAt,
    required this.verificationMethod,
    this.notes,
  });

  final String id;
  final String schoolId;
  final String queueEntryId;
  final String studentId;
  final String guardianId;
  final String staffId;
  final String staffName;
  final DateTime releasedAt;
  final String verificationMethod;
  final String? notes;

  factory ReleaseEvent.fromMap(Map<String, dynamic> map, {String? id}) {
    return ReleaseEvent(
      id: id ?? map['id'] as String,
      schoolId: map['schoolId'] as String,
      queueEntryId: map['queueEntryId'] as String? ?? map['id'] as String,
      studentId: map['studentId'] as String,
      guardianId: map['guardianId'] as String,
      staffId: map['staffId'] as String,
      staffName: map['staffName'] as String,
      releasedAt: DateTime.parse(map['releasedAt'] as String),
      verificationMethod: map['verificationMethod'] as String,
      notes: map['notes'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'schoolId': schoolId,
      'queueEntryId': queueEntryId,
      'studentId': studentId,
      'guardianId': guardianId,
      'staffId': staffId,
      'staffName': staffName,
      'releasedAt': releasedAt.toIso8601String(),
      'verificationMethod': verificationMethod,
      'notes': notes,
    };
  }
}
