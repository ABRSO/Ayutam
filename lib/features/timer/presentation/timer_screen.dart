import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/ayutam_app.dart';
import '../../../app/providers.dart';
import '../../../core/time/duration_format.dart';
import '../domain/models.dart';
import 'completion_screen.dart';

class TimerScreen extends ConsumerStatefulWidget {
  const TimerScreen({super.key, this.skillId, this.embeddedInShell = false});

  final String? skillId;
  final bool embeddedInShell;

  @override
  ConsumerState<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends ConsumerState<TimerScreen> {
  Timer? _tick;
  Timer? _heartbeat;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
    _heartbeat = Timer.periodic(const Duration(seconds: 30), (_) {
      ref.read(timerSessionProvider.notifier).heartbeat();
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    _heartbeat?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final snapAsync = ref.watch(timerSessionProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stopwatch'),
        automaticallyImplyLeading: Navigator.canPop(context),
      ),
      body: snapAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (snap) {
          final display = _liveActiveSeconds(snap);
          final paused = snap.runtime.machineState == TimerMachineState.paused;
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Spacer(),
                  Text(
                    formatActiveDuration(display),
                    style: theme.textTheme.displayLarge?.copyWith(
                      fontFeatures: const [FontFeature.tabularFigures()],
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    paused ? 'Paused' : 'Running',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _ControlButton(
                        tooltip: paused ? 'Resume' : 'Pause',
                        icon: paused ? Icons.play_arrow : Icons.pause,
                        onPressed: () async {
                          final error = paused
                              ? await ref
                                    .read(timerSessionProvider.notifier)
                                    .resume()
                              : await ref
                                    .read(timerSessionProvider.notifier)
                                    .pause();
                          if (error != null && context.mounted) {
                            ScaffoldMessenger.of(
                              context,
                            ).showSnackBar(SnackBar(content: Text(error)));
                          }
                        },
                      ),
                      _ControlButton(
                        tooltip: 'Stop',
                        icon: Icons.stop,
                        onPressed: () async {
                          final error = await ref
                              .read(timerSessionProvider.notifier)
                              .stop();
                          if (!context.mounted) {
                            return;
                          }
                          if (error != null) {
                            ScaffoldMessenger.of(
                              context,
                            ).showSnackBar(SnackBar(content: Text(error)));
                            return;
                          }
                          await _goToCompletion(context);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  int _liveActiveSeconds(TimerSnapshot snap) {
    final clock = ref.read(clockServiceProvider);
    return TimerMath.activeSecondsFromSegments(
      segments: snap.segments,
      nowUtc: clock.nowUtc(),
    );
  }

  Future<void> _goToCompletion(BuildContext context) async {
    final route = MaterialPageRoute<void>(
      builder: (_) => CompletionScreen(skillId: widget.skillId),
    );
    if (Navigator.of(context).canPop()) {
      await Navigator.of(context).pushReplacement(route);
    } else {
      await ayutamNavigatorKey.currentState?.pushReplacement(route);
    }
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      height: 56,
      child: IconButton.filledTonal(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(icon, size: 28),
        style: IconButton.styleFrom(
          minimumSize: const Size(48, 48),
          fixedSize: const Size(56, 56),
        ),
      ),
    );
  }
}
