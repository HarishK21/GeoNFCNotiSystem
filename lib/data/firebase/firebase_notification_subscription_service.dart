import 'package:firebase_messaging/firebase_messaging.dart';

import '../../domain/services/notification_subscription_service.dart';

class FirebaseNotificationSubscriptionService
    implements NotificationSubscriptionService {
  const FirebaseNotificationSubscriptionService(this._messaging);

  final FirebaseMessaging _messaging;

  @override
  Future<void> syncTopics({
    required Set<String> desiredTopics,
    Set<String> previousTopics = const {},
  }) async {
    await _messaging.requestPermission();

    final topicsToRemove = previousTopics.difference(desiredTopics);
    final topicsToAdd = desiredTopics.difference(previousTopics);

    for (final topic in topicsToRemove) {
      await _messaging.unsubscribeFromTopic(topic);
    }

    for (final topic in topicsToAdd) {
      await _messaging.subscribeToTopic(topic);
    }
  }
}
