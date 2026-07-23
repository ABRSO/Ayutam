import 'timer_enums.dart';

export 'timer_enums.dart';

final class PracticeSession {
  const PracticeSession({
    required this.id,
    required this.skillId,
    required this.mode,
    required this.status,
    required this.source,
    required this.startAtUtc,
    required this.activeSeconds,
    required this.pausedSeconds,
    required this.timezoneIdAtCreation,
    required this.offsetMinutesAtStart,
    required this.createdAtUtc,
    required this.updatedAtUtc,
    required this.sourceDeviceId,
    this.title,
    this.noteMarkdown,
    this.endAtUtc,
    this.deletedAtUtc,
  });

  final String id;
  final String skillId;
  final String? title;
  final String? noteMarkdown;
  final SessionMode mode;
  final SessionStatus status;
  final String source;
  final DateTime startAtUtc;
  final DateTime? endAtUtc;
  final int activeSeconds;
  final int pausedSeconds;
  final String timezoneIdAtCreation;
  final int offsetMinutesAtStart;
  final DateTime createdAtUtc;
  final DateTime updatedAtUtc;
  final String sourceDeviceId;
  final DateTime? deletedAtUtc;

  PracticeSession copyWith({
    SessionStatus? status,
    DateTime? endAtUtc,
    int? activeSeconds,
    int? pausedSeconds,
    DateTime? updatedAtUtc,
    bool clearEndAtUtc = false,
  }) {
    return PracticeSession(
      id: id,
      skillId: skillId,
      title: title,
      noteMarkdown: noteMarkdown,
      mode: mode,
      status: status ?? this.status,
      source: source,
      startAtUtc: startAtUtc,
      endAtUtc: clearEndAtUtc ? null : (endAtUtc ?? this.endAtUtc),
      activeSeconds: activeSeconds ?? this.activeSeconds,
      pausedSeconds: pausedSeconds ?? this.pausedSeconds,
      timezoneIdAtCreation: timezoneIdAtCreation,
      offsetMinutesAtStart: offsetMinutesAtStart,
      createdAtUtc: createdAtUtc,
      updatedAtUtc: updatedAtUtc ?? this.updatedAtUtc,
      sourceDeviceId: sourceDeviceId,
      deletedAtUtc: deletedAtUtc,
    );
  }
}

final class SessionSegment {
  const SessionSegment({
    required this.id,
    required this.sessionId,
    required this.segmentType,
    required this.startAtUtc,
    required this.durationSeconds,
    required this.createdAtUtc,
    required this.updatedAtUtc,
    this.pomodoroPhase,
    this.cycleNumber,
    this.endAtUtc,
  });

  final String id;
  final String sessionId;
  final SegmentType segmentType;
  final String? pomodoroPhase;
  final int? cycleNumber;
  final DateTime startAtUtc;
  final DateTime? endAtUtc;
  final int durationSeconds;
  final DateTime createdAtUtc;
  final DateTime updatedAtUtc;

  bool get isOpen => endAtUtc == null;

  SessionSegment copyWith({
    DateTime? endAtUtc,
    int? durationSeconds,
    DateTime? updatedAtUtc,
  }) {
    return SessionSegment(
      id: id,
      sessionId: sessionId,
      segmentType: segmentType,
      pomodoroPhase: pomodoroPhase,
      cycleNumber: cycleNumber,
      startAtUtc: startAtUtc,
      endAtUtc: endAtUtc ?? this.endAtUtc,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      createdAtUtc: createdAtUtc,
      updatedAtUtc: updatedAtUtc ?? this.updatedAtUtc,
    );
  }
}

final class TimerRuntimeState {
  const TimerRuntimeState({
    required this.machineState,
    required this.currentCycle,
    required this.phaseAccumulatedSeconds,
    required this.updatedAtUtc,
    this.sessionId,
    this.currentSegmentId,
    this.phasePlannedSeconds,
    this.phaseStartedAtUtc,
    this.monotonicAnchorMicros,
    this.wallClockAnchorUtc,
    this.lastHeartbeatUtc,
    this.lastCheckpointAtUtc,
    this.recoveryReason,
  });

  final String? sessionId;
  final TimerMachineState machineState;
  final String? currentSegmentId;
  final int? phasePlannedSeconds;
  final DateTime? phaseStartedAtUtc;
  final int phaseAccumulatedSeconds;
  final int currentCycle;
  final int? monotonicAnchorMicros;
  final DateTime? wallClockAnchorUtc;
  final DateTime? lastHeartbeatUtc;
  final DateTime? lastCheckpointAtUtc;
  final RecoveryReason? recoveryReason;
  final DateTime updatedAtUtc;

  bool get isIdle => machineState == TimerMachineState.idle;

  TimerRuntimeState copyWith({
    String? sessionId,
    TimerMachineState? machineState,
    String? currentSegmentId,
    int? phasePlannedSeconds,
    DateTime? phaseStartedAtUtc,
    int? phaseAccumulatedSeconds,
    int? currentCycle,
    int? monotonicAnchorMicros,
    DateTime? wallClockAnchorUtc,
    DateTime? lastHeartbeatUtc,
    DateTime? lastCheckpointAtUtc,
    RecoveryReason? recoveryReason,
    DateTime? updatedAtUtc,
    bool clearSession = false,
    bool clearSegment = false,
    bool clearRecoveryReason = false,
    bool clearHeartbeat = false,
  }) {
    return TimerRuntimeState(
      sessionId: clearSession ? null : (sessionId ?? this.sessionId),
      machineState: machineState ?? this.machineState,
      currentSegmentId: clearSegment
          ? null
          : (currentSegmentId ?? this.currentSegmentId),
      phasePlannedSeconds: phasePlannedSeconds ?? this.phasePlannedSeconds,
      phaseStartedAtUtc: phaseStartedAtUtc ?? this.phaseStartedAtUtc,
      phaseAccumulatedSeconds:
          phaseAccumulatedSeconds ?? this.phaseAccumulatedSeconds,
      currentCycle: currentCycle ?? this.currentCycle,
      monotonicAnchorMicros:
          monotonicAnchorMicros ?? this.monotonicAnchorMicros,
      wallClockAnchorUtc: wallClockAnchorUtc ?? this.wallClockAnchorUtc,
      lastHeartbeatUtc: clearHeartbeat
          ? null
          : (lastHeartbeatUtc ?? this.lastHeartbeatUtc),
      lastCheckpointAtUtc: lastCheckpointAtUtc ?? this.lastCheckpointAtUtc,
      recoveryReason: clearRecoveryReason
          ? null
          : (recoveryReason ?? this.recoveryReason),
      updatedAtUtc: updatedAtUtc ?? this.updatedAtUtc,
    );
  }
}

/// Pure helpers for active/paused second math.
abstract final class TimerMath {
  static int activeSecondsFromSegments({
    required List<SessionSegment> segments,
    required DateTime nowUtc,
  }) {
    var total = 0;
    for (final segment in segments) {
      if (segment.segmentType != SegmentType.work) {
        continue;
      }
      if (segment.endAtUtc != null) {
        total += segment.durationSeconds;
      } else {
        final elapsed = nowUtc.difference(segment.startAtUtc).inSeconds;
        total += elapsed < 0 ? 0 : elapsed;
      }
    }
    return total;
  }

  static int pausedSecondsFromSegments({
    required List<SessionSegment> segments,
    required DateTime nowUtc,
  }) {
    var total = 0;
    for (final segment in segments) {
      if (segment.segmentType != SegmentType.pause &&
          segment.segmentType != SegmentType.pomodoroBreak) {
        continue;
      }
      if (segment.endAtUtc != null) {
        total += segment.durationSeconds;
      } else {
        final elapsed = nowUtc.difference(segment.startAtUtc).inSeconds;
        total += elapsed < 0 ? 0 : elapsed;
      }
    }
    return total;
  }

  static int closedDurationSeconds({
    required DateTime startAtUtc,
    required DateTime endAtUtc,
  }) {
    final seconds = endAtUtc.difference(startAtUtc).inSeconds;
    return seconds < 0 ? 0 : seconds;
  }
}

final class StartupRoute {
  const StartupRoute({
    required this.destination,
    this.sessionId,
    this.skillId,
    this.recoveryReason,
    this.proposedActiveSeconds,
    this.lastHeartbeatUtc,
  });

  final StartupDestination destination;
  final String? sessionId;
  final String? skillId;
  final RecoveryReason? recoveryReason;
  final int? proposedActiveSeconds;
  final DateTime? lastHeartbeatUtc;
}

final class TimerSnapshot {
  const TimerSnapshot({
    required this.runtime,
    this.session,
    this.segments = const [],
    this.displayActiveSeconds = 0,
  });

  final TimerRuntimeState runtime;
  final PracticeSession? session;
  final List<SessionSegment> segments;
  final int displayActiveSeconds;
}
