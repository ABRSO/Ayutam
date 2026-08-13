import 'package:ayutam/core/id/id_generator.dart';
import 'package:ayutam/core/time/clock_service.dart';
import 'package:ayutam/core/time/timezone_service.dart';
import 'package:ayutam/database/app_database.dart';
import 'package:ayutam/features/learning_log/application/indexed_session_deletion.dart';
import 'package:ayutam/features/learning_log/data/session_search_indexer.dart';
import 'package:ayutam/features/skills/application/skill_service.dart';
import 'package:ayutam/features/skills/data/drift_skill_repository.dart';
import 'package:ayutam/features/timer/application/stopwatch_timer_service.dart';
import 'package:ayutam/features/timer/data/drift_session_repository.dart';
import 'package:ayutam/features/timer/data/drift_timer_runtime_repository.dart';
import 'package:ayutam/features/timer/data/drift_unit_of_work.dart';
import 'package:ayutam/features/timer/domain/models.dart';
import 'package:flutter_test/flutter_test.dart';

class _SeqIds implements IdGenerator {
  int _n = 0;

  @override
  String v4() {
    _n += 1;
    return 'id-${_n.toString().padLeft(4, '0')}';
  }
}

void main() {
  late FakeClockService clock;
  late _SeqIds ids;
  late AppDatabase db;
  late SkillService skills;
  late StopwatchTimerService timer;

  setUp(() async {
    clock = FakeClockService(initialUtc: DateTime.utc(2026, 7, 22, 12));
    ids = _SeqIds();
    db = AppDatabase.memory(clock: clock, ids: ids);
    await db.ensureSeeded(clock: clock, ids: ids);
    final skillRepo = DriftSkillRepository(db);
    final sessionRepo = DriftSessionRepository(db);
    final runtimeRepo = DriftTimerRuntimeRepository(db);
    final uow = DriftUnitOfWork(db);
    final sessionDeletion = IndexedSessionDeletion(
      sessions: sessionRepo,
      indexer: SessionSearchIndexer(db),
    );
    skills = SkillService(
      skills: skillRepo,
      sessions: sessionRepo,
      clock: clock,
      ids: ids,
      deviceId: db.requireDeviceId,
    );
    timer = StopwatchTimerService(
      sessions: sessionRepo,
      runtime: runtimeRepo,
      skills: skillRepo,
      uow: uow,
      sessionDeletion: sessionDeletion,
      clock: clock,
      timezones: const FakeTimezoneService(),
      ids: ids,
      deviceId: db.requireDeviceId,
    );
  });

  tearDown(() async {
    await db.close();
  });

  Future<String> createSkill() async {
    final result = await skills.create(name: 'Piano');
    return result.valueOrNull!.id;
  }

  test('start pause resume stop save updates skill total', () async {
    final skillId = await createSkill();

    expect((await timer.startStopwatch(skillId)).isSuccess, isTrue);
    clock.advance(const Duration(minutes: 5));
    expect((await timer.pause()).isSuccess, isTrue);
    clock.advance(const Duration(minutes: 2));
    expect((await timer.resume()).isSuccess, isTrue);
    clock.advance(const Duration(minutes: 3));
    expect((await timer.stop()).isSuccess, isTrue);

    final pending = await timer.snapshot();
    expect(pending.runtime.machineState, TimerMachineState.completionPending);
    expect(pending.session!.activeSeconds, 8 * 60);

    expect((await timer.saveCompletion()).isSuccess, isTrue);
    final list = await skills.listActive();
    expect(list.single.completedActiveSeconds, 8 * 60);
  });

  test('double stop is idempotent', () async {
    final skillId = await createSkill();
    await timer.startStopwatch(skillId);
    clock.advance(const Duration(seconds: 30));
    final first = await timer.stop();
    final second = await timer.stop();
    expect(first.isSuccess, isTrue);
    expect(second.isSuccess, isTrue);

    final inProgress = await DriftSessionRepository(db).listInProgress();
    expect(inProgress, hasLength(1));
    expect(inProgress.single.status, SessionStatus.completionPending);
  });

  test('discard removes session and returns idle', () async {
    final skillId = await createSkill();
    await timer.startStopwatch(skillId);
    clock.advance(const Duration(seconds: 10));
    await timer.stop();
    expect((await timer.discardCompletion()).isSuccess, isTrue);
    final snap = await timer.snapshot();
    expect(snap.runtime.machineState, TimerMachineState.idle);
    expect(snap.session, isNull);
    expect(await skills.listActive(), hasLength(1));
    expect((await skills.listActive()).single.completedActiveSeconds, 0);
  });

  test('one-active invariant rejects second start', () async {
    final a = await createSkill();
    final b = (await skills.create(name: 'Guitar')).valueOrNull!.id;
    await timer.startStopwatch(a);
    final second = await timer.startStopwatch(b);
    expect(second.isFailure, isTrue);
    expect(
      second.when(success: (_) => '', failure: (f) => f.code),
      'TIMER-BUSY',
    );
  });

  test('segment sums match cached active_seconds after stop', () async {
    final skillId = await createSkill();
    await timer.startStopwatch(skillId);
    clock.advance(const Duration(seconds: 90));
    await timer.pause();
    clock.advance(const Duration(seconds: 30));
    await timer.resume();
    clock.advance(const Duration(seconds: 45));
    await timer.stop();

    final snap = await timer.snapshot();
    final fromSegments = TimerMath.activeSecondsFromSegments(
      segments: snap.segments,
      nowUtc: clock.nowUtc(),
    );
    expect(snap.session!.activeSeconds, fromSegments);
    expect(fromSegments, 135);
  });

  test('short gap recovers silently to timer', () async {
    final skillId = await createSkill();
    await timer.startStopwatch(skillId);
    clock.advance(const Duration(minutes: 10));
    await timer.heartbeat();
    clock.advance(const Duration(minutes: 5));

    final route = await timer.recoverOnStartup();
    expect(route.isSuccess, isTrue);
    expect(route.valueOrNull!.destination, StartupDestination.timer);
    expect(
      (await timer.snapshot()).runtime.machineState,
      TimerMachineState.running,
    );
  });

  test('long gap routes to recovery review', () async {
    final skillId = await createSkill();
    await timer.startStopwatch(skillId);
    await timer.heartbeat();
    clock.advance(const Duration(minutes: 45));

    final route = await timer.recoverOnStartup();
    expect(route.valueOrNull!.destination, StartupDestination.recoveryReview);
    expect(
      (await timer.snapshot()).runtime.machineState,
      TimerMachineState.recoveryReview,
    );
  });

  test('paused session ignores long gap', () async {
    final skillId = await createSkill();
    await timer.startStopwatch(skillId);
    clock.advance(const Duration(minutes: 1));
    await timer.pause();
    clock.advance(const Duration(hours: 3));

    final route = await timer.recoverOnStartup();
    expect(route.valueOrNull!.destination, StartupDestination.timer);
    expect(
      (await timer.snapshot()).runtime.machineState,
      TimerMachineState.paused,
    );
  });

  test('crash mid-run reconstructs within 10s via wall clock', () async {
    final skillId = await createSkill();
    await timer.startStopwatch(skillId);
    clock.advance(const Duration(seconds: 100));
    await timer.heartbeat();

    // Simulate process death: new service on same DB, advance 5s.
    clock.advance(const Duration(seconds: 5));
    final route = await timer.recoverOnStartup();
    expect(route.valueOrNull!.destination, StartupDestination.timer);
    final snap = await timer.snapshot();
    expect(snap.displayActiveSeconds, 105);
  });

  test('include full gap then stop yields continuous active time', () async {
    final skillId = await createSkill();
    await timer.startStopwatch(skillId);
    await timer.heartbeat();
    clock.advance(const Duration(minutes: 40));
    await timer.recoverOnStartup();
    await timer.applyRecoveryDecision(
      decision: RecoveryDecision.includeFullGap,
    );
    await timer.stop();
    final snap = await timer.snapshot();
    expect(snap.session!.activeSeconds, 40 * 60);
  });

  test('TimerMath ignores pauses for active seconds', () {
    final start = DateTime.utc(2026, 1, 1, 12);
    final segments = [
      SessionSegment(
        id: '1',
        sessionId: 's',
        segmentType: SegmentType.work,
        startAtUtc: start,
        endAtUtc: start.add(const Duration(seconds: 50)),
        durationSeconds: 50,
        createdAtUtc: start,
        updatedAtUtc: start,
      ),
      SessionSegment(
        id: '2',
        sessionId: 's',
        segmentType: SegmentType.pause,
        startAtUtc: start.add(const Duration(seconds: 50)),
        endAtUtc: start.add(const Duration(seconds: 80)),
        durationSeconds: 30,
        createdAtUtc: start,
        updatedAtUtc: start,
      ),
      SessionSegment(
        id: '3',
        sessionId: 's',
        segmentType: SegmentType.work,
        startAtUtc: start.add(const Duration(seconds: 80)),
        durationSeconds: 0,
        createdAtUtc: start,
        updatedAtUtc: start,
      ),
    ];
    final now = start.add(const Duration(seconds: 100));
    expect(
      TimerMath.activeSecondsFromSegments(segments: segments, nowUtc: now),
      70,
    );
  });

  test('idle runtime with stray session still rejects second start', () async {
    final a = await createSkill();
    final b = (await skills.create(name: 'Guitar')).valueOrNull!.id;
    await timer.startStopwatch(a);
    // Orphan the session by clearing runtime while leaving the row in-progress.
    await DriftTimerRuntimeRepository(
      db,
    ).clearToIdle(updatedAtUtc: clock.nowUtc());
    final second = await timer.startStopwatch(b);
    expect(second.isFailure, isTrue);
    expect(
      second.when(success: (_) => '', failure: (f) => f.code),
      'TIMER-BUSY',
    );
  });

  test(
    'startup reattaches idle runtime to stray in-progress session',
    () async {
      final skillId = await createSkill();
      await timer.startStopwatch(skillId);
      clock.advance(const Duration(minutes: 2));
      await DriftTimerRuntimeRepository(
        db,
      ).clearToIdle(updatedAtUtc: clock.nowUtc());

      final route = await timer.recoverOnStartup();
      expect(route.valueOrNull!.destination, StartupDestination.timer);
      expect(
        (await timer.snapshot()).runtime.machineState,
        TimerMachineState.running,
      );
      expect((await timer.snapshot()).session?.skillId, skillId);
    },
  );

  test('pause resume save discard are idempotent', () async {
    final skillId = await createSkill();
    await timer.startStopwatch(skillId);
    expect((await timer.pause()).isSuccess, isTrue);
    expect((await timer.pause()).isSuccess, isTrue);
    expect((await timer.resume()).isSuccess, isTrue);
    expect((await timer.resume()).isSuccess, isTrue);
    clock.advance(const Duration(seconds: 5));
    expect((await timer.stop()).isSuccess, isTrue);
    expect((await timer.stop()).isSuccess, isTrue);
    expect((await timer.saveCompletion()).isSuccess, isTrue);
    expect((await timer.saveCompletion()).isSuccess, isTrue);

    await timer.startStopwatch(skillId);
    clock.advance(const Duration(seconds: 3));
    await timer.stop();
    expect((await timer.discardCompletion()).isSuccess, isTrue);
    expect((await timer.discardCompletion()).isSuccess, isTrue);
  });

  test('resumeFromCompletion returns to running', () async {
    final skillId = await createSkill();
    await timer.startStopwatch(skillId);
    clock.advance(const Duration(seconds: 20));
    await timer.stop();
    expect((await timer.resumeFromCompletion()).isSuccess, isTrue);
    expect(
      (await timer.snapshot()).runtime.machineState,
      TimerMachineState.running,
    );
  });

  test('trimToHeartbeat closes work at last heartbeat', () async {
    final skillId = await createSkill();
    await timer.startStopwatch(skillId);
    clock.advance(const Duration(minutes: 5));
    await timer.heartbeat();
    final cut = clock.nowUtc();
    clock.advance(const Duration(minutes: 40));
    await timer.recoverOnStartup();
    expect(
      (await timer.applyRecoveryDecision(
        decision: RecoveryDecision.trimToHeartbeat,
      )).isSuccess,
      isTrue,
    );
    final snap = await timer.snapshot();
    expect(snap.runtime.machineState, TimerMachineState.paused);
    expect(snap.session!.activeSeconds, 5 * 60);
    expect(
      snap.segments
          .where((s) => s.segmentType == SegmentType.work && s.endAtUtc != null)
          .last
          .endAtUtc,
      cut,
    );
  });

  test('editEnd recovery completes session at edited time', () async {
    final skillId = await createSkill();
    await timer.startStopwatch(skillId);
    final start = clock.nowUtc();
    await timer.heartbeat();
    clock.advance(const Duration(minutes: 50));
    await timer.recoverOnStartup();
    final editedEnd = start.add(const Duration(minutes: 12));
    expect(
      (await timer.applyRecoveryDecision(
        decision: RecoveryDecision.editEnd,
        editedEndUtc: editedEnd,
      )).isSuccess,
      isTrue,
    );
    final snap = await timer.snapshot();
    expect(snap.runtime.machineState, TimerMachineState.completionPending);
    expect(snap.session!.activeSeconds, 12 * 60);
  });

  test('wall clock behind heartbeat routes to recovery review', () async {
    final skillId = await createSkill();
    await timer.startStopwatch(skillId);
    await timer.heartbeat();
    final heartbeat = clock.nowUtc();
    clock.setUtc(heartbeat.subtract(const Duration(minutes: 10)));
    final route = await timer.recoverOnStartup();
    expect(route.valueOrNull!.destination, StartupDestination.recoveryReview);
    expect(
      (await timer.snapshot()).runtime.recoveryReason,
      RecoveryReason.clockChange,
    );
  });

  test('archive blocked while skill has an active session', () async {
    final skillId = await createSkill();
    await timer.startStopwatch(skillId);
    final result = await skills.archive(skillId);
    expect(result.isFailure, isTrue);
    expect(
      result.when(success: (_) => '', failure: (f) => f.code),
      'SKILL-BUSY',
    );
  });

  test('create rejects non-positive target seconds', () async {
    final result = await skills.create(name: 'Bad', targetSeconds: 0);
    expect(result.isFailure, isTrue);
    expect(
      result.when(success: (_) => '', failure: (f) => f.code),
      'VAL-TARGET',
    );
  });

  test('start stores IANA timezone id not abbreviation', () async {
    final skillId = await createSkill();
    final ianaTimer = StopwatchTimerService(
      sessions: DriftSessionRepository(db),
      runtime: DriftTimerRuntimeRepository(db),
      skills: DriftSkillRepository(db),
      uow: DriftUnitOfWork(db),
      sessionDeletion: IndexedSessionDeletion(
        sessions: DriftSessionRepository(db),
        indexer: SessionSearchIndexer(db),
      ),
      clock: clock,
      timezones: const FakeTimezoneService(
        ianaId: 'Asia/Kolkata',
        offsetMinutes: 330,
      ),
      ids: ids,
      deviceId: db.requireDeviceId,
    );
    expect((await ianaTimer.startStopwatch(skillId)).isSuccess, isTrue);
    final session = (await ianaTimer.snapshot()).session!;
    expect(session.timezoneIdAtCreation, 'Asia/Kolkata');
    expect(session.offsetMinutesAtStart, 330);
  });
}
