import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/app_providers.dart';
import '../../../../core/widgets/dashboard_card.dart';

class ParentDelegationScreen extends ConsumerWidget {
  const ParentDelegationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final delegates = ref.watch(guardianDelegatesProvider);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        DashboardCard(
          title: 'Temporary guardian delegation',
          subtitle:
              'Delegations unlock pickup for approved helpers without sharing the primary guardian account.',
          icon: Icons.how_to_reg_rounded,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Each delegate still requires on-site NFC verification before staff can release a student.',
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: null,
                  icon: const Icon(Icons.add_circle_outline_rounded),
                  label: const Text(
                    'Add delegate in Firebase-backed milestone',
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        for (final delegate in delegates) ...[
          DashboardCard(
            title: delegate.name,
            subtitle: '${delegate.relationship} • ${delegate.windowLabel}',
            icon: delegate.isActive
                ? Icons.verified_user_outlined
                : Icons.history_toggle_off_rounded,
            trailing: Chip(
              label: Text(delegate.isActive ? 'Active' : 'Scheduled'),
            ),
            child: Text(
              delegate.isActive
                  ? 'This delegate can appear in the live pickup queue during the active window.'
                  : 'This delegate will remain inactive until the approved pickup window begins.',
            ),
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }
}
