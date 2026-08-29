import 'backup_models.dart';

/// Portable session completion semantics for backup merge/import.
///
/// Closes or truncates segments to fit within the reviewed end, then
/// recomputes parent active/paused totals from the resulting closed segments.
abstract final class BackupSessionCompletion {
  static const _pauseTypes = {'pause', 'pomodoro_break'};

  /// Rejects reviewed ends before session start or after [nowUtcMs].
  static void validateReviewedEnd({
    required int startAtUtc,
    required int endAtUtc,
    required int nowUtcMs,
  }) {
    if (endAtUtc < startAtUtc) {
      throw ArgumentError(
        'Reviewed end must be on or after the session start.',
      );
    }
    if (endAtUtc > nowUtcMs) {
      throw ArgumentError('Reviewed end cannot be in the future.');
    }
  }

  /// Closes/truncates segments for [session], marks it completed, and reconciles totals.
  static ({BackupSessionRecord session, List<BackupSegmentRecord> segments})
  completeSessionAt({
    required BackupSessionRecord session,
    required List<BackupSegmentRecord> sessionSegments,
    required int endAtUtc,
    required int nowUtcMs,
    int? updatedAtUtc,
  }) {
    validateReviewedEnd(
      startAtUtc: session.startAtUtc,
      endAtUtc: endAtUtc,
      nowUtcMs: nowUtcMs,
    );
    final updatedMs = updatedAtUtc ?? endAtUtc;
    final clipped = _clipSegmentsToEnd(
      segments: sessionSegments,
      endAtUtc: endAtUtc,
      updatedAtUtc: updatedMs,
    );

    final active = _sumWork(clipped);
    final paused = _sumPause(clipped);

    final completed = BackupSessionRecord(
      id: session.id,
      skillId: session.skillId,
      title: session.title,
      noteMarkdown: session.noteMarkdown,
      mode: session.mode,
      status: 'completed',
      source: session.source,
      startAtUtc: session.startAtUtc,
      endAtUtc: endAtUtc,
      activeSeconds: active,
      pausedSeconds: paused,
      timezoneIdAtCreation: session.timezoneIdAtCreation,
      offsetMinutesAtStart: session.offsetMinutesAtStart,
      createdAtUtc: session.createdAtUtc,
      updatedAtUtc: updatedMs,
      sourceDeviceId: session.sourceDeviceId,
      deletedAtUtc: session.deletedAtUtc,
    );

    return (session: completed, segments: clipped);
  }

  /// Keeps only segment time within `[sessionStart, endAtUtc]`, truncating or
  /// dropping segments that would extend past the reviewed end.
  static List<BackupSegmentRecord> _clipSegmentsToEnd({
    required List<BackupSegmentRecord> segments,
    required int endAtUtc,
    required int updatedAtUtc,
  }) {
    final sorted = [...segments]
      ..sort((a, b) => a.startAtUtc.compareTo(b.startAtUtc));
    final clipped = <BackupSegmentRecord>[];

    for (final segment in sorted) {
      if (segment.startAtUtc >= endAtUtc) continue;

      final clipEnd = segment.endAtUtc == null
          ? endAtUtc
          : (segment.endAtUtc! > endAtUtc ? endAtUtc : segment.endAtUtc!);
      if (clipEnd <= segment.startAtUtc) continue;

      clipped.add(
        BackupSegmentRecord(
          id: segment.id,
          sessionId: segment.sessionId,
          segmentType: segment.segmentType,
          pomodoroPhase: segment.pomodoroPhase,
          cycleNumber: segment.cycleNumber,
          startAtUtc: segment.startAtUtc,
          endAtUtc: clipEnd,
          durationSeconds: _closedDuration(segment.startAtUtc, clipEnd),
          createdAtUtc: segment.createdAtUtc,
          updatedAtUtc: updatedAtUtc,
        ),
      );
    }

    return clipped;
  }

  static int _closedDuration(int startAtUtc, int endAtUtc) {
    final seconds = ((endAtUtc - startAtUtc) / 1000).round();
    return seconds < 0 ? 0 : seconds;
  }

  static int _sumWork(List<BackupSegmentRecord> segments) {
    var total = 0;
    for (final segment in segments) {
      if (segment.segmentType != 'work') continue;
      if (segment.endAtUtc == null) continue;
      total += segment.durationSeconds;
    }
    return total;
  }

  static int _sumPause(List<BackupSegmentRecord> segments) {
    var total = 0;
    for (final segment in segments) {
      if (!_pauseTypes.contains(segment.segmentType)) continue;
      if (segment.endAtUtc == null) continue;
      total += segment.durationSeconds;
    }
    return total;
  }
}
