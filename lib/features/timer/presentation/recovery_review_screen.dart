import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/ayutam_app.dart';
import '../../../app/app_shell.dart';
import '../../../app/providers.dart';
import '../../../core/time/duration_format.dart';
import '../domain/models.dart';
import 'completion_screen.dart';
import 'timer_screen.dart';

class RecoveryReviewScreen extends ConsumerWidget {
  const RecoveryReviewScreen({
    super.key,
    this.skillId,
    this.proposedActiveSeconds,
    this.lastHeartbeatUtc,
    this.reason,
  });

  final String? skillId;
  final int? proposedActiveSeconds;
  final DateTime? lastHeartbeatUtc;
  final RecoveryReason? reason;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final reasonLabel = switch (reason) {
      RecoveryReason.longGap => 'Long gap since last heartbeat',
      RecoveryReason.clockChange => 'Clock anomaly detected',
      RecoveryReason.restart => 'Unexpected restart',
      null => 'Session needs review',
    };

    return Scaffold(
      appBar: AppBar(title: const Text('Recovery review')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(reasonLabel, style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            Text(
              'Proposed active time if the full gap is included: '
              '${formatActiveDuration(proposedActiveSeconds ?? 0)}',
            ),
            if (lastHeartbeatUtc != null) ...[
              const SizedBox(height: 8),
              Text(
                'Last heartbeat (UTC): ${lastHeartbeatUtc!.toIso8601String()}',
                style: theme.textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 8),
            Text(
              'Choose how to resolve the interrupted session. '
              'Ayutam never silently discards in-progress work.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const Spacer(),
            FilledButton(
              onPressed: () =>
                  _apply(context, ref, RecoveryDecision.includeFullGap),
              child: const Text('Include full gap'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () =>
                  _apply(context, ref, RecoveryDecision.trimToHeartbeat),
              child: const Text('Trim to last heartbeat'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () async {
                final end = await showDatePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now().add(const Duration(days: 1)),
                  initialDate: DateTime.now(),
                );
                if (end == null || !context.mounted) {
                  return;
                }
                final time = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.now(),
                );
                if (time == null || !context.mounted) {
                  return;
                }
                final edited = DateTime(
                  end.year,
                  end.month,
                  end.day,
                  time.hour,
                  time.minute,
                ).toUtc();
                await _apply(
                  context,
                  ref,
                  RecoveryDecision.editEnd,
                  editedEndUtc: edited,
                );
              },
              child: const Text('Edit end time'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Discard session?'),
                    content: const Text(
                      'Deletes the interrupted session permanently.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Discard'),
                      ),
                    ],
                  ),
                );
                if (ok == true && context.mounted) {
                  await _apply(context, ref, RecoveryDecision.discard);
                }
              },
              child: const Text('Discard session'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _apply(
    BuildContext context,
    WidgetRef ref,
    RecoveryDecision decision, {
    DateTime? editedEndUtc,
  }) async {
    final error = await ref
        .read(timerSessionProvider.notifier)
        .applyRecovery(decision: decision, editedEndUtc: editedEndUtc);
    if (!context.mounted) {
      return;
    }
    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    final snap = await ref.read(timerSessionProvider.future);
    ref.invalidate(activeSkillsProvider);

    if (!context.mounted) {
      return;
    }

    switch (snap.runtime.machineState) {
      case TimerMachineState.running:
      case TimerMachineState.paused:
        await _replace(
          context,
          TimerScreen(skillId: skillId ?? snap.session?.skillId),
        );
      case TimerMachineState.completionPending:
        await _replace(
          context,
          CompletionScreen(skillId: skillId ?? snap.session?.skillId),
        );
      case TimerMachineState.idle:
      case TimerMachineState.recoveryReview:
        ref.invalidate(startupGateProvider);
        await ayutamNavigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute<void>(builder: (_) => const AppShell()),
          (_) => false,
        );
    }
  }

  Future<void> _replace(BuildContext context, Widget page) {
    return Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute<void>(builder: (_) => page));
  }
}
