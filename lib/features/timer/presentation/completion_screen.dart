import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/ayutam_app.dart';
import '../../../app/app_shell.dart';
import '../../../app/providers.dart';
import '../../../core/time/duration_format.dart';
import 'timer_screen.dart';

class CompletionScreen extends ConsumerWidget {
  const CompletionScreen({super.key, this.skillId});

  final String? skillId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapAsync = ref.watch(timerSessionProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Session complete')),
      body: snapAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (snap) {
          final seconds =
              snap.session?.activeSeconds ?? snap.displayActiveSeconds;
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),
                Text(
                  'Active practice',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  formatActiveDuration(seconds),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    fontFamily: 'monospace',
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Notes and tags arrive in a later phase.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: () async {
                    final error = await ref
                        .read(timerSessionProvider.notifier)
                        .saveCompletion();
                    if (!context.mounted) {
                      return;
                    }
                    if (error != null) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(error)));
                      return;
                    }
                    ref.invalidate(activeSkillsProvider);
                    await _goHome(context, ref);
                  },
                  child: const Text('Save'),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () async {
                    final error = await ref
                        .read(timerSessionProvider.notifier)
                        .resumeFromCompletion();
                    if (!context.mounted) {
                      return;
                    }
                    if (error != null) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(error)));
                      return;
                    }
                    await Navigator.of(context).pushReplacement(
                      MaterialPageRoute<void>(
                        builder: (_) => TimerScreen(skillId: skillId),
                      ),
                    );
                  },
                  child: const Text('Resume'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Discard session?'),
                        content: const Text(
                          'This deletes the session and its segments. '
                          'This cannot be undone.',
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
                    if (ok != true || !context.mounted) {
                      return;
                    }
                    final error = await ref
                        .read(timerSessionProvider.notifier)
                        .discardCompletion();
                    if (!context.mounted) {
                      return;
                    }
                    if (error != null) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(error)));
                      return;
                    }
                    await _goHome(context, ref);
                  },
                  child: const Text('Discard'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

Future<void> _goHome(BuildContext context, WidgetRef ref) async {
  ref.invalidate(startupGateProvider);
  final nav = ayutamNavigatorKey.currentState;
  if (nav != null) {
    await nav.pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const AppShell()),
      (_) => false,
    );
  } else if (context.mounted) {
    await Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const AppShell()),
      (_) => false,
    );
  }
}
