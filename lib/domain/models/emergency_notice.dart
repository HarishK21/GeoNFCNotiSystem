enum EmergencySeverity { advisory, warning, critical }

class EmergencyNotice {
  const EmergencyNotice({
    required this.id,
    required this.schoolId,
    required this.title,
    required this.body,
    required this.severity,
    required this.sentAt,
    required this.isActive,
  });

  final String id;
  final String schoolId;
  final String title;
  final String body;
  final EmergencySeverity severity;
  final DateTime sentAt;
  final bool isActive;

  factory EmergencyNotice.fromMap(Map<String, dynamic> map, {String? id}) {
    return EmergencyNotice(
      id: id ?? map['id'] as String,
      schoolId: map['schoolId'] as String,
      title: map['title'] as String,
      body: map['body'] as String,
      severity: EmergencySeverity.values.firstWhere(
        (value) => value.name == map['severity'],
        orElse: () => EmergencySeverity.warning,
      ),
      sentAt: DateTime.parse(map['sentAt'] as String),
      isActive: map['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'schoolId': schoolId,
      'title': title,
      'body': body,
      'severity': severity.name,
      'sentAt': sentAt.toIso8601String(),
      'isActive': isActive,
    };
  }
}
