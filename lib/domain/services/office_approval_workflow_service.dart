import '../models/office_approval_record.dart';
import '../models/office_approval_status.dart';
import '../models/pickup_exception_code.dart';
import '../models/pickup_queue_entry.dart';

class OfficeApprovalWorkflowService {
  const OfficeApprovalWorkflowService();

  OfficeApprovalRecord createPending({
    required PickupQueueEntry entry,
    required PickupExceptionCode? reasonCode,
    required String reasonMessage,
    required String actorUid,
    required String actorName,
    required DateTime at,
  }) {
    return OfficeApprovalRecord(
      id: entry.id,
      schoolId: entry.schoolId,
      queueEntryId: entry.id,
      studentId: entry.studentId,
      guardianId: entry.guardianId,
      studentName: entry.studentName,
      guardianName: entry.guardianName,
      status: OfficeApprovalStatus.pending,
      reasonCode:
          reasonCode?.name ?? PickupExceptionCode.officeApprovalRequired.name,
      reasonMessage: reasonMessage,
      requestedAt: at,
      requestedByUid: actorUid,
      requestedByName: actorName,
    );
  }

  OfficeApprovalRecord approve({
    required OfficeApprovalRecord record,
    required String reviewerUid,
    required String reviewerName,
    String? notes,
    required DateTime at,
  }) {
    return record.copyWith(
      status: OfficeApprovalStatus.approved,
      reviewedAt: at,
      reviewedByUid: reviewerUid,
      reviewedByName: reviewerName,
      reviewNotes: notes,
      clearResolution: true,
    );
  }

  OfficeApprovalRecord deny({
    required OfficeApprovalRecord record,
    required String reviewerUid,
    required String reviewerName,
    String? notes,
    required DateTime at,
  }) {
    return record.copyWith(
      status: OfficeApprovalStatus.denied,
      reviewedAt: at,
      reviewedByUid: reviewerUid,
      reviewedByName: reviewerName,
      reviewNotes: notes,
      clearResolution: true,
    );
  }

  OfficeApprovalRecord resolve({
    required OfficeApprovalRecord record,
    required String resolverUid,
    required String resolverName,
    String? notes,
    required DateTime at,
  }) {
    return record.copyWith(
      status: OfficeApprovalStatus.resolved,
      resolvedAt: at,
      resolvedByUid: resolverUid,
      resolvedByName: resolverName,
      reviewNotes: notes ?? record.reviewNotes,
    );
  }

  bool allowsRelease(OfficeApprovalRecord? record) {
    return record?.status == OfficeApprovalStatus.approved;
  }
}
