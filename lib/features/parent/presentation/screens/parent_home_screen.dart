import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/pickup_request.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/widgets/content_state_card.dart';
import '../../../../core/widgets/dashboard_card.dart';
import '../../../../core/widgets/pickup_request_card.dart';
import '../../../../domain/models/geofence_target.dart';
import '../../../../domain/models/geofencing_status.dart';
import '../../../../domain/models/pickup_queue_entry.dart';
import '../../../../domain/models/student.dart';

class ParentHomeScreen extends ConsumerWidget {
  const ParentHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final environment = ref.watch(appEnvironmentProvider);
    final workflowAction = ref.watch(workflowActionControllerProvider);
    final deviceAction = ref.watch(deviceActionControllerProvider);
    final authGate = ref.watch(authGateStateProvider);
    final geofencingStatus = ref.watch(geofencingStatusProvider);
    final studentsState = ref.watch(studentsFutureProvider);
    final guardiansState = ref.watch(guardiansFutureProvider);
    final queueState = ref.watch(queueEntriesStreamProvider);
    final schoolState = ref.watch(activeSchoolProvider);
    final familyStudents = ref.watch(familyStudentsProvider);
    final familyQueueEntries = ref.watch(familyQueueEntriesProvider);
    final familyQueue = ref.watch(familyPickupQueueProvider);
    final activeDelegates = ref.watch(familyDelegatesProvider);
    final geofenceTargets = ref.watch(activeGeofenceTargetsProvider);
    final debugEnabled = ref.watch(deviceDebugEnabledProvider);
    final announcements = ref.watch(announcementsProvider);
    final latestAnnouncement = announcements.isNotEmpty
        ? announcements.first
        : null;
    final geofenceTargetByStudentId = {
      for (final target in geofenceTargets) target.studentId: target,
    };
    final loadError = _firstError([
      studentsState,
      guardiansState,
      queueState,
      schoolState,
    ]);
    final isLoading =
        studentsState.isLoading ||
        guardiansState.isLoading ||
        queueState.isLoading ||
        schoolState.isLoading;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (workflowAction.isLoading || deviceAction.isLoading) ...[
          const LinearProgressIndicator(),
          const SizedBox(height: 16),
        ],
        if (loadError != null) ...[
          ContentStateCard.error(
            title: 'Could not fully load today\'s pickup plan',
            message: '$loadError',
          ),
          const SizedBox(height: 16),
        ],
        if (!environment.firebaseConfigured) ...[
          DashboardCard(
            title: 'Running without Firebase',
            subtitle:
                'The app shell uses local mock data until Auth and Firestore are configured.',
            icon: Icons.cloud_off_rounded,
            child: const Text(
              'This milestone keeps the device workflow structure in place while mock repositories and debug simulation power the data and actions.',
            ),
          ),
          const SizedBox(height: 16),
        ],
        DashboardCard(
          title: authGate.profile?.displayName ?? 'Parent pickup overview',
          subtitle:
              schoolState.asData?.value?.name ?? 'Resolving school profile',
          icon: Icons.family_restroom_rounded,
          child: Text(
            activeDelegates.isEmpty
                ? 'Today\'s dismissal is tied to your primary guardian profile. Add a one-time delegate from the Guardians tab when someone else will handle pickup.'
                : '${activeDelegates.length} delegate'
                      '${activeDelegates.length == 1 ? ' is' : 's are'} active for today\'s pickup window.',
          ),
        ),
        const SizedBox(height: 16),
        _GeofencingCard(
          status: geofencingStatus,
          targetCount: geofenceTargets.length,
        ),
        const SizedBox(height: 16),
        const DashboardCard(
          title: 'Today\'s pickup rules',
          subtitle:
              'Approaching and verified stay separate states in app logic.',
          icon: Icons.rule_folder_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _FlowStep(
                index: '1',
                text:
                    'Pending means a pickup plan exists, but the guardian has not started the handoff flow yet.',
              ),
              SizedBox(height: 10),
              _FlowStep(
                index: '2',
                text:
                    'Approaching is driven by Android geofence entry. In debug mode you can simulate it without moving the device.',
              ),
              SizedBox(height: 10),
              _FlowStep(
                index: '3',
                text:
                    'Verified means on-site confirmation is complete. Staff release happens only after that state is visible.',
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (isLoading &&
            familyStudents.isEmpty &&
            familyQueueEntries.isEmpty) ...[
          const ContentStateCard.loading(
            title: 'Loading family pickup plan',
            message: 'Resolving students, queue state, and linked guardians.',
          ),
          const SizedBox(height: 16),
        ] else if (familyStudents.isEmpty) ...[
          const ContentStateCard.empty(
            title: 'No linked students',
            message:
                'This parent profile does not currently map to any student records.',
          ),
          const SizedBox(height: 16),
        ] else ...[
          for (final student in familyStudents) ...[
            _StudentPlanCard(
              student: student,
              queueEntry: familyQueueEntries
                  .where((entry) => entry.studentId == student.id)
                  .firstOrNull,
              request: familyQueue
                  .where((request) => request.studentId == student.id)
                  .firstOrNull,
              geofenceTarget: geofenceTargetByStudentId[student.id],
              debugEnabled: debugEnabled,
            ),
            const SizedBox(height: 16),
          ],
        ],
        DashboardCard(
          title: latestAnnouncement?.title ?? 'Announcements will appear here',
          subtitle:
              latestAnnouncement?.sentAtLabel ??
              'Waiting for announcement feed data.',
          icon: Icons.campaign_rounded,
          child: Text(
            latestAnnouncement?.body ??
                'The repository layer is active, but no announcement documents have been emitted yet.',
          ),
        ),
      ],
    );
  }
}

class _GeofencingCard extends ConsumerWidget {
  const _GeofencingCard({required this.status, required this.targetCount});

  final AsyncValue<GeofencingStatus> status;
  final int targetCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canRequestPermission =
        status.asData?.value.supported == true &&
        status.asData?.value.permissionGranted == false;

    return DashboardCard(
      title: 'Android geofencing',
      subtitle: 'Approaching is driven by Android location events.',
      icon: Icons.near_me_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            status.when(
              data: (value) {
                if (!value.supported) {
                  return value.detail;
                }
                if (value.canMonitor) {
                  return 'Monitoring $targetCount family target'
                      '${targetCount == 1 ? '' : 's'} around the school geofence.';
                }
                return value.detail;
              },
              error: (error, stackTrace) =>
                  'Could not read Android geofencing status: $error',
              loading: () =>
                  'Checking Android location permission and monitoring state.',
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(
                label: Text(
                  status.asData?.value.supported == true
                      ? 'Android supported'
                      : 'Stubbed elsewhere',
                ),
              ),
              Chip(
                label: Text(
                  '$targetCount active target${targetCount == 1 ? '' : 's'}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              if (canRequestPermission)
                FilledButton.icon(
                  onPressed: () => _runDeviceAction(
                    context,
                    ref,
                    successMessage: 'Requested Android location access.',
                    action: () => ref
                        .read(deviceActionControllerProvider.notifier)
                        .requestGeofencePermission(),
                  ),
                  icon: const Icon(Icons.location_on_outlined),
                  label: const Text('Grant location access'),
                ),
              OutlinedButton.icon(
                onPressed: () => ref
                    .read(deviceActionControllerProvider.notifier)
                    .refreshGeofencingStatus(),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Refresh geofencing'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StudentPlanCard extends ConsumerWidget {
  const _StudentPlanCard({
    required this.student,
    required this.queueEntry,
    required this.request,
    required this.geofenceTarget,
    required this.debugEnabled,
  });

  final Student student;
  final PickupQueueEntry? queueEntry;
  final PickupRequest? request;
  final GeofenceTarget? geofenceTarget;
  final bool debugEnabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DashboardCard(
      title: student.displayName,
      subtitle:
          '${student.gradeLevel} | ${student.homeroom} | ${student.pickupZone}',
      icon: Icons.directions_walk_rounded,
      child: request == null
          ? const Text(
              'No active pickup request is in the queue for this student yet.',
            )
          : PickupRequestCard(
              request: request!,
              showReleaseState: true,
              footer: _StudentPlanActions(
                request: request!,
                queueEntry: queueEntry,
                geofenceTarget: geofenceTarget,
                debugEnabled: debugEnabled,
              ),
            ),
    );
  }
}

class _StudentPlanActions extends ConsumerWidget {
  const _StudentPlanActions({
    required this.request,
    required this.queueEntry,
    required this.geofenceTarget,
    required this.debugEnabled,
  });

  final PickupRequest request;
  final PickupQueueEntry? queueEntry;
  final GeofenceTarget? geofenceTarget;
  final bool debugEnabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final buttons = <Widget>[];

    if (debugEnabled &&
        geofenceTarget != null &&
        queueEntry != null &&
        queueEntry!.canMarkApproaching) {
      buttons.add(
        FilledButton.icon(
          onPressed: () => _runDeviceAction(
            context,
            ref,
            successMessage: '${request.studentName} marked as approaching.',
            action: () => ref
                .read(deviceActionControllerProvider.notifier)
                .simulateApproaching(geofenceTarget!),
          ),
          icon: const Icon(Icons.near_me_rounded),
          label: const Text('Simulate approaching'),
        ),
      );
    }

    if (debugEnabled && queueEntry != null && !queueEntry!.canMarkApproaching) {
      buttons.add(
        OutlinedButton.icon(
          onPressed: () => _runDeviceAction(
            context,
            ref,
            successMessage: '${request.studentName} reset to pending.',
            action: () => ref
                .read(deviceActionControllerProvider.notifier)
                .resetQueueState(request.studentId),
          ),
          icon: const Icon(Icons.restart_alt_rounded),
          label: const Text('Reset queue state'),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          request.presenceState.detail,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        if (buttons.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(spacing: 12, runSpacing: 12, children: buttons),
        ],
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

extension _FirstOrNullExtension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

Object? _firstError(Iterable<AsyncValue<dynamic>> values) {
  for (final value in values) {
    if (value.hasError) {
      return value.error;
    }
  }
  return null;
}
