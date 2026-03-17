class AuditEvent {
  const AuditEvent({
    required this.studentName,
    required this.action,
    required this.actorName,
    required this.timestampLabel,
    required this.notes,
  });

  final String studentName;
  final String action;
  final String actorName;
  final String timestampLabel;
  final String notes;
}
