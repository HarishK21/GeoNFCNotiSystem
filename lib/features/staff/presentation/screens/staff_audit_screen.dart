import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/app_providers.dart';
import '../../../../core/widgets/dashboard_card.dart';

class StaffAuditScreen extends ConsumerWidget {
  const StaffAuditScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(auditTrailProvider);

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: events.length + 1,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        if (index == 0) {
          return const DashboardCard(
            title: 'Audit trail',
            subtitle:
                'Every queue update, delegation change, verification, and release is logged.',
            icon: Icons.fact_check_outlined,
            child: Text(
              'The final backend milestone should swap these mock events for Firestore-backed history with filters and export support.',
            ),
          );
        }

        final event = events[index - 1];
        return DashboardCard(
          title: '${event.studentName} • ${event.action}',
          subtitle: '${event.actorName} • ${event.timestampLabel}',
          icon: Icons.history_edu_rounded,
          child: Text(event.notes),
        );
      },
    );
  }
}
