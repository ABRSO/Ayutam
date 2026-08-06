import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_theme.dart';
import '../../../app/ayutam_app.dart';
import '../../../app/providers.dart';
import '../../../core/time/duration_format.dart';
import '../../skills/domain/skill.dart';
import '../domain/models.dart';
import 'timer_screen.dart';

Future<void> showPreSessionSheet(BuildContext context, {required Skill skill}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => PreSessionSheet(skill: skill),
  );
}

class PreSessionSheet extends ConsumerWidget {
  const PreSessionSheet({super.key, required this.skill});

  final Skill skill;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final media = MediaQuery.of(context);
    final active = ref.watch(timerSessionProvider).asData?.value.session;
    final blocking = active != null && active.status.isInProgress;

    // Cap height so the sheet can scroll on short landscape viewports instead
    // of clipping Start / Cancel (or Open active timer) below the screen edge.
    final maxHeight = media.size.height * 0.92;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(skill.name, style: theme.textTheme.titleLarge),
                        const SizedBox(height: 8),
                        Text(
                          '${formatHoursMinutes(skill.completedActiveSeconds)} of '
                          '${formatHoursMinutes(skill.targetSeconds)}',
                          style: durationMonoStyle(
                            context,
                            base: theme.textTheme.bodyMedium,
                          ).copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: 16),
                        if (blocking)
                          _ActiveSessionConflictBody(
                            requested: skill,
                            active: active,
                          )
                        else
                          const _StartSessionBody(),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (blocking)
                  _ActiveSessionConflictActions(
                    requested: skill,
                    active: active,
                  )
                else
                  _StartSessionActions(skill: skill),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StartSessionBody extends StatelessWidget {
  const _StartSessionBody();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Mode: Stopwatch',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Pomodoro arrives in a later phase. This session tracks '
          'active practice time only.',
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _StartSessionActions extends ConsumerWidget {
  const _StartSessionActions({required this.skill});

  final Skill skill;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          onPressed: () async {
            final messenger = ScaffoldMessenger.of(context);
            final nav = Navigator.of(context);
            final error = await ref
                .read(timerSessionProvider.notifier)
                .startStopwatch(skill.id);
            if (error != null) {
              messenger.showSnackBar(SnackBar(content: Text(error)));
              return;
            }
            nav.pop();
            await _openTimer(skill.id);
          },
          icon: const Icon(Icons.play_arrow),
          label: const Text('Start'),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

/// Only one session may be active, paused, or completion-pending, so starting
/// another skill has to resolve the current one first.
class _ActiveSessionConflictBody extends ConsumerWidget {
  const _ActiveSessionConflictBody({
    required this.requested,
    required this.active,
  });

  final Skill requested;
  final PracticeSession active;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final sameSkill = active.skillId == requested.id;
    final activeName = _skillName(ref, active.skillId);

    return Text(
      sameSkill
          ? 'This skill already has a session in progress.'
          : 'A session for ${activeName ?? 'another skill'} is already in '
                'progress.',
      style: theme.textTheme.bodyMedium,
    );
  }
}

class _ActiveSessionConflictActions extends ConsumerWidget {
  const _ActiveSessionConflictActions({
    required this.requested,
    required this.active,
  });

  final Skill requested;
  final PracticeSession active;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sameSkill = active.skillId == requested.id;
    final activeName = _skillName(ref, active.skillId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          onPressed: () async {
            Navigator.of(context).pop();
            await _openTimer(active.skillId);
          },
          icon: const Icon(Icons.timer_outlined),
          label: const Text('Open active timer'),
        ),
        if (!sameSkill) ...[
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => _stopActiveAndStart(context, ref, activeName),
            child: const Text('Stop active and start this'),
          ),
        ],
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  Future<void> _stopActiveAndStart(
    BuildContext context,
    WidgetRef ref,
    String? activeName,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Stop active session?'),
        content: SingleChildScrollView(
          child: Text(
            'The session for ${activeName ?? 'the active skill'} will be stopped '
            'and saved, then a new session starts for ${requested.name}.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Stop and save'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    final notifier = ref.read(timerSessionProvider.notifier);

    final stopError = await notifier.stop();
    if (stopError != null) {
      messenger.showSnackBar(SnackBar(content: Text(stopError)));
      return;
    }
    final saveError = await notifier.saveCompletion();
    if (saveError != null) {
      messenger.showSnackBar(SnackBar(content: Text(saveError)));
      return;
    }
    ref.invalidate(activeSkillsProvider);
    final startError = await notifier.startStopwatch(requested.id);
    if (startError != null) {
      messenger.showSnackBar(SnackBar(content: Text(startError)));
      return;
    }
    nav.pop();
    await _openTimer(requested.id);
  }
}

Future<void> _openTimer(String skillId) async {
  await ayutamNavigatorKey.currentState?.push(
    MaterialPageRoute<void>(builder: (_) => TimerScreen(skillId: skillId)),
  );
}

String? _skillName(WidgetRef ref, String skillId) {
  final skills = ref.watch(activeSkillsProvider).asData?.value;
  if (skills == null) {
    return null;
  }
  for (final skill in skills) {
    if (skill.id == skillId) {
      return skill.name;
    }
  }
  return null;
}
