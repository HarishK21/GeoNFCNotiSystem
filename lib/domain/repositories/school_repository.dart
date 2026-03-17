import '../models/school.dart';

abstract class SchoolRepository {
  Future<School?> fetchSchool(String schoolId);
}
