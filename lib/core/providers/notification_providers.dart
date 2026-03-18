import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_environment.dart';
import '../../domain/services/notification_subscription_service.dart';
import '../../domain/services/notification_topic_planner.dart';
import '../../domain/models/user_profile.dart';
import '../../data/firebase/firebase_notification_subscription_service.dart';
import '../../data/mock/mock_notification_subscription_service.dart';
import 'flow_providers.dart';
import 'repository_providers.dart';

final notificationTopicPlannerProvider = Provider<NotificationTopicPlanner>((
  ref,
) {
  return const NotificationTopicPlanner();
});

final notificationSubscriptionServiceProvider =
    Provider<NotificationSubscriptionService>((ref) {
      final environment = ref.watch(appEnvironmentProvider);
      if (environment.dataSource == AppDataSource.firebase &&
          environment.firebaseConfigured) {
        return FirebaseNotificationSubscriptionService(
          FirebaseMessaging.instance,
        );
      }
      return const MockNotificationSubscriptionService();
    });

final notificationSubscriptionBootstrapProvider = Provider<void>((ref) {
  final environment = ref.watch(appEnvironmentProvider);
  if (environment.dataSource != AppDataSource.firebase ||
      !environment.firebaseConfigured) {
    return;
  }

  final planner = ref.watch(notificationTopicPlannerProvider);
  final service = ref.watch(notificationSubscriptionServiceProvider);
  var lastTopics = <String>{};
  var lastProfileKey = '';

  Future<void> syncForProfile(UserProfile? profile) async {
    final nextTopics = profile == null
        ? <String>{}
        : planner.topicsForProfile(profile);
    final nextKey = profile == null
        ? ''
        : '${profile.uid}:${profile.role.name}:${profile.schoolId}:${profile.linkedGuardianId ?? ''}';

    if (nextKey == lastProfileKey && _sameTopics(nextTopics, lastTopics)) {
      return;
    }

    await service.syncTopics(
      desiredTopics: nextTopics,
      previousTopics: lastTopics,
    );
    lastTopics = nextTopics;
    lastProfileKey = nextKey;
  }

  unawaited(syncForProfile(ref.read(currentUserProfileProvider)));
  ref.listen(currentUserProfileStreamProvider, (previous, next) {
    unawaited(syncForProfile(next.asData?.value));
  });
});

bool _sameTopics(Set<String> left, Set<String> right) {
  if (left.length != right.length) {
    return false;
  }
  for (final topic in left) {
    if (!right.contains(topic)) {
      return false;
    }
  }
  return true;
}
