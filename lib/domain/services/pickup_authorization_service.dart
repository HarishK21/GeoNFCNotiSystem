import '../models/pickup_exception_code.dart';
import '../models/pickup_permission.dart';
import '../models/pickup_queue_entry.dart';
import '../models/student.dart';

enum PickupAuthorizationMode { directGuardian, delegatedPermission, blocked }

class PickupAuthorizationDecision {
  const PickupAuthorizationDecision({
    required this.isAuthorized,
    required this.requiresOfficeApproval,
    required this.mode,
    this.exceptionCode,
    this.message,
  });

  final bool isAuthorized;
  final bool requiresOfficeApproval;
  final PickupAuthorizationMode mode;
  final PickupExceptionCode? exceptionCode;
  final String? message;
}

class PickupAuthorizationService {
  const PickupAuthorizationService();

  PickupAuthorizationDecision evaluate({
    required PickupQueueEntry entry,
    required Student? student,
    required List<PickupPermission> permissions,
    required DateTime at,
  }) {
    if (student == null) {
      return const PickupAuthorizationDecision(
        isAuthorized: false,
        requiresOfficeApproval: true,
        mode: PickupAuthorizationMode.blocked,
        exceptionCode: PickupExceptionCode.officeApprovalRequired,
        message:
            'Student roster details are unavailable. Office approval is required before release.',
      );
    }

    final exceptionCode = parsePickupExceptionCode(entry.exceptionCode);
    final hasManualOfficeHold =
        entry.officeApprovalRequired &&
        exceptionCode == PickupExceptionCode.manualFlag;

    if (hasManualOfficeHold) {
      return PickupAuthorizationDecision(
        isAuthorized: false,
        requiresOfficeApproval: true,
        mode: PickupAuthorizationMode.blocked,
        exceptionCode: PickupExceptionCode.officeApprovalRequired,
        message:
            entry.exceptionFlag ??
            'Office approval is required before this student can be released.',
      );
    }

    if (student.guardianIds.contains(entry.guardianId)) {
      return const PickupAuthorizationDecision(
        isAuthorized: true,
        requiresOfficeApproval: false,
        mode: PickupAuthorizationMode.directGuardian,
      );
    }

    final matchingPermissions = permissions
        .where(
          (permission) =>
              permission.studentId == entry.studentId &&
              _normalize(permission.delegateName) ==
                  _normalize(entry.guardianName),
        )
        .toList(growable: false);

    if (matchingPermissions.any((permission) => permission.isActiveAt(at))) {
      return const PickupAuthorizationDecision(
        isAuthorized: true,
        requiresOfficeApproval: false,
        mode: PickupAuthorizationMode.delegatedPermission,
      );
    }

    if (matchingPermissions.isNotEmpty) {
      return PickupAuthorizationDecision(
        isAuthorized: false,
        requiresOfficeApproval: true,
        mode: PickupAuthorizationMode.blocked,
        exceptionCode: PickupExceptionCode.expiredDelegation,
        message:
            'Temporary pickup delegation for ${entry.guardianName} is expired or inactive. Office approval is required.',
      );
    }

    return PickupAuthorizationDecision(
      isAuthorized: false,
      requiresOfficeApproval: true,
      mode: PickupAuthorizationMode.blocked,
      exceptionCode: PickupExceptionCode.unauthorizedGuardian,
      message:
          '${entry.guardianName} is not authorized for ${entry.studentName}. Office approval is required.',
    );
  }
}

String _normalize(String value) {
  return value.trim().toLowerCase();
}
