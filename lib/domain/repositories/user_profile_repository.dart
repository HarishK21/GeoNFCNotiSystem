import '../models/user_profile.dart';

abstract class UserProfileRepository {
  Stream<UserProfile?> watchProfile(String uid);
}
