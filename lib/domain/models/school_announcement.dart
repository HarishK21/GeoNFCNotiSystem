class SchoolAnnouncement {
  const SchoolAnnouncement({
    required this.id,
    required this.schoolId,
    required this.title,
    required this.body,
    required this.audience,
    required this.sentAt,
    required this.requiresAcknowledgement,
  });

  final String id;
  final String schoolId;
  final String title;
  final String body;
  final String audience;
  final DateTime sentAt;
  final bool requiresAcknowledgement;

  factory SchoolAnnouncement.fromMap(Map<String, dynamic> map, {String? id}) {
    return SchoolAnnouncement(
      id: id ?? map['id'] as String,
      schoolId: map['schoolId'] as String,
      title: map['title'] as String,
      body: map['body'] as String,
      audience: map['audience'] as String,
      sentAt: DateTime.parse(map['sentAt'] as String),
      requiresAcknowledgement: map['requiresAcknowledgement'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'schoolId': schoolId,
      'title': title,
      'body': body,
      'audience': audience,
      'sentAt': sentAt.toIso8601String(),
      'requiresAcknowledgement': requiresAcknowledgement,
    };
  }
}
