import '../models/release_event.dart';

abstract class ReleaseEventRepository {
  Stream<List<ReleaseEvent>> watchReleaseEvents(String schoolId);
}
