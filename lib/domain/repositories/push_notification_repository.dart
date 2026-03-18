import '../models/push_notification_job.dart';

abstract class PushNotificationRepository {
  Stream<List<PushNotificationJob>> watchJobs(String schoolId);
  Future<void> enqueueJob(PushNotificationJob job);
}
