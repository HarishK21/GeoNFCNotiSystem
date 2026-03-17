class DeviceGeofenceDefaults {
  const DeviceGeofenceDefaults({
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
  });

  final double latitude;
  final double longitude;
  final double radiusMeters;
}

DeviceGeofenceDefaults geofenceDefaultsForSchool(String schoolId) {
  switch (schoolId) {
    case 'school_springfield':
      return const DeviceGeofenceDefaults(
        latitude: 43.6532,
        longitude: -79.3832,
        radiusMeters: 200,
      );
    default:
      return const DeviceGeofenceDefaults(
        latitude: 43.6532,
        longitude: -79.3832,
        radiusMeters: 200,
      );
  }
}
