class Announcement {
  const Announcement({
    required this.title,
    required this.body,
    required this.sentAtLabel,
    required this.audience,
    this.requiresAcknowledgement = false,
  });

  final String title;
  final String body;
  final String sentAtLabel;
  final String audience;
  final bool requiresAcknowledgement;
}
