import 'package:flutter/services.dart';

import '../../domain/models/nfc_status.dart';
import '../../domain/models/nfc_verification_event.dart';
import '../../domain/models/nfc_verification_target.dart';
import '../../domain/services/nfc_service.dart';

class MethodChannelNfcService implements NfcService {
  static const _methodChannel = MethodChannel('geo_tap_guardian/nfc/methods');
  static const _eventChannel = EventChannel('geo_tap_guardian/nfc/events');

  Stream<NfcVerificationEvent>? _events;

  @override
  Stream<NfcVerificationEvent> watchEvents() {
    _events ??= _eventChannel.receiveBroadcastStream().map((event) {
      return NfcVerificationEvent.fromMap(
        Map<String, dynamic>.from(event as Map),
      );
    });
    return _events!;
  }

  @override
  Future<NfcStatus> getStatus() async {
    try {
      final result = await _methodChannel.invokeMethod<Map<Object?, Object?>>(
        'getStatus',
      );
      if (result == null) {
        return const NfcStatus.unsupported();
      }
      return NfcStatus.fromMap(Map<String, dynamic>.from(result));
    } on MissingPluginException {
      return const NfcStatus.unsupported();
    }
  }

  @override
  Future<void> startVerificationSession(NfcVerificationTarget target) async {
    try {
      await _methodChannel.invokeMethod<void>(
        'startVerificationSession',
        target.toMap(),
      );
    } on MissingPluginException {
      return;
    }
  }

  @override
  Future<void> stopVerificationSession() async {
    try {
      await _methodChannel.invokeMethod<void>('stopVerificationSession');
    } on MissingPluginException {
      return;
    }
  }

  @override
  Future<void> simulateScan(NfcVerificationTarget target) async {
    try {
      await _methodChannel.invokeMethod<void>('simulateScan', target.toMap());
    } on MissingPluginException {
      return;
    }
  }
}
