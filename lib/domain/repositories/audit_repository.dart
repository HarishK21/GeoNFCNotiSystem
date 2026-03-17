import '../models/audit_trail_entry.dart';

abstract class AuditRepository {
  Stream<List<AuditTrailEntry>> watchAuditTrail(String schoolId);
  Future<void> appendAuditEntry(AuditTrailEntry entry);
}
