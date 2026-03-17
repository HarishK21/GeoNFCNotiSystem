import 'package:flutter/material.dart';

import 'dashboard_card.dart';

class ContentStateCard extends StatelessWidget {
  const ContentStateCard.loading({
    super.key,
    required this.title,
    this.message = 'Loading...',
  }) : icon = Icons.hourglass_bottom_rounded;

  const ContentStateCard.empty({
    super.key,
    required this.title,
    required this.message,
  }) : icon = Icons.inbox_outlined;

  const ContentStateCard.error({
    super.key,
    required this.title,
    required this.message,
  }) : icon = Icons.error_outline_rounded;

  final String title;
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return DashboardCard(
      title: title,
      icon: icon,
      child: Text(message),
    );
  }
}
