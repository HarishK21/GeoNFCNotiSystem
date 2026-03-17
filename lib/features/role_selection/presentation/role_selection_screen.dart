import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/app_role.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/widgets/dashboard_card.dart';

class RoleSelectionScreen extends ConsumerWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final environment = ref.watch(appEnvironmentProvider);
    final currentProfile = ref.watch(currentUserProfileProvider);
    final school = ref.watch(activeSchoolProvider).asData?.value;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'GeoTap Guardian',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Android-first dismissal coordination for approaching detection, on-site NFC verification, and live release decisions.',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 20),
              DashboardCard(
                title: 'Current build mode',
                subtitle: environment.bootstrapMessage,
                icon: Icons.construction_rounded,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _ModeChip(
                      label: environment.isMockMode
                          ? 'Mock repositories'
                          : 'Firebase repositories',
                    ),
                    _ModeChip(
                      label: environment.androidFirst
                          ? 'Android-first'
                          : 'Cross-platform',
                    ),
                    _ModeChip(
                      label: environment.nfcEnabledFlows
                          ? 'NFC placeholders ready'
                          : 'NFC pending',
                    ),
                    _ModeChip(
                      label: environment.firebaseConfigured
                          ? 'Firebase connected'
                          : 'Firebase optional',
                    ),
                  ],
                ),
              ),
              if (currentProfile != null) ...[
                const SizedBox(height: 16),
                DashboardCard(
                  title: 'Resolved user profile',
                  subtitle: school?.name ?? currentProfile.schoolId,
                  icon: currentProfile.role == AppRole.parent
                      ? Icons.family_restroom_rounded
                      : Icons.badge_rounded,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${currentProfile.displayName} • ${currentProfile.role.label}',
                      ),
                      const SizedBox(height: 6),
                      Text(currentProfile.email),
                      if (currentProfile.phone case final phone?)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(phone),
                        ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              for (final role in AppRole.values) ...[
                _RoleCard(role: role),
                const SizedBox(height: 16),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({required this.role});

  final AppRole role;

  @override
  Widget build(BuildContext context) {
    return DashboardCard(
      title: role.label,
      subtitle: role.description,
      icon: role == AppRole.parent
          ? Icons.family_restroom_rounded
          : Icons.badge_rounded,
      trailing: Icon(
        Icons.arrow_forward_rounded,
        color: Theme.of(context).colorScheme.primary,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            role == AppRole.parent
                ? 'Parent flow surfaces queue status, delegation, and announcements before release.'
                : 'Staff flow keeps the queue visible while requiring NFC verification before release.',
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => context.go(role.defaultRoute),
              icon: const Icon(Icons.arrow_circle_right_outlined),
              label: Text('Open ${role.label} view'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(label: Text(label));
  }
}
