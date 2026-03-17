import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/app_providers.dart';
import '../../../../core/widgets/content_state_card.dart';
import '../../../../core/widgets/dashboard_card.dart';

class ParentAnnouncementsScreen extends ConsumerWidget {
  const ParentAnnouncementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final announcementsState = ref.watch(schoolAnnouncementsStreamProvider);
    final emergencyState = ref.watch(emergencyNoticesStreamProvider);
    final announcements = ref.watch(announcementsProvider);
    final activeEmergencyCount =
        emergencyState.asData?.value
            .where((notice) => notice.isActive)
            .length ??
        0;
    final loadError = _firstError([announcementsState, emergencyState]);
    final isLoading = announcementsState.isLoading || emergencyState.isLoading;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        DashboardCard(
          title: 'Announcements and emergency notices',
          subtitle:
              '$activeEmergencyCount active emergency notice${activeEmergencyCount == 1 ? '' : 's'}',
          icon: Icons.notifications_active_outlined,
          child: const Text(
            'Emergency notices and school announcements are merged into one feed so families can scan the latest pickup guidance quickly.',
          ),
        ),
        const SizedBox(height: 16),
        if (loadError != null) ...[
          ContentStateCard.error(
            title: 'Could not load announcements',
            message: '$loadError',
          ),
          const SizedBox(height: 16),
        ],
        if (isLoading && announcements.isEmpty) ...[
          const ContentStateCard.loading(
            title: 'Loading announcements',
            message: 'Waiting for school messages and emergency notices.',
          ),
        ] else if (announcements.isEmpty) ...[
          const ContentStateCard.empty(
            title: 'No announcements right now',
            message:
                'School updates and emergency notices will appear here when they are published.',
          ),
        ] else ...[
          for (final announcement in announcements) ...[
            DashboardCard(
              title: announcement.title,
              subtitle:
                  '${announcement.sentAtLabel} | ${announcement.audience}',
              icon: Icons.notifications_active_outlined,
              trailing: announcement.requiresAcknowledgement
                  ? Chip(label: const Text('Ack required'))
                  : null,
              child: Text(announcement.body),
            ),
            const SizedBox(height: 16),
          ],
        ],
      ],
    );
  }
}

Object? _firstError(Iterable<AsyncValue<dynamic>> values) {
  for (final value in values) {
    if (value.hasError) {
      return value.error;
    }
  }
  return null;
}
