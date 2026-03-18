import '../models/office_approval_record.dart';

abstract class OfficeApprovalRepository {
  Stream<List<OfficeApprovalRecord>> watchApprovals(String schoolId);
  Future<void> saveApproval(OfficeApprovalRecord record);
}
