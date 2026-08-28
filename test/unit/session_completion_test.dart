import 'package:ayutam/features/backup/domain/backup_models.dart';
import 'package:ayutam/features/backup/domain/session_completion.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const sessionId = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';
  const skillId = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';

  BackupSessionRecord liveSession({required int start}) {
    return BackupSessionRecord(
      id: sessionId,
      skillId: skillId,
      mode: 'stopwatch',
      status: 'active',
      source: 'timer',
      startAtUtc: start,
      activeSeconds: 0,
      pausedSeconds: 0,
      timezoneIdAtCreation: 'UTC',
      offsetMinutesAtStart: 0,
      createdAtUtc: start,
      updatedAtUtc: start,
      sourceDeviceId: 'd',
    );
  }

  BackupSegmentRecord seg({
    required String id,
    required String type,
    required int start,
    int? end,
    int duration = 0,
    String? pomodoroPhase,
  }) {
    return BackupSegmentRecord(
      id: id,
      sessionId: sessionId,
      segmentType: type,
      pomodoroPhase: pomodoroPhase,
      startAtUtc: start,
      endAtUtc: end,
      durationSeconds: duration,
      createdAtUtc: start,
      updatedAtUtc: start,
    );
  }

  group('completeSessionAt segment clipping', () {
    test('drops open segment starting after reviewed end', () {
      const workId = '11111111-1111-4111-8111-111111111111';
      const pauseId = '22222222-2222-4222-8222-222222222222';
      const openId = '33333333-3333-4333-8333-333333333333';

      final result = BackupSessionCompletion.completeSessionAt(
        session: liveSession(start: 0),
        sessionSegments: [
          seg(
            id: workId,
            type: 'work',
            start: 0,
            end: 30 * 60 * 1000,
            duration: 30 * 60,
          ),
          seg(
            id: pauseId,
            type: 'pause',
            start: 30 * 60 * 1000,
            end: 40 * 60 * 1000,
            duration: 10 * 60,
          ),
          seg(id: openId, type: 'work', start: 40 * 60 * 1000),
        ],
        endAtUtc: 20 * 60 * 1000,
        nowUtcMs: 60 * 60 * 1000,
      );

      expect(result.session.endAtUtc, 20 * 60 * 1000);
      expect(result.segments, hasLength(1));
      expect(result.segments.single.id, workId);
      expect(result.segments.single.endAtUtc, 20 * 60 * 1000);
      expect(result.segments.single.durationSeconds, 20 * 60);
      expect(result.session.activeSeconds, 20 * 60);
      expect(result.session.pausedSeconds, 0);
    });

    test('truncates closed segment when reviewed end is inside it', () {
      const workId = '11111111-1111-4111-8111-111111111111';

      final result = BackupSessionCompletion.completeSessionAt(
        session: liveSession(start: 0),
        sessionSegments: [
          seg(
            id: workId,
            type: 'work',
            start: 0,
            end: 30 * 60 * 1000,
            duration: 30 * 60,
          ),
        ],
        endAtUtc: 20 * 60 * 1000,
        nowUtcMs: 60 * 60 * 1000,
      );

      expect(result.segments.single.endAtUtc, 20 * 60 * 1000);
      expect(result.segments.single.durationSeconds, 20 * 60);
      expect(result.session.activeSeconds, 20 * 60);
    });

    test('drops segments after reviewed end before last closed segment', () {
      const firstWorkId = '11111111-1111-4111-8111-111111111111';
      const pauseId = '22222222-2222-4222-8222-222222222222';
      const secondWorkId = '33333333-3333-4333-8333-333333333333';

      final result = BackupSessionCompletion.completeSessionAt(
        session: liveSession(start: 0),
        sessionSegments: [
          seg(
            id: firstWorkId,
            type: 'work',
            start: 0,
            end: 15 * 60 * 1000,
            duration: 15 * 60,
          ),
          seg(
            id: pauseId,
            type: 'pause',
            start: 15 * 60 * 1000,
            end: 20 * 60 * 1000,
            duration: 5 * 60,
          ),
          seg(
            id: secondWorkId,
            type: 'work',
            start: 20 * 60 * 1000,
            end: 35 * 60 * 1000,
            duration: 15 * 60,
          ),
        ],
        endAtUtc: 18 * 60 * 1000,
        nowUtcMs: 60 * 60 * 1000,
      );

      expect(result.segments.map((s) => s.id), [firstWorkId, pauseId]);
      expect(result.segments.last.endAtUtc, 18 * 60 * 1000);
      expect(result.session.activeSeconds, 15 * 60);
      expect(result.session.pausedSeconds, 3 * 60);
    });

    test('clips pomodoro break segments like pause segments', () {
      const workId = '11111111-1111-4111-8111-111111111111';
      const breakId = '22222222-2222-4222-8222-222222222222';

      final result = BackupSessionCompletion.completeSessionAt(
        session: liveSession(start: 0),
        sessionSegments: [
          seg(
            id: workId,
            type: 'work',
            start: 0,
            end: 25 * 60 * 1000,
            duration: 25 * 60,
          ),
          seg(
            id: breakId,
            type: 'pomodoro_break',
            start: 25 * 60 * 1000,
            end: 30 * 60 * 1000,
            duration: 5 * 60,
            pomodoroPhase: 'short_break',
          ),
        ],
        endAtUtc: 27 * 60 * 1000,
        nowUtcMs: 60 * 60 * 1000,
      );

      expect(result.segments, hasLength(2));
      expect(result.segments.last.id, breakId);
      expect(result.segments.last.endAtUtc, 27 * 60 * 1000);
      expect(result.session.activeSeconds, 25 * 60);
      expect(result.session.pausedSeconds, 2 * 60);
    });
  });
}
