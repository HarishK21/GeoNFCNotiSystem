import '../../domain/models/audit_trail_entry.dart';
import '../../domain/models/emergency_notice.dart';
import '../../domain/models/guardian.dart';
import '../../domain/models/pickup_event.dart';
import '../../domain/models/pickup_permission.dart';
import '../../domain/models/pickup_queue_entry.dart';
import '../../domain/models/release_event.dart';
import '../../domain/models/school.dart';
import '../../domain/models/school_announcement.dart';
import '../../domain/models/student.dart';
import '../../domain/models/user_profile.dart';
import '../../domain/repositories/audit_repository.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/guardian_repository.dart';
import '../../domain/repositories/notice_repository.dart';
import '../../domain/repositories/pickup_event_repository.dart';
import '../../domain/repositories/pickup_permission_repository.dart';
import '../../domain/repositories/queue_repository.dart';
import '../../domain/repositories/release_event_repository.dart';
import '../../domain/repositories/school_repository.dart';
import '../../domain/repositories/student_repository.dart';
import '../../domain/repositories/user_profile_repository.dart';
import 'mock_data_store.dart';

class MockAuthRepository implements AuthRepository {
  const MockAuthRepository(this._currentUserId);

  final String _currentUserId;

  @override
  String? getCurrentUserId() => _currentUserId;

  @override
  Stream<String?> watchCurrentUserId() => Stream<String?>.value(_currentUserId);
}

class MockUserProfileRepository implements UserProfileRepository {
  const MockUserProfileRepository(this._store);

  final MockDataStore _store;

  @override
  Stream<UserProfile?> watchProfile(String uid) {
    UserProfile? profile;
    for (final item in _store.userProfiles) {
      if (item.uid == uid) {
        profile = item;
        break;
      }
    }
    return Stream<UserProfile?>.value(profile);
  }
}

class MockSchoolRepository implements SchoolRepository {
  const MockSchoolRepository(this._store);

  final MockDataStore _store;

  @override
  Future<School?> fetchSchool(String schoolId) async {
    return schoolId == _store.school.id ? _store.school : null;
  }
}

class MockStudentRepository implements StudentRepository {
  const MockStudentRepository(this._store);

  final MockDataStore _store;

  @override
  Future<List<Student>> fetchStudents(String schoolId) async {
    return _store.students
        .where((item) => item.schoolId == schoolId)
        .toList(growable: false);
  }
}

class MockGuardianRepository implements GuardianRepository {
  const MockGuardianRepository(this._store);

  final MockDataStore _store;

  @override
  Future<List<Guardian>> fetchGuardians(String schoolId) async {
    return _store.guardians
        .where((item) => item.schoolId == schoolId)
        .toList(growable: false);
  }
}

class MockPickupPermissionRepository implements PickupPermissionRepository {
  const MockPickupPermissionRepository(this._store);

  final MockDataStore _store;

  @override
  Stream<List<PickupPermission>> watchPermissions(String schoolId) {
    return Stream.value(
      _store.pickupPermissions
          .where((item) => item.schoolId == schoolId)
          .toList(growable: false),
    );
  }
}

class MockPickupEventRepository implements PickupEventRepository {
  const MockPickupEventRepository(this._store);

  final MockDataStore _store;

  @override
  Stream<List<PickupEvent>> watchPickupEvents(String schoolId) {
    return Stream.value(
      _store.pickupEvents
          .where((item) => item.schoolId == schoolId)
          .toList(growable: false),
    );
  }
}

class MockReleaseEventRepository implements ReleaseEventRepository {
  const MockReleaseEventRepository(this._store);

  final MockDataStore _store;

  @override
  Stream<List<ReleaseEvent>> watchReleaseEvents(String schoolId) {
    return Stream.value(
      _store.releaseEvents
          .where((item) => item.schoolId == schoolId)
          .toList(growable: false),
    );
  }
}

class MockNoticeRepository implements NoticeRepository {
  const MockNoticeRepository(this._store);

  final MockDataStore _store;

  @override
  Stream<List<SchoolAnnouncement>> watchAnnouncements(String schoolId) {
    return Stream.value(
      _store.announcements
          .where((item) => item.schoolId == schoolId)
          .toList(growable: false),
    );
  }

  @override
  Stream<List<EmergencyNotice>> watchEmergencyNotices(String schoolId) {
    return Stream.value(
      _store.emergencyNotices
          .where((item) => item.schoolId == schoolId)
          .toList(growable: false),
    );
  }
}

class MockQueueRepository implements QueueRepository {
  const MockQueueRepository(this._store);

  final MockDataStore _store;

  @override
  Stream<List<PickupQueueEntry>> watchQueue(String schoolId) {
    return Stream.value(
      _store.queueEntries
          .where((item) => item.schoolId == schoolId)
          .toList(growable: false),
    );
  }
}

class MockAuditRepository implements AuditRepository {
  const MockAuditRepository(this._store);

  final MockDataStore _store;

  @override
  Stream<List<AuditTrailEntry>> watchAuditTrail(String schoolId) {
    return Stream.value(
      _store.auditTrail
          .where((item) => item.schoolId == schoolId)
          .toList(growable: false),
    );
  }
}
