import 'package:flutter_test/flutter_test.dart';

import 'package:geo_tap_guardian/domain/models/pickup_event.dart';
import 'package:geo_tap_guardian/domain/models/pickup_exception_code.dart';
import 'package:geo_tap_guardian/domain/models/pickup_permission.dart';
import 'package:geo_tap_guardian/domain/models/pickup_queue_entry.dart';
import 'package:geo_tap_guardian/domain/models/release_event.dart';
import 'package:geo_tap_guardian/domain/models/student.dart';
import 'package:geo_tap_guardian/domain/services/pickup_authorization_service.dart';
import 'package:geo_tap_guardian/domain/services/queue_reconciliation_service.dart';

void main() {
  const authorizationService = PickupAuthorizationService();
  const service = QueueReconciliationService(authorizationService);

  test(
    'reconciliation marks a queue entry released when release history is newer',
    () {
      final change = service.reconcileEntry(
        entry: _entry(eventType: PickupEventType.verified, isNfcVerified: true),
        student: _student(),
        permissions: const [],
        pickupEvents: [
          PickupEvent(
            id: 'pickup_1',
            schoolId: 'school_1',
            studentId: 'student_1',
            guardianId: 'guardian_1',
            type: PickupEventType.verified,
            source: PickupEventSource.nfc,
            pickupZone: 'North Loop',
            occurredAt: DateTime.utc(2026, 3, 17, 15, 10),
          ),
        ],
        releaseEvents: [
          ReleaseEvent(
            id: 'release_1',
            schoolId: 'school_1',
            studentId: 'student_1',
            guardianId: 'guardian_1',
            staffId: 'staff_1',
            staffName: 'Ms. Carson',
            releasedAt: DateTime.utc(2026, 3, 17, 15, 11),
            verificationMethod: 'nfc-verified-release',
          ),
        ],
        at: DateTime.utc(2026, 3, 17, 15, 12),
      );

      expect(change, isNotNull);
      expect(change!.updatedEntry.eventType, PickupEventType.released);
      expect(change.updatedEntry.isNfcVerified, isTrue);
      expect(change.notes, contains('Queue state reconciled'));
    },
  );

  test('reconciliation flags unauthorized guardians for office approval', () {
    final change = service.reconcileEntry(
      entry: _entry(
        guardianId: 'visitor_1',
        guardianName: 'Casey Visitor',
        eventType: PickupEventType.verified,
        isNfcVerified: true,
      ),
      student: _student(),
      permissions: const [],
      pickupEvents: const [],
      releaseEvents: const [],
      at: DateTime.utc(2026, 3, 17, 15, 12),
    );

    expect(change, isNotNull);
    expect(
      change!.updatedEntry.exceptionCode,
      PickupExceptionCode.unauthorizedGuardian.name,
    );
    expect(change.updatedEntry.officeApprovalRequired, isTrue);
    expect(change.notes, contains('not authorized'));
  });

  test(
    'reconciliation clears system-generated flags when active delegation exists',
    () {
      final now = DateTime.utc(2026, 3, 17, 15, 12);
      final change = service.reconcileEntry(
        entry: _entry(
          guardianId: 'delegate_1',
          guardianName: 'Sam Brooks',
          eventType: PickupEventType.verified,
          isNfcVerified: true,
          exceptionFlag:
              'Office approval is required before this student can be released.',
          exceptionCode: PickupExceptionCode.unauthorizedGuardian.name,
          officeApprovalRequired: true,
        ),
        student: _student(),
        permissions: [
          PickupPermission(
            id: 'permission_1',
            schoolId: 'school_1',
            studentId: 'student_1',
            guardianId: 'guardian_1',
            delegateName: 'Sam Brooks',
            delegatePhone: '+1-555-0101',
            relationship: 'Uncle',
            approvedBy: 'Andrea Brooks',
            startsAt: now.subtract(const Duration(minutes: 30)),
            endsAt: now.add(const Duration(minutes: 30)),
            isActive: true,
          ),
        ],
        pickupEvents: const [],
        releaseEvents: const [],
        at: now,
      );

      expect(change, isNotNull);
      expect(change!.updatedEntry.exceptionFlag, isNull);
      expect(change.updatedEntry.exceptionCode, isNull);
      expect(change.updatedEntry.officeApprovalRequired, isFalse);
      expect(change.notes, contains('Cleared system-generated release block'));
    },
  );
}

PickupQueueEntry _entry({
  String guardianId = 'guardian_1',
  String guardianName = 'Andrea Brooks',
  PickupEventType eventType = PickupEventType.approaching,
  bool isNfcVerified = false,
  String? exceptionFlag,
  String? exceptionCode,
  bool officeApprovalRequired = false,
}) {
  return PickupQueueEntry(
    id: 'queue_1',
    schoolId: 'school_1',
    studentId: 'student_1',
    studentName: 'Maya Brooks',
    guardianId: guardianId,
    guardianName: guardianName,
    homeroom: 'Grade 2 - Cedar',
    pickupZone: 'North Loop',
    etaLabel: 'Pending',
    eventType: eventType,
    isNfcVerified: isNfcVerified,
    exceptionFlag: exceptionFlag,
    exceptionCode: exceptionCode,
    officeApprovalRequired: officeApprovalRequired,
  );
}

Student _student() {
  return const Student(
    id: 'student_1',
    schoolId: 'school_1',
    displayName: 'Maya Brooks',
    gradeLevel: 'Grade 2',
    homeroom: 'Cedar',
    pickupZone: 'North Loop',
    guardianIds: ['guardian_1'],
  );
}
