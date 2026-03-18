import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/app_providers.dart';
import '../../../../core/widgets/content_state_card.dart';
import '../../../../core/widgets/dashboard_card.dart';
import '../../../../domain/models/office_approval_status.dart';
import '../../../../domain/models/pickup_queue_entry.dart';
import '../widgets/workflow_action_feedback.dart';

class StaffAnnouncementsScreen extends ConsumerWidget {
  const StaffAnnouncementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queueState = ref.watch(queueEntriesStreamProvider);
    final workflowAction = ref.watch(workflowActionControllerProvider);
    final liveQueue = ref.watch(liveQueueEntriesProvider);
    final flaggedEntries = ref.watch(flaggedQueueEntriesProvider);
    final pendingApprovals = ref.watch(pendingOfficeApprovalsProvider);
    final readyToFlag = liveQueue
        .where((entry) => !entry.hasException)
        .toList(growable: false);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (workflowAction.isLoading) ...[
          const LinearProgressIndicator(),
          const SizedBox(height: 16),
        ],
        DashboardCard(
          title: 'Exception flags',
          subtitle:
              '${flaggedEntries.length} active flag${flaggedEntries.length == 1 ? '' : 's'} need staff attention | ${pendingApprovals.length} pending office approval${pendingApprovals.length == 1 ? '' : 's'}',
          icon: Icons.flag_rounded,
          child: const Text(
            'Flags do not replace verification and release rules. They provide a fast staff-visible note when a pickup needs extra attention.',
          ),
        ),
        const SizedBox(height: 16),
        if (queueState.hasError) ...[
          ContentStateCard.error(
            title: 'Could not load exception flags',
            message: '${queueState.error}',
          ),
          const SizedBox(height: 16),
        ],
        if (queueState.isLoading && liveQueue.isEmpty) ...[
          const ContentStateCard.loading(
            title: 'Loading exception workflow',
            message: 'Waiting for queue entries before showing flag controls.',
          ),
          const SizedBox(height: 16),
        ],
        if (flaggedEntries.isEmpty) ...[
          const ContentStateCard.empty(
            title: 'No active exception flags',
            message:
                'Flagged pickups will appear here so staff can clear them after follow-up.',
          ),
          const SizedBox(height: 16),
        ] else ...[
          for (final entry in flaggedEntries) ...[
            _FlaggedEntryCard(entry: entry),
            const SizedBox(height: 16),
          ],
        ],
        if (readyToFlag.isNotEmpty) ...[
          DashboardCard(
            title: 'Quick flag actions',
            subtitle: 'Add a staff note when a queue item needs review.',
            icon: Icons.flag_outlined,
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final entry in readyToFlag)
                  ActionChip(
                    avatar: const Icon(Icons.add_alert_rounded),
                    label: Text(entry.studentName),
                    onPressed: () => _openFlagDialog(context, ref, entry),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _openFlagDialog(
    BuildContext context,
    WidgetRef ref,
    PickupQueueEntry entry,
  ) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => const _FlagReasonDialog(),
    );
    if (reason == null || reason.trim().isEmpty) {
      return;
    }
    if (!context.mounted) {
      return;
    }

    await runWorkflowAction(
      context,
      ref,
      successMessage: 'Flag added for ${entry.studentName}.',
      action: () => ref
          .read(workflowActionControllerProvider.notifier)
          .flagException(entry, reason.trim()),
    );
  }
}

class _FlaggedEntryCard extends ConsumerWidget {
  const _FlaggedEntryCard({required this.entry});

  final PickupQueueEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final approval = ref.watch(officeApprovalByQueueEntryProvider(entry.id));
    final approvalLabel = switch (approval?.status) {
      OfficeApprovalStatus.pending => 'Approval pending',
      OfficeApprovalStatus.approved => 'Approved',
      OfficeApprovalStatus.denied => 'Denied',
      OfficeApprovalStatus.resolved => 'Resolved',
      null => 'Flagged',
    };

    return DashboardCard(
      title: entry.studentName,
      subtitle: '${entry.guardianName} | ${entry.pickupZone}',
      icon: Icons.flag_circle_rounded,
      trailing: Chip(label: Text(approvalLabel)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(entry.exceptionFlag ?? 'Flagged for follow-up.'),
          if (approval != null) ...[
            const SizedBox(height: 8),
            Text(
              'Office approval record: ${approval.status.name}. Requested by ${approval.requestedByName}.',
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              if (approval != null && !approval.isApproved)
                FilledButton.icon(
                  onPressed: () => runWorkflowAction(
                    context,
                    ref,
                    successMessage:
                        'Office approval granted for ${entry.studentName}.',
                    action: () => ref
                        .read(workflowActionControllerProvider.notifier)
                        .approveOfficeApproval(approval),
                  ),
                  icon: const Icon(Icons.verified_user_outlined),
                  label: const Text('Approve release'),
                ),
              if (approval != null)
                OutlinedButton.icon(
                  onPressed: () => runWorkflowAction(
                    context,
                    ref,
                    successMessage:
                        'Office approval updated for ${entry.studentName}.',
                    action: () => ref
                        .read(workflowActionControllerProvider.notifier)
                        .denyOfficeApproval(approval),
                  ),
                  icon: const Icon(Icons.block_outlined),
                  label: const Text('Deny release'),
                ),
              FilledButton.icon(
                onPressed: () => runWorkflowAction(
                  context,
                  ref,
                  successMessage: 'Flag cleared for ${entry.studentName}.',
                  action: () => ref
                      .read(workflowActionControllerProvider.notifier)
                      .clearException(entry),
                ),
                icon: const Icon(Icons.check_circle_outline_rounded),
                label: const Text('Clear flag'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FlagReasonDialog extends StatefulWidget {
  const _FlagReasonDialog();

  @override
  State<_FlagReasonDialog> createState() => _FlagReasonDialogState();
}

class _FlagReasonDialogState extends State<_FlagReasonDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add exception flag'),
      content: TextField(
        controller: _controller,
        decoration: const InputDecoration(
          labelText: 'Reason',
          hintText: 'Example: ID check needed or custody note follow-up',
        ),
        autofocus: true,
        minLines: 2,
        maxLines: 3,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: const Text('Flag'),
        ),
      ],
    );
  }
}
