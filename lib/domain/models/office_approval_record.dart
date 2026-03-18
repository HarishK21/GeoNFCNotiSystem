import 'office_approval_status.dart';

class OfficeApprovalRecord {
  const OfficeApprovalRecord({
    required this.id,
    required this.schoolId,
    required this.queueEntryId,
    required this.studentId,
    required this.guardianId,
    required this.studentName,
    required this.guardianName,
    required this.status,
    required this.reasonCode,
    required this.reasonMessage,
    required this.requestedAt,
    required this.requestedByUid,
    required this.requestedByName,
    this.reviewedAt,
    this.reviewedByUid,
    this.reviewedByName,
    this.reviewNotes,
    this.resolvedAt,
    this.resolvedByUid,
    this.resolvedByName,
  });

  final String id;
  final String schoolId;
  final String queueEntryId;
  final String studentId;
  final String guardianId;
  final String studentName;
  final String guardianName;
  final OfficeApprovalStatus status;
  final String reasonCode;
  final String reasonMessage;
  final DateTime requestedAt;
  final String requestedByUid;
  final String requestedByName;
  final DateTime? reviewedAt;
  final String? reviewedByUid;
  final String? reviewedByName;
  final String? reviewNotes;
  final DateTime? resolvedAt;
  final String? resolvedByUid;
  final String? resolvedByName;

  bool get isPending => status == OfficeApprovalStatus.pending;
  bool get isApproved => status == OfficeApprovalStatus.approved;
  bool get isDenied => status == OfficeApprovalStatus.denied;
  bool get isResolved => status == OfficeApprovalStatus.resolved;

  OfficeApprovalRecord copyWith({
    String? id,
    String? schoolId,
    String? queueEntryId,
    String? studentId,
    String? guardianId,
    String? studentName,
    String? guardianName,
    OfficeApprovalStatus? status,
    String? reasonCode,
    String? reasonMessage,
    DateTime? requestedAt,
    String? requestedByUid,
    String? requestedByName,
    DateTime? reviewedAt,
    String? reviewedByUid,
    String? reviewedByName,
    String? reviewNotes,
    DateTime? resolvedAt,
    String? resolvedByUid,
    String? resolvedByName,
    bool clearReview = false,
    bool clearResolution = false,
  }) {
    return OfficeApprovalRecord(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      queueEntryId: queueEntryId ?? this.queueEntryId,
      studentId: studentId ?? this.studentId,
      guardianId: guardianId ?? this.guardianId,
      studentName: studentName ?? this.studentName,
      guardianName: guardianName ?? this.guardianName,
      status: status ?? this.status,
      reasonCode: reasonCode ?? this.reasonCode,
      reasonMessage: reasonMessage ?? this.reasonMessage,
      requestedAt: requestedAt ?? this.requestedAt,
      requestedByUid: requestedByUid ?? this.requestedByUid,
      requestedByName: requestedByName ?? this.requestedByName,
      reviewedAt: clearReview ? null : (reviewedAt ?? this.reviewedAt),
      reviewedByUid: clearReview ? null : (reviewedByUid ?? this.reviewedByUid),
      reviewedByName: clearReview
          ? null
          : (reviewedByName ?? this.reviewedByName),
      reviewNotes: clearReview ? null : (reviewNotes ?? this.reviewNotes),
      resolvedAt: clearResolution ? null : (resolvedAt ?? this.resolvedAt),
      resolvedByUid: clearResolution
          ? null
          : (resolvedByUid ?? this.resolvedByUid),
      resolvedByName: clearResolution
          ? null
          : (resolvedByName ?? this.resolvedByName),
    );
  }

  factory OfficeApprovalRecord.fromMap(Map<String, dynamic> map, {String? id}) {
    return OfficeApprovalRecord(
      id: id ?? map['id'] as String,
      schoolId: map['schoolId'] as String,
      queueEntryId: map['queueEntryId'] as String,
      studentId: map['studentId'] as String,
      guardianId: map['guardianId'] as String,
      studentName: map['studentName'] as String,
      guardianName: map['guardianName'] as String,
      status:
          parseOfficeApprovalStatus(map['status'] as String?) ??
          OfficeApprovalStatus.pending,
      reasonCode: map['reasonCode'] as String,
      reasonMessage: map['reasonMessage'] as String,
      requestedAt: DateTime.parse(map['requestedAt'] as String),
      requestedByUid: map['requestedByUid'] as String,
      requestedByName: map['requestedByName'] as String,
      reviewedAt: map['reviewedAt'] == null
          ? null
          : DateTime.parse(map['reviewedAt'] as String),
      reviewedByUid: map['reviewedByUid'] as String?,
      reviewedByName: map['reviewedByName'] as String?,
      reviewNotes: map['reviewNotes'] as String?,
      resolvedAt: map['resolvedAt'] == null
          ? null
          : DateTime.parse(map['resolvedAt'] as String),
      resolvedByUid: map['resolvedByUid'] as String?,
      resolvedByName: map['resolvedByName'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'schoolId': schoolId,
      'queueEntryId': queueEntryId,
      'studentId': studentId,
      'guardianId': guardianId,
      'studentName': studentName,
      'guardianName': guardianName,
      'status': status.name,
      'reasonCode': reasonCode,
      'reasonMessage': reasonMessage,
      'requestedAt': requestedAt.toIso8601String(),
      'requestedByUid': requestedByUid,
      'requestedByName': requestedByName,
      'reviewedAt': reviewedAt?.toIso8601String(),
      'reviewedByUid': reviewedByUid,
      'reviewedByName': reviewedByName,
      'reviewNotes': reviewNotes,
      'resolvedAt': resolvedAt?.toIso8601String(),
      'resolvedByUid': resolvedByUid,
      'resolvedByName': resolvedByName,
    };
  }
}
