import 'presence_state.dart';

class PickupRequest {
  const PickupRequest({
    required this.queueEntryId,
    required this.studentId,
    required this.guardianId,
    required this.studentName,
    required this.guardianName,
    required this.homeroom,
    required this.pickupZone,
    required this.etaLabel,
    required this.presenceState,
    required this.isNfcVerified,
    this.exceptionFlag,
  });

  final String queueEntryId;
  final String studentId;
  final String guardianId;
  final String studentName;
  final String guardianName;
  final String homeroom;
  final String pickupZone;
  final String etaLabel;
  final PresenceState presenceState;
  final bool isNfcVerified;
  final String? exceptionFlag;

  bool get canRelease => presenceState == PresenceState.verified;
  bool get canVerify => presenceState == PresenceState.approaching;
  bool get canMarkApproaching => presenceState == PresenceState.pending;
  bool get isReleased => presenceState == PresenceState.released;
  bool get hasException => exceptionFlag != null && exceptionFlag!.isNotEmpty;
}
