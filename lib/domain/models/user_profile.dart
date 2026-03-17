import '../../core/models/app_role.dart';

class UserProfile {
  const UserProfile({
    required this.uid,
    required this.role,
    required this.schoolId,
    required this.displayName,
    required this.email,
    this.phone,
    this.linkedGuardianId,
  });

  final String uid;
  final AppRole role;
  final String schoolId;
  final String displayName;
  final String email;
  final String? phone;
  final String? linkedGuardianId;

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      uid: map['uid'] as String,
      role: AppRole.fromStorage(map['role'] as String? ?? 'parent'),
      schoolId: map['schoolId'] as String,
      displayName: map['displayName'] as String,
      email: map['email'] as String,
      phone: map['phone'] as String?,
      linkedGuardianId: map['linkedGuardianId'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'role': role.name,
      'schoolId': schoolId,
      'displayName': displayName,
      'email': email,
      'phone': phone,
      'linkedGuardianId': linkedGuardianId,
    };
  }
}
