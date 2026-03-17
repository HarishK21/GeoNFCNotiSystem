import '../models/pickup_event.dart';

class QueueStateMachine {
  const QueueStateMachine();

  bool canTransition(PickupEventType current, PickupEventType next) {
    return switch ((current, next)) {
      (PickupEventType.pending, PickupEventType.approaching) => true,
      (PickupEventType.approaching, PickupEventType.verified) => true,
      (PickupEventType.verified, PickupEventType.released) => true,
      _ => false,
    };
  }

  String? validateTransition(PickupEventType current, PickupEventType next) {
    if (canTransition(current, next)) {
      return null;
    }
    return 'Cannot move a queue entry from ${current.name} to ${next.name}.';
  }
}
