class Guardian {
  const Guardian({
    required this.id,
    required this.schoolId,
    required this.displayName,
    required this.email,
    required this.phone,
    required this.studentIds,
  });

  final String id;
  final String schoolId;
  final String displayName;
  final String email;
  final String phone;
  final List<String> studentIds;

  factory Guardian.fromMap(Map<String, dynamic> map, {String? id}) {
    return Guardian(
      id: id ?? map['id'] as String,
      schoolId: map['schoolId'] as String,
      displayName: map['displayName'] as String,
      email: map['email'] as String,
      phone: map['phone'] as String,
      studentIds: List<String>.from(map['studentIds'] as List<dynamic>? ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'schoolId': schoolId,
      'displayName': displayName,
      'email': email,
      'phone': phone,
      'studentIds': studentIds,
    };
  }
}
