import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/pickup_request.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/widgets/content_state_card.dart';
import '../../../../core/widgets/dashboard_card.dart';
import '../../../../core/widgets/pickup_request_card.dart';
import '../../../../domain/models/pickup_queue_entry.dart';
import '../widgets/workflow_action_feedback.dart';

class StaffQueueScreen extends ConsumerWidget {
  const StaffQueueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queueState = ref.watch(queueEntriesStreamProvider);
    final workflowAction = ref.watch(workflowActionControllerProvider);
    final deviceAction = ref.watch(deviceActionControllerProvider);
    final debugEnabled = ref.watch(deviceDebugEnabledProvider);
    final liveQueue = ref.watch(liveQueueEntriesProvider);
    final releaseReady = liveQueue.where((entry) => entry.canRelease).length;
    final pendingVerification = liveQueue
        .where((entry) => entry.canVerify)
        .length;
    final loadError = queueState.hasError ? queueState.error : null;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (workflowAction.isLoading || deviceAction.isLoading) ...[
          const LinearProgressIndicator(),
          const SizedBox(height: 16),
        ],
        DashboardCard(
          title: 'Live release queue',
          subtitle:
              '$releaseReady ready for release | $pendingVerification waiting on NFC verification',
          icon: Icons.local_shipping_outlined,
          child: const Text(
            'Approaching is driven by geofencing and verified is driven by NFC. Release remains locked until the queue shows verified on-site.',
          ),
        ),
        const SizedBox(height: 16),
        if (loadError != null) ...[
          ContentStateCard.error(
            title: 'Could not load the live queue',
            message: '$loadError',
          ),
          const SizedBox(height: 16),
        ],
        if (queueState.isLoading && liveQueue.isEmpty) ...[
          const ContentStateCard.loading(
            title: 'Loading live queue',
            message: 'Waiting for repository-backed queue updates.',
          ),
        ] else if (liveQueue.isEmpty) ...[
          const ContentStateCard.empty(
            title: 'No active pickups in queue',
            message:
                'When guardians trigger the pickup flow, live queue entries will appear here.',
          ),
        ] else ...[
          for (final entry in liveQueue) ...[
            PickupRequestCard(
              request: _toRequest(entry),
              showReleaseState: true,
              footer: _QueueActions(entry: entry, debugEnabled: debugEnabled),
            ),
            const SizedBox(height: 16),
          ],
        ],
      ],
    );
  }
}

class _QueueActions extends ConsumerWidget {
  const _QueueActions({required this.entry, required this.debugEnabled});

  final PickupQueueEntry entry;
  final bool debugEnabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final buttons = <Widget>[];

    if (entry.canRelease) {
      buttons.add(
        FilledButton.icon(
          onPressed: () async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Confirm release'),
                content: Text(
                  'Release ${entry.studentName} to ${entry.guardianName} now?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Release'),
                  ),
                ],
              ),
            );

            if (confirmed != true || !context.mounted) {
              return;
            }

            await runWorkflowAction(
              context,
              ref,
              successMessage: '${entry.studentName} released successfully.',
              action: () => ref
                  .read(workflowActionControllerProvider.notifier)
                  .releaseStudent(entry),
            );
          },
          icon: const Icon(Icons.task_alt_rounded),
          label: const Text('Confirm release'),
        ),
      );
    }

    if (debugEnabled && !entry.canMarkApproaching) {
      buttons.add(
        OutlinedButton.icon(
          onPressed: () => _runDeviceAction(
            context,
            ref,
            successMessage: '${entry.studentName} reset to pending.',
            action: () => ref
                .read(deviceActionControllerProvider.notifier)
                .resetQueueState(entry.studentId),
          ),
          icon: const Icon(Icons.restart_alt_rounded),
          label: const Text('Reset queue'),
        ),
      );
    }

    if (buttons.isEmpty) {
      return Text(
        entry.canVerify
            ? 'Use the Student Lookup tab to arm Android NFC verification or simulate it in debug mode.'
            : (entry.hasException
                  ? 'Resolve the current exception flag from the Flags tab if follow-up is needed.'
                  : 'No additional staff actions are available for this queue item.'),
      );
    }

    return Wrap(spacing: 12, runSpacing: 12, children: buttons);
  }
}

PickupRequest _toRequest(PickupQueueEntry entry) {
  return PickupRequest(
    queueEntryId: entry.id,
    studentId: entry.studentId,
    guardianId: entry.guardianId,
    studentName: entry.studentName,
    guardianName: entry.guardianName,
    homeroom: entry.homeroom,
    pickupZone: entry.pickupZone,
    etaLabel: entry.etaLabel,
    presenceState: toPresenceState(entry.eventType),
    isNfcVerified: entry.isNfcVerified,
    exceptionFlag: entry.exceptionFlag,
  );
}

Future<void> _runDeviceAction(
  BuildContext context,
  WidgetRef ref, {
  required String successMessage,
  required Future<void> Function() action,
}) async {
  await action();
  if (!context.mounted) {
    return;
  }

  final state = ref.read(deviceActionControllerProvider);
  final messenger = ScaffoldMessenger.of(context);
  if (state.hasError) {
    messenger.showSnackBar(
      SnackBar(content: Text('Device action failed: ${state.error}')),
    );
    return;
  }

  messenger.showSnackBar(SnackBar(content: Text(successMessage)));
}
