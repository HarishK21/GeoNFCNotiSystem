abstract class NotificationSubscriptionService {
  Future<void> syncTopics({
    required Set<String> desiredTopics,
    Set<String> previousTopics = const {},
  });
}
