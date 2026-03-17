class GeofencingStatus {
  const GeofencingStatus({
    required this.supported,
    required this.permissionGranted,
    required this.locationServicesEnabled,
    required this.activeTargetCount,
    required this.detail,
  });

  const GeofencingStatus.unsupported({
    this.detail = 'Android geofencing is unavailable on this platform.',
  }) : supported = false,
       permissionGranted = false,
       locationServicesEnabled = false,
       activeTargetCount = 0;

  final bool supported;
  final bool permissionGranted;
  final bool locationServicesEnabled;
  final int activeTargetCount;
  final String detail;

  bool get canMonitor =>
      supported && permissionGranted && locationServicesEnabled;

  factory GeofencingStatus.fromMap(Map<String, dynamic> map) {
    return GeofencingStatus(
      supported: map['supported'] as bool? ?? false,
      permissionGranted: map['permissionGranted'] as bool? ?? false,
      locationServicesEnabled: map['locationServicesEnabled'] as bool? ?? false,
      activeTargetCount: map['activeTargetCount'] as int? ?? 0,
      detail:
          map['detail'] as String? ??
          'Geofencing status is available on Android only.',
    );
  }
}
