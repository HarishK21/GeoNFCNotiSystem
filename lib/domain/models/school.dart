class School {
  const School({
    required this.id,
    required this.name,
    required this.timezone,
    required this.pickupZones,
  });

  final String id;
  final String name;
  final String timezone;
  final List<String> pickupZones;

  factory School.fromMap(Map<String, dynamic> map, {String? id}) {
    return School(
      id: id ?? map['id'] as String,
      name: map['name'] as String,
      timezone: map['timezone'] as String,
      pickupZones: List<String>.from(
        map['pickupZones'] as List<dynamic>? ?? [],
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'timezone': timezone,
      'pickupZones': pickupZones,
    };
  }
}
