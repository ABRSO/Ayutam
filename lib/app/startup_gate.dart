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
        StartupDestination.timer => TimerScreen(
          skillId: route.skillId,
          embeddedInShell: false,
        ),
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
