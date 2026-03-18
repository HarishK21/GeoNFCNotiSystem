import '../../core/models/app_role.dart';
import '../../domain/models/audit_trail_entry.dart';
import '../../domain/models/emergency_notice.dart';
import '../../domain/models/guardian.dart';
import '../../domain/models/office_approval_record.dart';
import '../../domain/models/pickup_event.dart';
import '../../domain/models/pickup_permission.dart';
import '../../domain/models/pickup_queue_entry.dart';
import '../../domain/models/push_notification_job.dart';
import '../../domain/models/release_event.dart';
import '../../domain/models/school.dart';
import '../../domain/models/school_announcement.dart';
import '../../domain/models/student.dart';
import '../../domain/models/user_profile.dart';
import '../../domain/repositories/audit_repository.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/guardian_repository.dart';
import '../../domain/repositories/notice_repository.dart';
import '../../domain/repositories/office_approval_repository.dart';
import '../../domain/repositories/pickup_event_repository.dart';
import '../../domain/repositories/pickup_permission_repository.dart';
import '../../domain/repositories/push_notification_repository.dart';
import '../../domain/repositories/queue_repository.dart';
import '../../domain/repositories/release_event_repository.dart';
import '../../domain/repositories/school_repository.dart';
import '../../domain/repositories/student_repository.dart';
import '../../domain/repositories/user_profile_repository.dart';
import 'mock_data_store.dart';

class MockAuthRepository implements AuthRepository {
  const MockAuthRepository(this._store);

  final MockDataStore _store;

  @override
  String? getCurrentUserId() => _store.currentUserId;

  @override
  bool get supportsCredentialSignIn => false;

  @override
  bool get supportsDemoSignIn => true;

  @override
  Future<void> signInAsDemoRole(AppRole role) => _store.signInAsRole(role);

  @override
  Future<void> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    throw UnsupportedError('Mock auth only supports demo sign-in.');
  }

  @override
  Future<void> signOut() => _store.signOut();

  @override
  Stream<String?> watchCurrentUserId() => _store.watchCurrentUserId();
}

class MockUserProfileRepository implements UserProfileRepository {
  const MockUserProfileRepository(this._store);

  final MockDataStore _store;

  @override
  Stream<UserProfile?> watchProfile(String uid) async* {
    yield _store.userProfiles.where((item) => item.uid == uid).firstOrNull;
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
  Future<void> createPermission(PickupPermission permission) {
    return _store.createPermission(permission);
  }

  @override
  Stream<List<PickupPermission>> watchPermissions(String schoolId) {
    return _store.watchPermissions(schoolId);
  }
}

class MockPickupEventRepository implements PickupEventRepository {
  const MockPickupEventRepository(this._store);

  final MockDataStore _store;

  @override
  Future<void> logPickupEvent(PickupEvent event) {
    return _store.logPickupEvent(event);
  }

  @override
  Stream<List<PickupEvent>> watchPickupEvents(String schoolId) {
    return _store.watchPickupEvents(schoolId);
  }
}

class MockReleaseEventRepository implements ReleaseEventRepository {
  const MockReleaseEventRepository(this._store);

  final MockDataStore _store;

  @override
  Future<void> createReleaseEvent(ReleaseEvent event) {
    return _store.createReleaseEvent(event);
  }

  @override
  Stream<List<ReleaseEvent>> watchReleaseEvents(String schoolId) {
    return _store.watchReleaseEvents(schoolId);
  }
}

class MockNoticeRepository implements NoticeRepository {
  const MockNoticeRepository(this._store);

  final MockDataStore _store;

  @override
  Stream<List<SchoolAnnouncement>> watchAnnouncements(String schoolId) {
    return _store.watchAnnouncements(schoolId);
  }

  @override
  Stream<List<EmergencyNotice>> watchEmergencyNotices(String schoolId) {
    return _store.watchEmergencyNotices(schoolId);
  }
}

class MockQueueRepository implements QueueRepository {
  const MockQueueRepository(this._store);

  final MockDataStore _store;

  @override
  Future<void> saveQueueEntry(PickupQueueEntry entry) {
    return _store.saveQueueEntry(entry);
  }

  @override
  Stream<List<PickupQueueEntry>> watchQueue(String schoolId) {
    return _store.watchQueue(schoolId);
  }
}

class MockAuditRepository implements AuditRepository {
  const MockAuditRepository(this._store);

  final MockDataStore _store;

  @override
  Future<void> appendAuditEntry(AuditTrailEntry entry) {
    return _store.appendAuditEntry(entry);
  }

  @override
  Stream<List<AuditTrailEntry>> watchAuditTrail(String schoolId) {
    return _store.watchAuditTrail(schoolId);
  }
}

class MockPushNotificationRepository implements PushNotificationRepository {
  const MockPushNotificationRepository(this._store);

  final MockDataStore _store;

  @override
  Future<void> enqueueJob(PushNotificationJob job) {
    return _store.enqueueNotificationJob(job);
  }

  @override
  Stream<List<PushNotificationJob>> watchJobs(String schoolId) {
    return _store.watchNotificationJobs(schoolId);
  }
}

class MockOfficeApprovalRepository implements OfficeApprovalRepository {
  const MockOfficeApprovalRepository(this._store);

  final MockDataStore _store;

  @override
  Future<void> saveApproval(OfficeApprovalRecord record) {
    return _store.saveOfficeApproval(record);
  }

  @override
  Stream<List<OfficeApprovalRecord>> watchApprovals(String schoolId) {
    return _store.watchOfficeApprovals(schoolId);
  }
}

extension _FirstOrNullExtension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
