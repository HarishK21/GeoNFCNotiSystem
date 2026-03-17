import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/presence_state.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/widgets/dashboard_card.dart';
import '../../../../core/widgets/status_pill.dart';

class ParentHomeScreen extends ConsumerWidget {
  const ParentHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final environment = ref.watch(appEnvironmentProvider);
    final queue = ref.watch(pickupQueueProvider);
    final activeDelegates = ref.watch(activeDelegatesProvider);
    final latestAnnouncement = ref.watch(announcementsProvider).first;
    final nextPickup = queue.first;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (!environment.firebaseConfigured) ...[
          DashboardCard(
            title: 'Running without Firebase',
            subtitle:
                'The app shell uses local mock data until Auth, Firestore, and FCM are configured.',
            icon: Icons.cloud_off_rounded,
            child: const Text(
              'Navigation, theme, and dismissal concepts are ready now, so the team can iterate on flow before backend wiring.',
            ),
          ),
          const SizedBox(height: 16),
        ],
        DashboardCard(
          title: 'Dismissal status at a glance',
          subtitle: 'Geofence means approaching. NFC means verified on-site.',
          icon: Icons.route_rounded,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  StatusPill(
                    label: nextPickup.presenceState.label,
                    icon: nextPickup.presenceState == PresenceState.approaching
                        ? Icons.near_me_rounded
                        : Icons.schedule_rounded,
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.secondaryContainer,
                    foregroundColor: Theme.of(
                      context,
                    ).colorScheme.onSecondaryContainer,
                  ),
                  StatusPill(
                    label: nextPickup.isNfcVerified
                        ? 'Verified on-site'
                        : 'Awaiting NFC tap',
                    icon: nextPickup.isNfcVerified
                        ? Icons.nfc_rounded
                        : Icons.nfc_outlined,
                    backgroundColor: nextPickup.isNfcVerified
                        ? Theme.of(context).colorScheme.primaryContainer
                        : Theme.of(context).colorScheme.surface,
                    foregroundColor: nextPickup.isNfcVerified
                        ? Theme.of(context).colorScheme.onPrimaryContainer
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                '${nextPickup.studentName} is currently tied to ${nextPickup.guardianName} at ${nextPickup.pickupZone}. Staff release stays locked until NFC verification succeeds.',
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        DashboardCard(
          title: 'Pickup flow',
          subtitle: 'What this milestone enforces in the UI shell.',
          icon: Icons.rule_folder_outlined,
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _FlowStep(
                index: '1',
                text:
                    'Approaching is triggered by geofence entry and places the student in the live queue.',
              ),
              SizedBox(height: 10),
              _FlowStep(
                index: '2',
                text:
                    'On-site NFC verification upgrades the request from approaching to verified.',
              ),
              SizedBox(height: 10),
              _FlowStep(
                index: '3',
                text:
                    'Teacher/staff release is allowed only after verification is visible in the queue.',
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        DashboardCard(
          title: 'Active delegates',
          subtitle: '${activeDelegates.length} currently available for pickup.',
          icon: Icons.groups_2_outlined,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final delegate in activeDelegates)
                Chip(
                  label: Text('${delegate.name} • ${delegate.relationship}'),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        DashboardCard(
          title: latestAnnouncement.title,
          subtitle: latestAnnouncement.sentAtLabel,
          icon: Icons.campaign_rounded,
          child: Text(latestAnnouncement.body),
        ),
      ],
    );
  }
}

class _FlowStep extends StatelessWidget {
  const _FlowStep({required this.index, required this.text});

  final String index;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(radius: 14, child: Text(index)),
        const SizedBox(width: 12),
        Expanded(child: Text(text)),
      ],
    );
  }
}
