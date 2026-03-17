class NfcVerificationTarget {
  const NfcVerificationTarget({
    required this.schoolId,
    required this.studentId,
    required this.guardianId,
    required this.studentName,
    required this.guardianName,
  });

  final String schoolId;
  final String studentId;
  final String guardianId;
  final String studentName;
  final String guardianName;

  Map<String, dynamic> toMap() {
    return {
      'schoolId': schoolId,
      'studentId': studentId,
      'guardianId': guardianId,
      'studentName': studentName,
      'guardianName': guardianName,
    };
  }

  factory NfcVerificationTarget.fromMap(Map<String, dynamic> map) {
    return NfcVerificationTarget(
      schoolId: map['schoolId'] as String,
      studentId: map['studentId'] as String,
      guardianId: map['guardianId'] as String,
      studentName: map['studentName'] as String,
      guardianName: map['guardianName'] as String,
    );
  }
}
