import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/app_providers.dart';
import '../../../../core/widgets/content_state_card.dart';
import '../../../../core/widgets/dashboard_card.dart';

class StaffAuditScreen extends ConsumerWidget {
  const StaffAuditScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auditState = ref.watch(auditTrailStreamProvider);
    final events = ref.watch(auditTrailProvider);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        DashboardCard(
          title: 'Audit trail',
          subtitle:
              '${events.length} repository-backed event${events.length == 1 ? '' : 's'} visible to staff',
          icon: Icons.fact_check_outlined,
          child: const Text(
            'Queue changes, delegation actions, verification, release, and exception handling should all leave an audit record.',
          ),
        ),
        const SizedBox(height: 16),
        if (auditState.hasError) ...[
          ContentStateCard.error(
            title: 'Could not load the audit trail',
            message: '${auditState.error}',
          ),
          const SizedBox(height: 16),
        ],
        if (auditState.isLoading && events.isEmpty) ...[
          const ContentStateCard.loading(
            title: 'Loading audit trail',
            message: 'Waiting for audit entries from the current repository.',
          ),
        ] else if (events.isEmpty) ...[
          const ContentStateCard.empty(
            title: 'No audit events yet',
            message:
                'Audit entries will appear once queue, delegation, verification, or release actions occur.',
          ),
        ] else ...[
          for (final event in events) ...[
            DashboardCard(
              title: '${event.studentName} - ${event.action}',
              subtitle: '${event.actorName} | ${event.timestampLabel}',
              icon: Icons.history_edu_rounded,
              child: Text(event.notes),
            ),
            const SizedBox(height: 16),
          ],
        ],
      ],
    );
  }
}
