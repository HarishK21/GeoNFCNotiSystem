class PickupPermission {
  const PickupPermission({
    required this.id,
    required this.schoolId,
    required this.studentId,
    required this.guardianId,
    required this.delegateName,
    required this.delegatePhone,
    required this.relationship,
    required this.approvedBy,
    required this.startsAt,
    required this.endsAt,
    required this.isActive,
  });

  final String id;
  final String schoolId;
  final String studentId;
  final String guardianId;
  final String delegateName;
  final String delegatePhone;
  final String relationship;
  final String approvedBy;
  final DateTime startsAt;
  final DateTime endsAt;
  final bool isActive;

  bool isActiveAt(DateTime value) {
    if (!isActive) {
      return false;
    }
    return !value.isBefore(startsAt) && !value.isAfter(endsAt);
  }

  factory PickupPermission.fromMap(Map<String, dynamic> map, {String? id}) {
    return PickupPermission(
      id: id ?? map['id'] as String,
      schoolId: map['schoolId'] as String,
      studentId: map['studentId'] as String,
      guardianId: map['guardianId'] as String,
      delegateName: map['delegateName'] as String,
      delegatePhone: map['delegatePhone'] as String? ?? '',
      relationship: map['relationship'] as String,
      approvedBy: map['approvedBy'] as String? ?? 'system',
      startsAt: DateTime.parse(map['startsAt'] as String),
      endsAt: DateTime.parse(map['endsAt'] as String),
      isActive: map['isActive'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'schoolId': schoolId,
      'studentId': studentId,
      'guardianId': guardianId,
      'delegateName': delegateName,
      'delegatePhone': delegatePhone,
      'relationship': relationship,
      'approvedBy': approvedBy,
      'startsAt': startsAt.toIso8601String(),
      'endsAt': endsAt.toIso8601String(),
      'isActive': isActive,
    };
  }
}
