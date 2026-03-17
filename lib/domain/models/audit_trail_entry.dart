class AuditTrailEntry {
  const AuditTrailEntry({
    required this.id,
    required this.schoolId,
    required this.studentName,
    required this.action,
    required this.actorName,
    required this.occurredAt,
    required this.notes,
  });

  final String id;
  final String schoolId;
  final String studentName;
  final String action;
  final String actorName;
  final DateTime occurredAt;
  final String notes;

  factory AuditTrailEntry.fromMap(Map<String, dynamic> map, {String? id}) {
    return AuditTrailEntry(
      id: id ?? map['id'] as String,
      schoolId: map['schoolId'] as String,
      studentName: map['studentName'] as String,
      action: map['action'] as String,
      actorName: map['actorName'] as String,
      occurredAt: DateTime.parse(map['occurredAt'] as String),
      notes: map['notes'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'schoolId': schoolId,
      'studentName': studentName,
      'action': action,
      'actorName': actorName,
      'occurredAt': occurredAt.toIso8601String(),
      'notes': notes,
    };
  }
}
