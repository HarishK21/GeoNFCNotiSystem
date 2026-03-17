import '../../core/models/app_role.dart';
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

class MockDataStore {
  const MockDataStore();

  static const primarySchoolId = 'school_springfield';
  static const currentUserId = 'dev-parent-1';

  List<UserProfile> get userProfiles => const [
    UserProfile(
      uid: 'dev-parent-1',
      role: AppRole.parent,
      schoolId: primarySchoolId,
      displayName: 'Andrea Brooks',
      email: 'andrea.brooks@example.com',
      phone: '+1-555-0100',
    ),
    UserProfile(
      uid: 'dev-staff-1',
      role: AppRole.staff,
      schoolId: primarySchoolId,
      displayName: 'Ms. Carson',
      email: 'mcarson@springfieldacademy.edu',
      phone: '+1-555-0144',
    ),
  ];

  School get school => const School(
    id: primarySchoolId,
    name: 'Springfield Academy',
    timezone: 'America/Toronto',
    pickupZones: ['North Loop', 'South Gate', 'Gym Corridor'],
  );

  List<Student> get students => const [
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

  List<Guardian> get guardians => const [
    Guardian(
      id: 'guardian_andrea',
      schoolId: primarySchoolId,
      displayName: 'Andrea Brooks',
      email: 'andrea.brooks@example.com',
      phone: '+1-555-0100',
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

  List<PickupPermission> get pickupPermissions => [
    PickupPermission(
      id: 'permission_jordan',
      schoolId: primarySchoolId,
      studentId: 'student_maya',
      guardianId: 'guardian_andrea',
      delegateName: 'Jordan Brooks',
      delegatePhone: '+1-555-0190',
      relationship: 'Grandparent',
      approvedBy: 'Front Office',
      startsAt: DateTime.parse('2026-03-17T15:00:00Z'),
      endsAt: DateTime.parse('2026-03-17T16:00:00Z'),
      isActive: true,
    ),
    PickupPermission(
      id: 'permission_mina',
      schoolId: primarySchoolId,
      studentId: 'student_noah',
      guardianId: 'guardian_rohan',
      delegateName: 'Mina Patel',
      delegatePhone: '+1-555-0204',
      relationship: 'Neighbor',
      approvedBy: 'Front Office',
      startsAt: DateTime.parse('2026-03-20T15:00:00Z'),
      endsAt: DateTime.parse('2026-03-20T15:45:00Z'),
      isActive: false,
    ),
  ];

  List<PickupEvent> get pickupEvents => [
    PickupEvent(
      id: 'pickup_maya',
      schoolId: primarySchoolId,
      studentId: 'student_maya',
      guardianId: 'guardian_andrea',
      type: PickupEventType.approaching,
      source: PickupEventSource.geofence,
      pickupZone: 'North Loop',
      occurredAt: DateTime.parse('2026-03-17T19:09:00Z'),
      actorName: 'System',
      notes: 'Guardian entered geofence radius near North Loop.',
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
      actorName: 'South Gate NFC Reader',
      notes: 'Verified on-site by NFC tap at South Gate.',
    ),
    PickupEvent(
      id: 'pickup_ava',
      schoolId: primarySchoolId,
      studentId: 'student_ava',
      guardianId: 'guardian_lena',
      type: PickupEventType.queued,
      source: PickupEventSource.manual,
      pickupZone: 'North Loop',
      occurredAt: DateTime.parse('2026-03-17T19:03:00Z'),
      actorName: 'System',
      notes: 'Pickup request queued by family app.',
    ),
  ];

  List<ReleaseEvent> get releaseEvents => [
    ReleaseEvent(
      id: 'release_noah',
      schoolId: primarySchoolId,
      studentId: 'student_noah',
      guardianId: 'guardian_rohan',
      staffId: 'dev-staff-1',
      staffName: 'Ms. Carson',
      releasedAt: DateTime.parse('2026-03-17T19:12:30Z'),
      verificationMethod: 'nfc',
      notes: 'Released from South Gate after NFC verification.',
    ),
  ];

  List<SchoolAnnouncement> get announcements => [
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

  List<EmergencyNotice> get emergencyNotices => [
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

  List<PickupQueueEntry> get queueEntries => const [
    PickupQueueEntry(
      id: 'queue_maya',
      schoolId: primarySchoolId,
      studentId: 'student_maya',
      studentName: 'Maya Brooks',
      guardianId: 'guardian_andrea',
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
      etaLabel: 'Queued',
      eventType: PickupEventType.queued,
      isNfcVerified: false,
    ),
  ];

  List<AuditTrailEntry> get auditTrail => [
    AuditTrailEntry(
      id: 'audit_release_noah',
      schoolId: primarySchoolId,
      studentName: 'Noah Patel',
      action: 'Released',
      actorName: 'Ms. Carson',
      occurredAt: DateTime.parse('2026-03-17T19:12:30Z'),
      notes: 'Verified on-site by NFC tap at South Gate.',
    ),
    AuditTrailEntry(
      id: 'audit_pickup_maya',
      schoolId: primarySchoolId,
      studentName: 'Maya Brooks',
      action: 'Queued',
      actorName: 'System',
      occurredAt: DateTime.parse('2026-03-17T19:09:00Z'),
      notes: 'Guardian entered geofence radius near North Loop.',
    ),
    AuditTrailEntry(
      id: 'audit_delegate_ava',
      schoolId: primarySchoolId,
      studentName: 'Ava Hernandez',
      action: 'Delegate approved',
      actorName: 'Front Office',
      occurredAt: DateTime.parse('2026-03-17T17:42:00Z'),
      notes: 'Temporary guardian window approved for Lena Hernandez.',
    ),
  ];
}
