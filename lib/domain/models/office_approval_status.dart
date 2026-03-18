enum OfficeApprovalStatus { pending, approved, denied, resolved }

OfficeApprovalStatus? parseOfficeApprovalStatus(String? value) {
  if (value == null || value.isEmpty) {
    return null;
  }

  for (final status in OfficeApprovalStatus.values) {
    if (status.name == value) {
      return status;
    }
  }
  return null;
}
