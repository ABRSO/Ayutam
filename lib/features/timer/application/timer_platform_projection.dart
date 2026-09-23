import '../domain/models.dart';
import '../domain/timer_platform_ports.dart';

/// Builds a [TimerPlatformProjection] from a [TimerSnapshot] + skill name.
TimerPlatformProjection? projectionFromSnapshot({
  required TimerSnapshot snapshot,
  required String skillName,
  required DateTime nowUtc,
}) {
  final state = snapshot.runtime.machineState;
  if (state != TimerMachineState.running && state != TimerMachineState.paused) {
    return null;
  }
  final session = snapshot.session;
  if (session == null) return null;

  DateTime? openWorkStart;
  var closedActive = 0;
  for (final segment in snapshot.segments) {
    if (segment.segmentType != SegmentType.work) continue;
    if (segment.endAtUtc != null) {
      closedActive += segment.durationSeconds;
    } else {
      openWorkStart = segment.startAtUtc;
    }
  }

  if (state == TimerMachineState.paused) {
    // All work is closed while paused; prefer snapshot display total.
    closedActive = snapshot.displayActiveSeconds;
    openWorkStart = null;
  } else if (openWorkStart == null) {
    // Running but no open segment in snapshot — fall back to display total.
    closedActive = snapshot.displayActiveSeconds;
  }

  return TimerPlatformProjection(
    skillId: session.skillId,
    skillName: skillName,
    machineState: state,
    closedActiveSeconds: closedActive,
    openWorkStartUtc: openWorkStart,
    sessionId: session.id,
  );
}
