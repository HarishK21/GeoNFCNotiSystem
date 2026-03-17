import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

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
import 'firestore_helpers.dart';

class FirestoreAuthRepository implements AuthRepository {
  const FirestoreAuthRepository(this._auth);

  final firebase_auth.FirebaseAuth _auth;

  @override
  String? getCurrentUserId() => _auth.currentUser?.uid;

  @override
  Stream<String?> watchCurrentUserId() =>
      _auth.authStateChanges().map((user) => user?.uid);
}

class FirestoreUserProfileRepository implements UserProfileRepository {
  const FirestoreUserProfileRepository(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Stream<UserProfile?> watchProfile(String uid) {
    return _firestore.collection('userProfiles').doc(uid).snapshots().map((
      snapshot,
    ) {
      final data = snapshot.data();
      if (data == null) {
        return null;
      }
      return UserProfile.fromMap({...data, 'uid': data['uid'] ?? snapshot.id});
    });
  }
}

class FirestoreSchoolRepository implements SchoolRepository {
  const FirestoreSchoolRepository(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Future<School?> fetchSchool(String schoolId) async {
    final snapshot = await _firestore.collection('schools').doc(schoolId).get();
    final data = snapshot.data();
    if (data == null) {
      return null;
    }
    return School.fromMap(data, id: snapshot.id);
  }
}

class FirestoreStudentRepository implements StudentRepository {
  const FirestoreStudentRepository(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Future<List<Student>> fetchStudents(String schoolId) async {
    final snapshot = await _firestore
        .collection('schools')
        .doc(schoolId)
        .collection('students')
        .get();

    return snapshot.docs
        .map((doc) => Student.fromMap(doc.data(), id: doc.id))
        .toList(growable: false);
  }
}

class FirestoreGuardianRepository implements GuardianRepository {
  const FirestoreGuardianRepository(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Future<List<Guardian>> fetchGuardians(String schoolId) async {
    final snapshot = await _firestore
        .collection('schools')
        .doc(schoolId)
        .collection('guardians')
        .get();

    return snapshot.docs
        .map((doc) => Guardian.fromMap(doc.data(), id: doc.id))
        .toList(growable: false);
  }
}

class FirestorePickupPermissionRepository
    implements PickupPermissionRepository {
  const FirestorePickupPermissionRepository(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Stream<List<PickupPermission>> watchPermissions(String schoolId) {
    return _firestore
        .collection('schools')
        .doc(schoolId)
        .collection('pickupPermissions')
        .orderBy('startsAt', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) {
                final data = doc.data();
                return PickupPermission.fromMap({
                  ...data,
                  'startsAt': readFirestoreDate(
                    data['startsAt'],
                  ).toIso8601String(),
                  'endsAt': readFirestoreDate(data['endsAt']).toIso8601String(),
                }, id: doc.id);
              })
              .toList(growable: false),
        );
  }
}

class FirestorePickupEventRepository implements PickupEventRepository {
  const FirestorePickupEventRepository(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Stream<List<PickupEvent>> watchPickupEvents(String schoolId) {
    return _firestore
        .collection('schools')
        .doc(schoolId)
        .collection('pickupEvents')
        .orderBy('occurredAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) {
                final data = doc.data();
                return PickupEvent.fromMap({
                  ...data,
                  'occurredAt': readFirestoreDate(
                    data['occurredAt'],
                  ).toIso8601String(),
                }, id: doc.id);
              })
              .toList(growable: false),
        );
  }
}

class FirestoreReleaseEventRepository implements ReleaseEventRepository {
  const FirestoreReleaseEventRepository(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Stream<List<ReleaseEvent>> watchReleaseEvents(String schoolId) {
    return _firestore
        .collection('schools')
        .doc(schoolId)
        .collection('releaseEvents')
        .orderBy('releasedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) {
                final data = doc.data();
                return ReleaseEvent.fromMap({
                  ...data,
                  'releasedAt': readFirestoreDate(
                    data['releasedAt'],
                  ).toIso8601String(),
                }, id: doc.id);
              })
              .toList(growable: false),
        );
  }
}

class FirestoreNoticeRepository implements NoticeRepository {
  const FirestoreNoticeRepository(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Stream<List<SchoolAnnouncement>> watchAnnouncements(String schoolId) {
    return _firestore
        .collection('schools')
        .doc(schoolId)
        .collection('announcements')
        .orderBy('sentAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) {
                final data = doc.data();
                return SchoolAnnouncement.fromMap({
                  ...data,
                  'sentAt': readFirestoreDate(data['sentAt']).toIso8601String(),
                }, id: doc.id);
              })
              .toList(growable: false),
        );
  }

  @override
  Stream<List<EmergencyNotice>> watchEmergencyNotices(String schoolId) {
    return _firestore
        .collection('schools')
        .doc(schoolId)
        .collection('emergencyNotices')
        .orderBy('sentAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) {
                final data = doc.data();
                return EmergencyNotice.fromMap({
                  ...data,
                  'sentAt': readFirestoreDate(data['sentAt']).toIso8601String(),
                }, id: doc.id);
              })
              .toList(growable: false),
        );
  }
}

class FirestoreQueueRepository implements QueueRepository {
  const FirestoreQueueRepository(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Stream<List<PickupQueueEntry>> watchQueue(String schoolId) {
    return _firestore
        .collection('schools')
        .doc(schoolId)
        .collection('queue')
        .orderBy('studentName')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => PickupQueueEntry.fromMap(doc.data(), id: doc.id))
              .toList(growable: false),
        );
  }
}

class FirestoreAuditRepository implements AuditRepository {
  const FirestoreAuditRepository(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Stream<List<AuditTrailEntry>> watchAuditTrail(String schoolId) {
    return _firestore
        .collection('schools')
        .doc(schoolId)
        .collection('auditTrail')
        .orderBy('occurredAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) {
                final data = doc.data();
                return AuditTrailEntry.fromMap({
                  ...data,
                  'occurredAt': readFirestoreDate(
                    data['occurredAt'],
                  ).toIso8601String(),
                }, id: doc.id);
              })
              .toList(growable: false),
        );
  }
}
