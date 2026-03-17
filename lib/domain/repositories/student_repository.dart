import '../models/student.dart';

abstract class StudentRepository {
  Future<List<Student>> fetchStudents(String schoolId);
}
