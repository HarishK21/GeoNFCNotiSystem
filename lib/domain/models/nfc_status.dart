class NfcStatus {
  const NfcStatus({
    required this.supported,
    required this.enabled,
    required this.listening,
    required this.targetStudentId,
    required this.targetLabel,
    required this.detail,
  });

  const NfcStatus.unsupported({
    this.detail = 'Android NFC is unavailable on this platform.',
  }) : supported = false,
       enabled = false,
       listening = false,
       targetStudentId = null,
       targetLabel = null;

  final bool supported;
  final bool enabled;
  final bool listening;
  final String? targetStudentId;
  final String? targetLabel;
  final String detail;

  factory NfcStatus.fromMap(Map<String, dynamic> map) {
    return NfcStatus(
      supported: map['supported'] as bool? ?? false,
      enabled: map['enabled'] as bool? ?? false,
      listening: map['listening'] as bool? ?? false,
      targetStudentId: map['targetStudentId'] as String?,
      targetLabel: map['targetLabel'] as String?,
      detail:
          map['detail'] as String? ??
          'NFC verification is available on Android only.',
    );
  }
}
