enum PresenceState {
  queued(label: 'Queued', detail: 'Awaiting guardian arrival signal.'),
  approaching(
    label: 'Approaching',
    detail: 'Guardian entered the school geofence.',
  ),
  verified(label: 'Verified', detail: 'Guardian verified on-site by NFC.');

  const PresenceState({required this.label, required this.detail});

  final String label;
  final String detail;
}
