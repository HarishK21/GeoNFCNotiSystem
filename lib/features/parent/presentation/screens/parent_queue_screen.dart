import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/app_providers.dart';
import '../../../../core/widgets/content_state_card.dart';
import '../../../../core/widgets/dashboard_card.dart';

class ParentQueueScreen extends ConsumerWidget {
  const ParentQueueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pickupEventsState = ref.watch(pickupEventsStreamProvider);
    final releaseEventsState = ref.watch(releaseEventsStreamProvider);
    final history = ref.watch(familyHistoryProvider);
    final loadError = _firstError([pickupEventsState, releaseEventsState]);
    final isLoading =
        pickupEventsState.isLoading || releaseEventsState.isLoading;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        DashboardCard(
          title: 'Pickup history',
          subtitle:
              '${history.length} event${history.length == 1 ? '' : 's'} captured for your linked students.',
          icon: Icons.history_rounded,
          child: const Text(
            'This combines pickup state changes and release confirmations from the repository-backed event stream.',
          ),
        ),
        const SizedBox(height: 16),
        if (loadError != null) ...[
          ContentStateCard.error(
            title: 'Could not load pickup history',
            message: '$loadError',
          ),
          const SizedBox(height: 16),
        ],
        if (isLoading && history.isEmpty) ...[
          const ContentStateCard.loading(
            title: 'Loading pickup history',
            message: 'Waiting for pickup and release events to resolve.',
          ),
        ] else if (history.isEmpty) ...[
          const ContentStateCard.empty(
            title: 'No pickup history yet',
            message:
                'Queue transitions and release confirmations for your students will appear here.',
          ),
        ] else ...[
          for (final event in history) ...[
            DashboardCard(
              title: '${event.studentName} - ${event.action}',
              subtitle: '${event.actorName} | ${event.timestampLabel}',
              icon: Icons.receipt_long_rounded,
              child: Text(event.notes),
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
