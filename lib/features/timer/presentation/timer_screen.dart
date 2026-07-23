import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_theme.dart';
import '../../../app/ayutam_app.dart';
import '../../../app/providers.dart';
import '../../../core/theme/skill_accent_palette.dart';
import '../../../core/time/duration_format.dart';
import '../../skills/domain/skill.dart';
import '../domain/models.dart';
import 'completion_screen.dart';
import 'widgets/flip_clock.dart';
import 'widgets/timer_icon_control.dart';

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
    final skillId = widget.skillId;
    final skills = ref.watch(activeSkillsProvider).asData?.value;
    Skill? skill;
    if (skillId != null && skills != null) {
      for (final s in skills) {
        if (s.id == skillId) {
          skill = s;
          break;
        }
      }
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(skill?.name ?? 'Stopwatch'),
        automaticallyImplyLeading: Navigator.canPop(context),
      ),
      body: snapAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (snap) {
          final sessionActive = _liveActiveSeconds(snap);
          final completed = skill?.completedActiveSeconds ?? 0;
          final accumulated = completed + sessionActive;
          final paused = snap.runtime.machineState == TimerMachineState.paused;
          final accent = SkillAccentPalette.fromArgb(
            skill?.accentArgb,
            fallback: theme.colorScheme.primary,
          );

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Column(
                children: [
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return Column(
                          children: [
                            Expanded(
                              flex: 7,
                              child: Center(
                                child: SizedBox(
                                  width: constraints.maxWidth,
                                  height: constraints.maxHeight * 0.72,
                                  child: FlipClock(
                                    totalSeconds: accumulated,
                                    semanticLabel:
                                        'Skill total ${formatFlipClockDuration(accumulated)}',
                                  ),
                                ),
                              ),
                            ),
                            Text(
                              'Skill total',
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: Colors.white70,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Current session  ${formatActiveDuration(sessionActive)}',
                              style: durationMonoStyle(
                                context,
                                base: theme.textTheme.titleMedium,
                              ).copyWith(color: Colors.white60),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              paused ? 'Paused' : 'Running',
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: accent,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                        );
                      },
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TimerIconControl(
                        tooltip: paused ? 'Resume' : 'Pause',
                        semanticLabel: paused
                            ? 'Resume stopwatch'
                            : 'Pause stopwatch',
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
                      TimerIconControl(
                        tooltip: 'Stop',
                        semanticLabel: 'Stop stopwatch',
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
