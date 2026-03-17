import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/app_providers.dart';
import '../../../../core/widgets/dashboard_card.dart';
import '../../../../core/widgets/pickup_request_card.dart';

class StaffVerificationScreen extends ConsumerWidget {
  const StaffVerificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingVerification = ref.watch(pendingVerificationQueueProvider);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        DashboardCard(
          title: 'Android NFC verification',
          subtitle:
              'This Android-first placeholder reserves the flow for native NFC integration.',
          icon: Icons.nfc_rounded,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Teachers and front-office staff will tap a guardian device or card on-site to unlock release eligibility.',
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: null,
                  icon: const Icon(Icons.phonelink_setup_rounded),
                  label: const Text('Wire Android NFC channel next milestone'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        for (final request in pendingVerification) ...[
          PickupRequestCard(request: request, showReleaseState: true),
          const SizedBox(height: 16),
        ],
      ],
    );
  }
}
