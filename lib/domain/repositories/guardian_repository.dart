import '../models/guardian.dart';

abstract class GuardianRepository {
  Future<List<Guardian>> fetchGuardians(String schoolId);
}
