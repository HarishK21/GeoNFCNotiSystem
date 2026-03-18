enum PushNotificationType {
  guardianApproaching,
  guardianVerified,
  releaseCompleted,
  emergencyNotice,
}

enum PushNotificationStatus { queued, sent, failed }

class PushNotificationJob {
  const PushNotificationJob({
    required this.id,
    required this.schoolId,
    required this.type,
    required this.audienceTopic,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.status,
    required this.payload,
  });

  final String id;
  final String schoolId;
  final PushNotificationType type;
  final String audienceTopic;
  final String title;
  final String body;
  final DateTime createdAt;
  final PushNotificationStatus status;
  final Map<String, dynamic> payload;

  factory PushNotificationJob.fromMap(Map<String, dynamic> map, {String? id}) {
    return PushNotificationJob(
      id: id ?? map['id'] as String,
      schoolId: map['schoolId'] as String,
      type: PushNotificationType.values.firstWhere(
        (value) => value.name == map['type'],
        orElse: () => PushNotificationType.guardianApproaching,
      ),
      audienceTopic: map['audienceTopic'] as String,
      title: map['title'] as String,
      body: map['body'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      status: PushNotificationStatus.values.firstWhere(
        (value) => value.name == map['status'],
        orElse: () => PushNotificationStatus.queued,
      ),
      payload: Map<String, dynamic>.from(
        map['payload'] as Map<dynamic, dynamic>? ?? const {},
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'schoolId': schoolId,
      'type': type.name,
      'audienceTopic': audienceTopic,
      'title': title,
      'body': body,
      'createdAt': createdAt.toIso8601String(),
      'status': status.name,
      'payload': payload,
    };
  }
}
