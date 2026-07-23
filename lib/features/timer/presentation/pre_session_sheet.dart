import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/ayutam_app.dart';
import '../../../app/providers.dart';
import '../../skills/domain/skill.dart';
import 'timer_screen.dart';

Future<void> showPreSessionSheet(BuildContext context, {required Skill skill}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => PreSessionSheet(skill: skill),
  );
}

class PreSessionSheet extends ConsumerWidget {
  const PreSessionSheet({super.key, required this.skill});

  final Skill skill;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(skill.name, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Mode: Stopwatch',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pomodoro arrives in a later phase. This session tracks '
            'active practice time only.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 24),
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
              await ayutamNavigatorKey.currentState?.push(
                MaterialPageRoute<void>(
                  builder: (_) => TimerScreen(skillId: skill.id),
                ),
              );
            },
            icon: const Icon(Icons.play_arrow),
            label: const Text('Start'),
          ),
        ],
      ),
    );
  }
}
