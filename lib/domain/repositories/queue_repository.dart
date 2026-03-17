import '../models/pickup_queue_entry.dart';

abstract class QueueRepository {
  Stream<List<PickupQueueEntry>> watchQueue(String schoolId);
}
