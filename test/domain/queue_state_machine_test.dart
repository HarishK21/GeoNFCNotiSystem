import 'package:flutter_test/flutter_test.dart';

import 'package:geo_tap_guardian/domain/models/pickup_event.dart';
import 'package:geo_tap_guardian/domain/services/queue_state_machine.dart';

void main() {
  const machine = QueueStateMachine();

  test('allows the expected pickup progression', () {
    expect(
      machine.canTransition(
        PickupEventType.pending,
        PickupEventType.approaching,
      ),
      isTrue,
    );
    expect(
      machine.canTransition(
        PickupEventType.approaching,
        PickupEventType.verified,
      ),
      isTrue,
    );
    expect(
      machine.canTransition(PickupEventType.verified, PickupEventType.released),
      isTrue,
    );
  });

  test('rejects invalid pickup transitions', () {
    expect(
      machine.validateTransition(
        PickupEventType.pending,
        PickupEventType.verified,
      ),
      isNotNull,
    );
    expect(
      machine.validateTransition(
        PickupEventType.released,
        PickupEventType.approaching,
      ),
      isNotNull,
    );
  });
}
