import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/timer/domain/models.dart';
import '../features/timer/presentation/completion_screen.dart';
import '../features/timer/presentation/recovery_review_screen.dart';
import '../features/timer/presentation/timer_screen.dart';
import 'app_shell.dart';
import 'providers.dart';

/// Routes to completion / timer / recovery / skills after DB recovery.
class StartupGate extends ConsumerWidget {
  const StartupGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routeAsync = ref.watch(startupGateProvider);

    return routeAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) =>
          Scaffold(body: Center(child: Text('Startup failed: $e'))),
      data: (route) => switch (route.destination) {
        StartupDestination.skillsHome => const AppShell(),
        // Push timer above AppShell so Back matches a normal Play→Start entry
        // (cold start used to mount TimerScreen as home with nothing to pop).
        StartupDestination.timer => _ActiveSessionEntry(skillId: route.skillId),
        StartupDestination.completion => CompletionScreen(
          skillId: route.skillId,
        ),
        StartupDestination.recoveryReview => RecoveryReviewScreen(
          skillId: route.skillId,
          proposedActiveSeconds: route.proposedActiveSeconds,
          lastHeartbeatUtc: route.lastHeartbeatUtc,
          reason: route.recoveryReason,
        ),
      },
    );
  }
}

/// Skills shell underneath + [TimerScreen] on the navigator stack.
///
/// Leaving the timer (system/AppBar back) returns to Home without stopping the
/// session, same as when the timer was opened from Play.
class _ActiveSessionEntry extends StatefulWidget {
  const _ActiveSessionEntry({this.skillId});

  final String? skillId;

  @override
  State<_ActiveSessionEntry> createState() => _ActiveSessionEntryState();
}

class _ActiveSessionEntryState extends State<_ActiveSessionEntry> {
  var _opened = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _openTimer());
  }

  Future<void> _openTimer() async {
    if (!mounted || _opened) {
      return;
    }
    final nav = Navigator.of(context);
    // Another route may already be on top (e.g. hot restart); don't stack.
    if (nav.canPop()) {
      _opened = true;
      return;
    }
    _opened = true;
    await nav.push(
      MaterialPageRoute<void>(
        builder: (_) => TimerScreen(skillId: widget.skillId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => const AppShell();
}
