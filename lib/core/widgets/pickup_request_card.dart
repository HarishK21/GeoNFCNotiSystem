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
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
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
                      ? 'Verified on-site'
                      : 'Verification pending',
                  icon: request.isNfcVerified
                      ? Icons.verified_user_rounded
                      : Icons.pending_actions_rounded,
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
            if (request.hasException) ...[
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.flag_rounded,
                    color: colorScheme.error,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      request.exceptionFlag!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (showReleaseState) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Icon(
                    request.isReleased
                        ? Icons.task_alt_rounded
                        : (request.canRelease
                              ? Icons.verified_rounded
                              : Icons.pending_actions_rounded),
                    color: request.isReleased
                        ? colorScheme.tertiary
                        : (request.canRelease
                              ? colorScheme.primary
                              : colorScheme.error),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _releaseMessage(),
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

  String _releaseMessage() {
    if (request.isReleased) {
      return 'This student has already been released.';
    }
    if (request.canRelease) {
      return 'Staff can release this student now.';
    }
    if (request.canVerify) {
      return 'Staff can verify this student next, then confirm release.';
    }
    return 'This pickup is not ready for release yet.';
  }

  IconData _presenceIcon(PresenceState state) {
    return switch (state) {
      PresenceState.pending => Icons.schedule_rounded,
      PresenceState.approaching => Icons.near_me_rounded,
      PresenceState.verified => Icons.verified_user_rounded,
      PresenceState.released => Icons.task_alt_rounded,
    };
  }

  Color _presenceBackground(BuildContext context, PresenceState state) {
    final colorScheme = Theme.of(context).colorScheme;
    return switch (state) {
      PresenceState.pending => colorScheme.surface,
      PresenceState.approaching => colorScheme.secondaryContainer,
      PresenceState.verified => colorScheme.primaryContainer,
      PresenceState.released => colorScheme.tertiaryContainer,
    };
  }

  Color _presenceForeground(BuildContext context, PresenceState state) {
    final colorScheme = Theme.of(context).colorScheme;
    return switch (state) {
      PresenceState.pending => colorScheme.onSurfaceVariant,
      PresenceState.approaching => colorScheme.onSecondaryContainer,
      PresenceState.verified => colorScheme.onPrimaryContainer,
      PresenceState.released => colorScheme.onTertiaryContainer,
    };
  }
}
