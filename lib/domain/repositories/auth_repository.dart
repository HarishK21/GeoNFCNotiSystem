abstract class AuthRepository {
  Stream<String?> watchCurrentUserId();
  String? getCurrentUserId();
}
