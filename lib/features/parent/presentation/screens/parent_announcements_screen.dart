import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/app_providers.dart';
import '../../../../core/widgets/dashboard_card.dart';

class ParentAnnouncementsScreen extends ConsumerWidget {
  const ParentAnnouncementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final announcements = ref.watch(announcementsProvider);

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: announcements.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final announcement = announcements[index];
        return DashboardCard(
          title: announcement.title,
          subtitle: '${announcement.sentAtLabel} • ${announcement.audience}',
          icon: Icons.notifications_active_outlined,
          trailing: announcement.requiresAcknowledgement
              ? Chip(label: const Text('Ack required'))
              : null,
          child: Text(announcement.body),
        );
      },
    );
  }
}
