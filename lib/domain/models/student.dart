class Student {
  const Student({
    required this.id,
    required this.schoolId,
    required this.displayName,
    required this.gradeLevel,
    required this.homeroom,
    required this.pickupZone,
    required this.guardianIds,
  });

  final String id;
  final String schoolId;
  final String displayName;
  final String gradeLevel;
  final String homeroom;
  final String pickupZone;
  final List<String> guardianIds;

  factory Student.fromMap(Map<String, dynamic> map, {String? id}) {
    return Student(
      id: id ?? map['id'] as String,
      schoolId: map['schoolId'] as String,
      displayName: map['displayName'] as String,
      gradeLevel: map['gradeLevel'] as String,
      homeroom: map['homeroom'] as String,
      pickupZone: map['pickupZone'] as String,
      guardianIds: List<String>.from(
        map['guardianIds'] as List<dynamic>? ?? [],
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'schoolId': schoolId,
      'displayName': displayName,
      'gradeLevel': gradeLevel,
      'homeroom': homeroom,
      'pickupZone': pickupZone,
      'guardianIds': guardianIds,
    };
  }
}
