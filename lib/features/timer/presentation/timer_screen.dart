import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_theme.dart';
import '../../../app/ayutam_app.dart';
import '../../../app/providers.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/skill_accent_palette.dart';
import '../../../core/time/duration_format.dart';
import '../../skills/domain/skill.dart';
import '../application/long_session_warning.dart';
import '../domain/models.dart';
import '../domain/timer_platform_ports.dart';
import 'completion_screen.dart';
import 'open_in_progress_session.dart';
import 'widgets/flip_clock.dart';
import 'widgets/timer_icon_control.dart';

class TimerScreen extends ConsumerStatefulWidget {
  const TimerScreen({super.key, this.skillId});

  final String? skillId;

  @override
  ConsumerState<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends ConsumerState<TimerScreen> {
  Timer? _tick;
  var _redirected = false;
  var _longSessionWarned = false;
  TimerChromeService? _chrome;
  var _chromeEntered = false;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_enterChrome());
    });
  }

  Future<void> _enterChrome() async {
    if (_chromeEntered || !mounted) return;
    final chrome = ref.read(timerChromeServiceProvider);
    _chrome = chrome;
    _chromeEntered = true;
    final keepAwake = ref.read(keepScreenAwakeProvider).asData?.value ?? true;
    final landscape =
        ref.read(forceLandscapeAndroidProvider).asData?.value ?? true;
    await chrome.enterTimerVisible(
      keepScreenAwake: keepAwake,
      requestLandscape: landscape,
    );
  }

  @override
  void dispose() {
    _tick?.cancel();
    final chrome = _chrome;
    if (_chromeEntered && chrome != null) {
      unawaited(chrome.leaveTimerVisible());
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final snapAsync = ref.watch(timerSessionProvider);
    final theme = Theme.of(context);
    final skillId = widget.skillId;
    final skills =
        ref.watch(allSkillsProvider).asData?.value ??
        ref.watch(activeSkillsProvider).asData?.value;
    Skill? skill;
    if (skillId != null && skills != null) {
      for (final s in skills) {
        if (s.id == skillId) {
          skill = s;
          break;
        }
      }
    }

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          _remindSessionStillRunning();
        }
      },
      child: Scaffold(
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
            _redirectIfNotTimer(snap);
            final sessionActive = _liveActiveSeconds(snap);
            final completed = skill?.completedActiveSeconds ?? 0;
            final accumulated = completed + sessionActive;
            final paused =
                snap.runtime.machineState == TimerMachineState.paused;
            final longSession = exceedsLongSessionWarning(sessionActive);
            _maybeWarnLongSession(longSession);
            final accent = SkillAccentPalette.fromArgb(
              skill?.accentArgb,
              fallback: theme.colorScheme.primary,
            );

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Column(
                  children: [
                    if (longSession) ...[
                      const _LongSessionBanner(),
                      const SizedBox(height: 8),
                    ],
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
      ),
    );
  }

  void _redirectIfNotTimer(TimerSnapshot snap) {
    if (_redirected) {
      return;
    }
    final runtime = snap.runtime.machineState;
    final pending =
        runtime == TimerMachineState.completionPending ||
        snap.session?.status == SessionStatus.completionPending;
    final recovery = runtime == TimerMachineState.recoveryReview;
    if (!pending && !recovery) {
      return;
    }
    _redirected = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        return;
      }
      final page = screenForInProgressSnapshot(
        skillId: widget.skillId ?? snap.session?.skillId ?? '',
        snapshot: snap,
      );
      final route = MaterialPageRoute<void>(builder: (_) => page);
      if (Navigator.of(context).canPop()) {
        await Navigator.of(context).pushReplacement(route);
      } else {
        await ayutamNavigatorKey.currentState?.pushReplacement(route);
      }
    });
  }

  void _maybeWarnLongSession(bool longSession) {
    if (!longSession || _longSessionWarned) {
      return;
    }
    _longSessionWarned = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Long session'),
          content: const Text(
            'This session has more than ${AppConstants.longSessionWarningHours} '
            'hours of active time. Ayutam will not auto-stop.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    });
  }

  /// Shown after the route pops, so it must not use this screen's messenger.
  void _remindSessionStillRunning() {
    final state = ref
        .read(timerSessionProvider)
        .asData
        ?.value
        .runtime
        .machineState;
    final stillRunning =
        state == TimerMachineState.running || state == TimerMachineState.paused;
    if (!stillRunning) {
      return;
    }
    ayutamScaffoldMessengerKey.currentState
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text(
            'Session still running — reopen it from the skill\'s Play button.',
          ),
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

class _LongSessionBanner extends StatelessWidget {
  const _LongSessionBanner();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF5C4A16),
      borderRadius: BorderRadius.circular(8),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Text(
          'Over 8 hours of active time — the session will not auto-stop.',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
