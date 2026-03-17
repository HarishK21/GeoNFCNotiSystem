import '../models/pickup_event.dart';

abstract class PickupEventRepository {
  Stream<List<PickupEvent>> watchPickupEvents(String schoolId);
}
