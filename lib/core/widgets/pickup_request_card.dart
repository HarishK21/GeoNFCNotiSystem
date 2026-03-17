import 'package:flutter/material.dart';

import '../models/pickup_request.dart';
import '../models/presence_state.dart';
import 'status_pill.dart';

class PickupRequestCard extends StatelessWidget {
  const PickupRequestCard({
    super.key,
    required this.request,
    required this.showReleaseState,
  });

  final PickupRequest request;
  final bool showReleaseState;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.studentName,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${request.guardianName} • ${request.homeroom}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                Text(
                  request.etaLabel,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                StatusPill(
                  label: request.presenceState.label,
                  icon: _presenceIcon(request.presenceState),
                  backgroundColor: _presenceBackground(
                    context,
                    request.presenceState,
                  ),
                  foregroundColor: _presenceForeground(
                    context,
                    request.presenceState,
                  ),
                ),
                StatusPill(
                  label: request.isNfcVerified
                      ? 'NFC verified'
                      : 'Awaiting NFC tap',
                  icon: request.isNfcVerified
                      ? Icons.nfc_rounded
                      : Icons.nfc_outlined,
                  backgroundColor: request.isNfcVerified
                      ? colorScheme.tertiaryContainer
                      : colorScheme.surface,
                  foregroundColor: request.isNfcVerified
                      ? colorScheme.onTertiaryContainer
                      : colorScheme.onSurfaceVariant,
                ),
                StatusPill(
                  label: request.pickupZone,
                  icon: Icons.place_outlined,
                  backgroundColor: colorScheme.surface,
                  foregroundColor: colorScheme.onSurface,
                ),
              ],
            ),
            if (showReleaseState) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Icon(
                    request.canRelease
                        ? Icons.verified_rounded
                        : Icons.pending_actions_rounded,
                    color: request.canRelease
                        ? colorScheme.primary
                        : colorScheme.error,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      request.canRelease
                          ? 'Staff can release this student now.'
                          : 'Release is blocked until on-site NFC verification completes.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _presenceIcon(PresenceState state) {
    return switch (state) {
      PresenceState.queued => Icons.schedule_rounded,
      PresenceState.approaching => Icons.near_me_rounded,
      PresenceState.verified => Icons.verified_user_rounded,
    };
  }

  Color _presenceBackground(BuildContext context, PresenceState state) {
    final colorScheme = Theme.of(context).colorScheme;
    return switch (state) {
      PresenceState.queued => colorScheme.surface,
      PresenceState.approaching => colorScheme.secondaryContainer,
      PresenceState.verified => colorScheme.primaryContainer,
    };
  }

  Color _presenceForeground(BuildContext context, PresenceState state) {
    final colorScheme = Theme.of(context).colorScheme;
    return switch (state) {
      PresenceState.queued => colorScheme.onSurfaceVariant,
      PresenceState.approaching => colorScheme.onSecondaryContainer,
      PresenceState.verified => colorScheme.onPrimaryContainer,
    };
  }
}
