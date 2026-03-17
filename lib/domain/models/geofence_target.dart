class GeofenceTarget {
  const GeofenceTarget({
    required this.id,
    required this.schoolId,
    required this.studentId,
    required this.guardianId,
    required this.studentName,
    required this.pickupZone,
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
  });

  final String id;
  final String schoolId;
  final String studentId;
  final String guardianId;
  final String studentName;
  final String pickupZone;
  final double latitude;
  final double longitude;
  final double radiusMeters;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'schoolId': schoolId,
      'studentId': studentId,
      'guardianId': guardianId,
      'studentName': studentName,
      'pickupZone': pickupZone,
      'latitude': latitude,
      'longitude': longitude,
      'radiusMeters': radiusMeters,
    };
  }

  factory GeofenceTarget.fromMap(Map<String, dynamic> map) {
    return GeofenceTarget(
      id: map['id'] as String,
      schoolId: map['schoolId'] as String,
      studentId: map['studentId'] as String,
      guardianId: map['guardianId'] as String,
      studentName: map['studentName'] as String,
      pickupZone: map['pickupZone'] as String,
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      radiusMeters: (map['radiusMeters'] as num).toDouble(),
    );
  }
}
