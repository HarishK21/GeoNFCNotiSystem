import '../../core/models/app_role.dart';

abstract class AuthRepository {
  Stream<String?> watchCurrentUserId();
  String? getCurrentUserId();
  bool get supportsCredentialSignIn;
  bool get supportsDemoSignIn;
  Future<void> signInWithEmailPassword({
    required String email,
    required String password,
  });
  Future<void> signInAsDemoRole(AppRole role);
  Future<void> signOut();
}
