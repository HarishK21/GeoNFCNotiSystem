enum PickupWorkflowErrorCode {
  invalidStateTransition,
  unauthorizedGuardian,
  expiredDelegation,
  officeApprovalRequired,
  officeApprovalDenied,
  unauthorizedRole,
}

class PickupWorkflowException implements Exception {
  const PickupWorkflowException({required this.code, required this.message});

  final PickupWorkflowErrorCode code;
  final String message;

  @override
  String toString() => message;
}
