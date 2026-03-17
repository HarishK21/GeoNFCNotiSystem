import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/app_providers.dart';
import '../../../../core/widgets/dashboard_card.dart';
import '../../../../core/widgets/pickup_request_card.dart';

class StaffQueueScreen extends ConsumerWidget {
  const StaffQueueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queue = ref.watch(pickupQueueProvider);
    final releaseReady = ref.watch(releaseReadyQueueProvider).length;
    final pendingVerification = ref
        .watch(pendingVerificationQueueProvider)
        .length;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        DashboardCard(
          title: 'Live release queue',
          subtitle:
              '$releaseReady ready for release • $pendingVerification still blocked',
          icon: Icons.local_shipping_outlined,
          child: const Text(
            'Staff should only release a student when the queue shows verified on-site. Approaching status alone is not enough.',
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
