enum PickupExceptionCode {
  manualFlag,
  unauthorizedGuardian,
  expiredDelegation,
  officeApprovalRequired,
  officeApprovalDenied,
  staleQueueState,
  conflictingEventHistory,
}

PickupExceptionCode? parsePickupExceptionCode(String? value) {
  if (value == null || value.isEmpty) {
    return null;
  }

  for (final code in PickupExceptionCode.values) {
    if (code.name == value) {
      return code;
    }
  }
  return null;
}

bool isSystemManagedPickupException(String? value) {
  final code = parsePickupExceptionCode(value);
  if (code == null) {
    return false;
  }
  return code != PickupExceptionCode.manualFlag;
}
