enum PresenceState {
  pending(
    label: 'Pending',
    detail: 'Pickup has been requested but is not yet approaching.',
  ),
  approaching(
    label: 'Approaching',
    detail: 'Guardian entered the school geofence.',
  ),
  verified(
    label: 'Verified',
    detail: 'Guardian verified on-site and ready for release.',
  ),
  released(label: 'Released', detail: 'Student has already been released.');

  const PresenceState({required this.label, required this.detail});

  final String label;
  final String detail;
}
