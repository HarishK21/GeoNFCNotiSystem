enum PickupWorkflowErrorCode {
  invalidStateTransition,
  unauthorizedGuardian,
  expiredDelegation,
  officeApprovalRequired,
  unauthorizedRole,
}

class PickupWorkflowException implements Exception {
  const PickupWorkflowException({required this.code, required this.message});

  final PickupWorkflowErrorCode code;
  final String message;

  @override
  String toString() => message;
}
