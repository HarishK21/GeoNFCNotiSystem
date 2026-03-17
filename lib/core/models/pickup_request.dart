import 'presence_state.dart';

class PickupRequest {
  const PickupRequest({
    required this.studentName,
    required this.guardianName,
    required this.homeroom,
    required this.pickupZone,
    required this.etaLabel,
    required this.presenceState,
    required this.isNfcVerified,
  });

  final String studentName;
  final String guardianName;
  final String homeroom;
  final String pickupZone;
  final String etaLabel;
  final PresenceState presenceState;
  final bool isNfcVerified;

  bool get canRelease => isNfcVerified;
}
