import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/app_providers.dart';
import '../../../../core/widgets/dashboard_card.dart';

class StaffAnnouncementsScreen extends ConsumerWidget {
  const StaffAnnouncementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final announcements = ref.watch(announcementsProvider);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        DashboardCard(
          title: 'Emergency announcement composer',
          subtitle:
              'This milestone keeps the composer UI present without depending on Firebase messaging setup.',
          icon: Icons.warning_amber_rounded,
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: null,
              icon: const Icon(Icons.send_outlined),
              label: const Text('Broadcast after FCM setup'),
            ),
          ),
        ),
        const SizedBox(height: 16),
        for (final announcement in announcements) ...[
          DashboardCard(
            title: announcement.title,
            subtitle: '${announcement.sentAtLabel} • ${announcement.audience}',
            icon: Icons.campaign_outlined,
            trailing: announcement.requiresAcknowledgement
                ? Chip(label: const Text('Ack required'))
                : null,
            child: Text(announcement.body),
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }
}
