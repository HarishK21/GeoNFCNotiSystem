import 'dart:async';

import '../../core/models/app_role.dart';
import '../../domain/models/audit_trail_entry.dart';
import '../../domain/models/emergency_notice.dart';
import '../../domain/models/guardian.dart';
import '../../domain/models/pickup_event.dart';
import '../../domain/models/pickup_permission.dart';
import '../../domain/models/pickup_queue_entry.dart';
import '../../domain/models/push_notification_job.dart';
import '../../domain/models/release_event.dart';
import '../../domain/models/school.dart';
import '../../domain/models/school_announcement.dart';
import '../../domain/models/student.dart';
import '../../domain/models/user_profile.dart';

class MockDataStore {
  MockDataStore() {
    _userProfiles = _seedUserProfiles();
    _students = _seedStudents();
    _guardians = _seedGuardians();
    _pickupPermissions = _seedPickupPermissions();
    _pickupEvents = _seedPickupEvents();
    _releaseEvents = _seedReleaseEvents();
    _announcements = _seedAnnouncements();
    _emergencyNotices = _seedEmergencyNotices();
    _queueEntries = _seedQueueEntries();
    _auditTrail = _seedAuditTrail();
    _notificationJobs = <PushNotificationJob>[];
  }

  static const primarySchoolId = 'school_springfield';
  static const parentUserId = 'dev-parent-1';
  static const staffUserId = 'dev-staff-1';
  static const parentGuardianId = 'guardian_andrea';

  final School school = const School(
    id: primarySchoolId,
    name: 'Springfield Academy',
    timezone: 'America/Toronto',
    pickupZones: ['North Loop', 'South Gate', 'Gym Corridor'],
  );

  final _authController = StreamController<String?>.broadcast();
  final _queueController = StreamController<List<PickupQueueEntry>>.broadcast();
  final _pickupPermissionsController =
      StreamController<List<PickupPermission>>.broadcast();
  final _pickupEventsController =
      StreamController<List<PickupEvent>>.broadcast();
  final _releaseEventsController =
      StreamController<List<ReleaseEvent>>.broadcast();
  final _announcementsController =
      StreamController<List<SchoolAnnouncement>>.broadcast();
  final _emergencyController =
      StreamController<List<EmergencyNotice>>.broadcast();
  final _auditController = StreamController<List<AuditTrailEntry>>.broadcast();
  final _notificationJobsController =
      StreamController<List<PushNotificationJob>>.broadcast();

  late final List<UserProfile> _userProfiles;
  late final List<Student> _students;
  late final List<Guardian> _guardians;
  late final List<PickupPermission> _pickupPermissions;
  late final List<PickupEvent> _pickupEvents;
  late final List<ReleaseEvent> _releaseEvents;
  late final List<SchoolAnnouncement> _announcements;
  late final List<EmergencyNotice> _emergencyNotices;
  late final List<PickupQueueEntry> _queueEntries;
  late final List<AuditTrailEntry> _auditTrail;
  late final List<PushNotificationJob> _notificationJobs;
  String? _currentUserId;

  List<UserProfile> get userProfiles => List.unmodifiable(_userProfiles);
  List<Student> get students => List.unmodifiable(_students);
  List<Guardian> get guardians => List.unmodifiable(_guardians);
  List<PickupPermission> get pickupPermissions =>
      List.unmodifiable(_pickupPermissions);
  List<PickupEvent> get pickupEvents => List.unmodifiable(_pickupEvents);
  List<ReleaseEvent> get releaseEvents => List.unmodifiable(_releaseEvents);
  List<SchoolAnnouncement> get announcements =>
      List.unmodifiable(_announcements);
  List<EmergencyNotice> get emergencyNotices =>
      List.unmodifiable(_emergencyNotices);
  List<PickupQueueEntry> get queueEntries => List.unmodifiable(_queueEntries);
  List<AuditTrailEntry> get auditTrail => List.unmodifiable(_auditTrail);
  List<PushNotificationJob> get notificationJobs =>
      List.unmodifiable(_notificationJobs);
  String? get currentUserId => _currentUserId;

  Stream<String?> watchCurrentUserId() async* {
    yield _currentUserId;
    yield* _authController.stream;
  }

  Stream<List<PickupQueueEntry>> watchQueue(String schoolId) async* {
    yield _filterBySchool(_queueEntries, schoolId, (item) => item.schoolId);
    yield* _queueController.stream.map(
      (items) => _filterBySchool(items, schoolId, (item) => item.schoolId),
    );
  }

  Stream<List<PickupPermission>> watchPermissions(String schoolId) async* {
    yield _filterBySchool(
      _pickupPermissions,
      schoolId,
      (item) => item.schoolId,
    );
    yield* _pickupPermissionsController.stream.map(
      (items) => _filterBySchool(items, schoolId, (item) => item.schoolId),
    );
  }

  Stream<List<PickupEvent>> watchPickupEvents(String schoolId) async* {
    yield _filterBySchool(_pickupEvents, schoolId, (item) => item.schoolId);
    yield* _pickupEventsController.stream.map(
      (items) => _filterBySchool(items, schoolId, (item) => item.schoolId),
    );
  }

  Stream<List<ReleaseEvent>> watchReleaseEvents(String schoolId) async* {
    yield _filterBySchool(_releaseEvents, schoolId, (item) => item.schoolId);
    yield* _releaseEventsController.stream.map(
      (items) => _filterBySchool(items, schoolId, (item) => item.schoolId),
    );
  }

  Stream<List<SchoolAnnouncement>> watchAnnouncements(String schoolId) async* {
    yield _filterBySchool(_announcements, schoolId, (item) => item.schoolId);
    yield* _announcementsController.stream.map(
      (items) => _filterBySchool(items, schoolId, (item) => item.schoolId),
    );
  }

  Stream<List<EmergencyNotice>> watchEmergencyNotices(String schoolId) async* {
    yield _filterBySchool(_emergencyNotices, schoolId, (item) => item.schoolId);
    yield* _emergencyController.stream.map(
      (items) => _filterBySchool(items, schoolId, (item) => item.schoolId),
    );
  }

  Stream<List<AuditTrailEntry>> watchAuditTrail(String schoolId) async* {
    yield _filterBySchool(_auditTrail, schoolId, (item) => item.schoolId);
    yield* _auditController.stream.map(
      (items) => _filterBySchool(items, schoolId, (item) => item.schoolId),
    );
  }

  Stream<List<PushNotificationJob>> watchNotificationJobs(
    String schoolId,
  ) async* {
    yield _filterBySchool(_notificationJobs, schoolId, (item) => item.schoolId);
    yield* _notificationJobsController.stream.map(
      (items) => _filterBySchool(items, schoolId, (item) => item.schoolId),
    );
  }

  Future<void> signInAsRole(AppRole role) async {
    _currentUserId = switch (role) {
      AppRole.parent => parentUserId,
      AppRole.staff => staffUserId,
    };
    _authController.add(_currentUserId);
  }

  Future<void> signOut() async {
    _currentUserId = null;
    _authController.add(null);
  }

  Future<void> saveQueueEntry(PickupQueueEntry entry) async {
    final index = _queueEntries.indexWhere((item) => item.id == entry.id);
    if (index >= 0) {
      _queueEntries[index] = entry;
    } else {
      _queueEntries.add(entry);
    }
    _queueController.add(List.unmodifiable(_queueEntries));
  }

  Future<void> createPermission(PickupPermission permission) async {
    _pickupPermissions.add(permission);
    _pickupPermissionsController.add(List.unmodifiable(_pickupPermissions));
  }

  Future<void> logPickupEvent(PickupEvent event) async {
    _pickupEvents.add(event);
    _pickupEventsController.add(List.unmodifiable(_pickupEvents));
  }

  Future<void> createReleaseEvent(ReleaseEvent event) async {
    _releaseEvents.add(event);
    _releaseEventsController.add(List.unmodifiable(_releaseEvents));
  }

  Future<void> appendAuditEntry(AuditTrailEntry entry) async {
    _auditTrail.add(entry);
    _auditController.add(List.unmodifiable(_auditTrail));
  }

  Future<void> enqueueNotificationJob(PushNotificationJob job) async {
    final index = _notificationJobs.indexWhere((item) => item.id == job.id);
    if (index >= 0) {
      _notificationJobs[index] = job;
    } else {
      _notificationJobs.add(job);
    }
    _notificationJobsController.add(List.unmodifiable(_notificationJobs));
  }

  void dispose() {
    _authController.close();
    _queueController.close();
    _pickupPermissionsController.close();
    _pickupEventsController.close();
    _releaseEventsController.close();
    _announcementsController.close();
    _emergencyController.close();
    _auditController.close();
    _notificationJobsController.close();
  }

  static List<T> _filterBySchool<T>(
    List<T> items,
    String schoolId,
    String Function(T item) selector,
  ) {
    return items
        .where((item) => selector(item) == schoolId)
        .toList(growable: false);
  }

  static List<UserProfile> _seedUserProfiles() => const [
    UserProfile(
      uid: parentUserId,
      role: AppRole.parent,
      schoolId: primarySchoolId,
      displayName: 'Andrea Brooks',
      email: 'andrea.brooks@example.com',
      phone: '+1-555-0100',
      linkedGuardianId: parentGuardianId,
    ),
    UserProfile(
      uid: staffUserId,
      role: AppRole.staff,
      schoolId: primarySchoolId,
      displayName: 'Ms. Carson',
      email: 'mcarson@springfieldacademy.edu',
      phone: '+1-555-0144',
    ),
  ];

  static List<Student> _seedStudents() => const [
    Student(
      id: 'student_maya',
      schoolId: primarySchoolId,
      displayName: 'Maya Brooks',
      gradeLevel: 'Grade 2',
      homeroom: 'Cedar',
      pickupZone: 'North Loop',
      guardianIds: ['guardian_andrea', 'guardian_jordan'],
    ),
    Student(
      id: 'student_noah',
      schoolId: primarySchoolId,
      displayName: 'Noah Patel',
      gradeLevel: 'Grade 4',
      homeroom: 'Birch',
      pickupZone: 'South Gate',
      guardianIds: ['guardian_rohan'],
    ),
    Student(
      id: 'student_ava',
      schoolId: primarySchoolId,
      displayName: 'Ava Hernandez',
      gradeLevel: 'Kindergarten',
      homeroom: 'Maple',
      pickupZone: 'North Loop',
      guardianIds: ['guardian_lena'],
    ),
  ];

  static List<Guardian> _seedGuardians() => const [
    Guardian(
      id: 'guardian_andrea',
      schoolId: primarySchoolId,
      displayName: 'Andrea Brooks',
      email: 'andrea.brooks@example.com',
      phone: '+1-555-0100',
      studentIds: ['student_maya'],
    ),
    Guardian(
      id: 'guardian_jordan',
      schoolId: primarySchoolId,
      displayName: 'Jordan Brooks',
      email: 'jordan.brooks@example.com',
      phone: '+1-555-0190',
      studentIds: ['student_maya'],
    ),
    Guardian(
      id: 'guardian_rohan',
      schoolId: primarySchoolId,
      displayName: 'Rohan Patel',
      email: 'rohan.patel@example.com',
      phone: '+1-555-0122',
      studentIds: ['student_noah'],
    ),
    Guardian(
      id: 'guardian_lena',
      schoolId: primarySchoolId,
      displayName: 'Lena Hernandez',
      email: 'lena.hernandez@example.com',
      phone: '+1-555-0187',
      studentIds: ['student_ava'],
    ),
  ];

  static List<PickupPermission> _seedPickupPermissions() => [
    PickupPermission(
      id: 'permission_jordan',
      schoolId: primarySchoolId,
      studentId: 'student_maya',
      guardianId: parentGuardianId,
      delegateName: 'Jordan Brooks',
      delegatePhone: '+1-555-0190',
      relationship: 'Grandparent',
      approvedBy: 'Front Office',
      startsAt: DateTime.parse('2026-03-17T15:00:00Z'),
      endsAt: DateTime.parse('2026-03-17T16:00:00Z'),
      isActive: true,
    ),
  ];

  static List<PickupEvent> _seedPickupEvents() => [
    PickupEvent(
      id: 'pickup_maya',
      schoolId: primarySchoolId,
      studentId: 'student_maya',
      guardianId: parentGuardianId,
      type: PickupEventType.approaching,
      source: PickupEventSource.geofence,
      pickupZone: 'North Loop',
      occurredAt: DateTime.parse('2026-03-17T19:09:00Z'),
      actorName: 'System',
      notes: 'Guardian entered pickup radius near North Loop.',
    ),
    PickupEvent(
      id: 'pickup_noah',
      schoolId: primarySchoolId,
      studentId: 'student_noah',
      guardianId: 'guardian_rohan',
      type: PickupEventType.verified,
      source: PickupEventSource.nfc,
      pickupZone: 'South Gate',
      occurredAt: DateTime.parse('2026-03-17T19:12:00Z'),
      actorName: 'South Gate staff',
      notes: 'Ready for staff release confirmation.',
    ),
    PickupEvent(
      id: 'pickup_ava',
      schoolId: primarySchoolId,
      studentId: 'student_ava',
      guardianId: 'guardian_lena',
      type: PickupEventType.pending,
      source: PickupEventSource.manual,
      pickupZone: 'North Loop',
      occurredAt: DateTime.parse('2026-03-17T19:03:00Z'),
      actorName: 'Family app',
      notes: 'Pickup plan created for dismissal.',
    ),
  ];

  static List<ReleaseEvent> _seedReleaseEvents() => [
    ReleaseEvent(
      id: 'release_noah',
      schoolId: primarySchoolId,
      studentId: 'student_noah',
      guardianId: 'guardian_rohan',
      staffId: staffUserId,
      staffName: 'Ms. Carson',
      releasedAt: DateTime.parse('2026-03-17T19:12:30Z'),
      verificationMethod: 'manual-confirmed',
      notes: 'Release confirmed after verified status.',
    ),
  ];

  static List<SchoolAnnouncement> _seedAnnouncements() => [
    SchoolAnnouncement(
      id: 'announcement_weather',
      schoolId: primarySchoolId,
      title: 'Weather-adjusted dismissal today',
      body:
          'North Loop pickup remains active. Bus riders will dismiss from the gym corridor at 3:20 PM.',
      audience: 'All families and staff',
      sentAt: DateTime.parse('2026-03-17T18:05:00Z'),
      requiresAcknowledgement: false,
    ),
  ];

  static List<EmergencyNotice> _seedEmergencyNotices() => [
    EmergencyNotice(
      id: 'emergency_drill',
      schoolId: primarySchoolId,
      title: 'Emergency drill reminder',
      body:
          'Staff should pause release until the all-clear banner appears in the live queue.',
      severity: EmergencySeverity.warning,
      sentAt: DateTime.parse('2026-03-17T15:10:00Z'),
      isActive: true,
    ),
  ];

  static List<PickupQueueEntry> _seedQueueEntries() => [
    PickupQueueEntry(
      id: 'queue_maya',
      schoolId: primarySchoolId,
      studentId: 'student_maya',
      studentName: 'Maya Brooks',
      guardianId: parentGuardianId,
      guardianName: 'Andrea Brooks',
      homeroom: 'Grade 2 - Cedar',
      pickupZone: 'North Loop',
      etaLabel: '2 min',
      eventType: PickupEventType.approaching,
      isNfcVerified: false,
    ),
    PickupQueueEntry(
      id: 'queue_noah',
      schoolId: primarySchoolId,
      studentId: 'student_noah',
      studentName: 'Noah Patel',
      guardianId: 'guardian_rohan',
      guardianName: 'Rohan Patel',
      homeroom: 'Grade 4 - Birch',
      pickupZone: 'South Gate',
      etaLabel: 'On-site',
      eventType: PickupEventType.verified,
      isNfcVerified: true,
    ),
    PickupQueueEntry(
      id: 'queue_ava',
      schoolId: primarySchoolId,
      studentId: 'student_ava',
      studentName: 'Ava Hernandez',
      guardianId: 'guardian_lena',
      guardianName: 'Lena Hernandez',
      homeroom: 'Kindergarten - Maple',
      pickupZone: 'North Loop',
      etaLabel: 'Pending',
      eventType: PickupEventType.pending,
      isNfcVerified: false,
    ),
  ];

  static List<AuditTrailEntry> _seedAuditTrail() => [
    AuditTrailEntry(
      id: 'audit_release_noah',
      schoolId: primarySchoolId,
      studentName: 'Noah Patel',
      action: 'Released',
      actorName: 'Ms. Carson',
      occurredAt: DateTime.parse('2026-03-17T19:12:30Z'),
      notes: 'Release confirmed after verified status.',
    ),
    AuditTrailEntry(
      id: 'audit_pickup_maya',
      schoolId: primarySchoolId,
      studentName: 'Maya Brooks',
      action: 'Approaching',
      actorName: 'System',
      occurredAt: DateTime.parse('2026-03-17T19:09:00Z'),
      notes: 'Guardian entered pickup radius near North Loop.',
    ),
  ];
}
