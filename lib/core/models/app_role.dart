enum AppRole {
  parent(
    label: 'Parent/Guardian',
    description:
        'View approaching students, temporary delegates, and release updates.',
    defaultRoute: '/parent/plan',
  ),
  staff(
    label: 'Teacher/Staff',
    description:
        'Manage pickup queue, NFC verification, releases, and audit events.',
    defaultRoute: '/staff/queue',
  );

  const AppRole({
    required this.label,
    required this.description,
    required this.defaultRoute,
  });

  final String label;
  final String description;
  final String defaultRoute;

  static AppRole fromStorage(String value) {
    return AppRole.values.firstWhere(
      (role) => role.name == value,
      orElse: () => AppRole.parent,
    );
  }
}
