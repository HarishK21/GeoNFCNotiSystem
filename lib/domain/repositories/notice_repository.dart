import '../models/emergency_notice.dart';
import '../models/school_announcement.dart';

abstract class NoticeRepository {
  Stream<List<SchoolAnnouncement>> watchAnnouncements(String schoolId);
  Stream<List<EmergencyNotice>> watchEmergencyNotices(String schoolId);
}
