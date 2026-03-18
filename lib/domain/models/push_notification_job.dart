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
    this.attemptCount = 0,
    this.lastAttemptAt,
    this.deliveredAt,
    this.lastError,
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
  final int attemptCount;
  final DateTime? lastAttemptAt;
  final DateTime? deliveredAt;
  final String? lastError;

  PushNotificationJob copyWith({
    String? id,
    String? schoolId,
    PushNotificationType? type,
    String? audienceTopic,
    String? title,
    String? body,
    DateTime? createdAt,
    PushNotificationStatus? status,
    Map<String, dynamic>? payload,
    int? attemptCount,
    DateTime? lastAttemptAt,
    DateTime? deliveredAt,
    String? lastError,
    bool clearLastAttemptAt = false,
    bool clearDeliveredAt = false,
    bool clearLastError = false,
  }) {
    return PushNotificationJob(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      type: type ?? this.type,
      audienceTopic: audienceTopic ?? this.audienceTopic,
      title: title ?? this.title,
      body: body ?? this.body,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      payload: payload ?? this.payload,
      attemptCount: attemptCount ?? this.attemptCount,
      lastAttemptAt: clearLastAttemptAt
          ? null
          : (lastAttemptAt ?? this.lastAttemptAt),
      deliveredAt: clearDeliveredAt ? null : (deliveredAt ?? this.deliveredAt),
      lastError: clearLastError ? null : (lastError ?? this.lastError),
    );
  }

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
      attemptCount: map['attemptCount'] as int? ?? 0,
      lastAttemptAt: map['lastAttemptAt'] == null
          ? null
          : DateTime.parse(map['lastAttemptAt'] as String),
      deliveredAt: map['deliveredAt'] == null
          ? null
          : DateTime.parse(map['deliveredAt'] as String),
      lastError: map['lastError'] as String?,
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
      'attemptCount': attemptCount,
      'lastAttemptAt': lastAttemptAt?.toIso8601String(),
      'deliveredAt': deliveredAt?.toIso8601String(),
      'lastError': lastError,
    };
  }
}
