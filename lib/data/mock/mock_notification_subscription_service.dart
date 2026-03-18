import '../../domain/services/notification_subscription_service.dart';

class MockNotificationSubscriptionService
    implements NotificationSubscriptionService {
  const MockNotificationSubscriptionService();

  @override
  Future<void> syncTopics({
    required Set<String> desiredTopics,
    Set<String> previousTopics = const {},
  }) async {}
}
