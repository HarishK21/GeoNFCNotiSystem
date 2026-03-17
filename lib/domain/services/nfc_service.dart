import '../models/nfc_status.dart';
import '../models/nfc_verification_event.dart';
import '../models/nfc_verification_target.dart';

abstract class NfcService {
  Stream<NfcVerificationEvent> watchEvents();
  Future<NfcStatus> getStatus();
  Future<void> startVerificationSession(NfcVerificationTarget target);
  Future<void> stopVerificationSession();
  Future<void> simulateScan(NfcVerificationTarget target);
}
