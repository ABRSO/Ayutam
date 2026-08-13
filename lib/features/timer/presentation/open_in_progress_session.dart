import 'package:flutter/material.dart';

import '../domain/models.dart';
import 'completion_screen.dart';
import 'recovery_review_screen.dart';
import 'timer_screen.dart';

/// Opens the screen that matches persisted timer state (not always [TimerScreen]).
Future<void> openInProgressSession({
  required NavigatorState navigator,
  required String skillId,
  required TimerSnapshot snapshot,
}) async {
  final page = screenForInProgressSnapshot(
    skillId: skillId,
    snapshot: snapshot,
  );
  await navigator.push(MaterialPageRoute<void>(builder: (_) => page));
}

Widget screenForInProgressSnapshot({
  required String skillId,
  required TimerSnapshot snapshot,
}) {
  final runtime = snapshot.runtime;
  if (runtime.machineState == TimerMachineState.recoveryReview) {
    return RecoveryReviewScreen(
      skillId: skillId,
      proposedActiveSeconds: snapshot.displayActiveSeconds,
      lastHeartbeatUtc: runtime.lastHeartbeatUtc,
      reason: runtime.recoveryReason,
    );
  }
  if (runtime.machineState == TimerMachineState.completionPending ||
      snapshot.session?.status == SessionStatus.completionPending) {
    return CompletionScreen(skillId: skillId);
  }
  return TimerScreen(skillId: skillId);
}

String openInProgressLabel(TimerSnapshot snapshot) {
  final runtime = snapshot.runtime;
  if (runtime.machineState == TimerMachineState.recoveryReview) {
    return 'Open recovery review';
  }
  if (runtime.machineState == TimerMachineState.completionPending ||
      snapshot.session?.status == SessionStatus.completionPending) {
    return 'Open completion';
  }
  return 'Open active timer';
}
