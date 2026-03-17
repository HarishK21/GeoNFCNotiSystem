import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/app_providers.dart';
import '../../../../core/widgets/dashboard_card.dart';
import '../../../../core/widgets/pickup_request_card.dart';

class ParentQueueScreen extends ConsumerWidget {
  const ParentQueueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queue = ref.watch(pickupQueueProvider);
    final readyCount = ref.watch(releaseReadyQueueProvider).length;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        DashboardCard(
          title: 'Real-time pickup queue',
          subtitle:
              '$readyCount student${readyCount == 1 ? '' : 's'} cleared for release.',
          icon: Icons.queue_play_next_rounded,
          child: const Text(
            'Families can see which pickups are approaching versus verified on-site before arriving at the handoff point.',
          ),
        ),
        const SizedBox(height: 16),
        for (final request in queue) ...[
          PickupRequestCard(request: request, showReleaseState: true),
          const SizedBox(height: 16),
        ],
      ],
    );
  }
}
