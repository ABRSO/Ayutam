import 'dart:async';

import 'package:ayutam/core/id/id_generator.dart';
import 'package:ayutam/core/time/clock_service.dart';
import 'package:ayutam/core/time/timezone_service.dart';
import 'package:ayutam/database/app_database.dart';
import 'package:ayutam/features/learning_log/application/indexed_session_completion.dart';
import 'package:ayutam/features/learning_log/application/indexed_session_deletion.dart';
import 'package:ayutam/features/learning_log/application/indexed_skill_rename.dart';
import 'package:ayutam/features/learning_log/application/learning_log_service.dart';
import 'package:ayutam/features/learning_log/application/session_note_service.dart';
import 'package:ayutam/features/learning_log/application/tag_service.dart';
import 'package:ayutam/features/learning_log/data/drift_tag_repository.dart';
import 'package:ayutam/features/learning_log/data/session_search_indexer.dart';
import 'package:ayutam/features/learning_log/domain/learning_log_models.dart';
import 'package:ayutam/features/skills/application/skill_service.dart';
import 'package:ayutam/features/skills/data/drift_skill_repository.dart';
import 'package:ayutam/features/statistics/application/statistics_service.dart';
import 'package:ayutam/features/statistics/data/drift_statistics_source.dart';
import 'package:ayutam/features/statistics/domain/statistics_models.dart';
import 'package:ayutam/features/timer/application/stopwatch_timer_service.dart';
import 'package:ayutam/features/timer/data/drift_session_repository.dart';
import 'package:ayutam/features/timer/data/drift_timer_runtime_repository.dart';
import 'package:ayutam/features/timer/data/drift_unit_of_work.dart';
import 'package:flutter_test/flutter_test.dart';

/// Exit criterion: statistics totals match the Learning Log / skill totals
/// for the same fixture, including a cross-midnight session.
void main() {
  // Configured zone +05:30 (IST-style) so midnight splits are non-trivial.
  const tz = FakeTimezoneService(ianaId: 'Asia/Kolkata', offsetMinutes: 330);

  late FakeClockService clock;
  late AppDatabase db;
  late DriftSkillRepository skillRepo;
  late SkillService skills;
  late StopwatchTimerService timer;
  late SessionNoteService notes;
  late StatisticsService stats;

  setUp(() async {
    clock = FakeClockService(initialUtc: DateTime.utc(2026, 8, 1, 6));
    const ids = UuidIdGenerator();
    db = AppDatabase.memory(clock: clock, ids: ids);
    await db.ensureSeeded(clock: clock, ids: ids);
    skillRepo = DriftSkillRepository(db);
    final sessionRepo = DriftSessionRepository(db);
    final indexer = SessionSearchIndexer(db);
    final uow = DriftUnitOfWork(db);
    skills = SkillService(
      skills: skillRepo,
      sessions: sessionRepo,
      searchReindexing: IndexedSkillRename(indexer),
      clock: clock,
      timezones: tz,
      ids: ids,
      deviceId: db.requireDeviceId,
    );
    timer = StopwatchTimerService(
      sessions: sessionRepo,
      runtime: DriftTimerRuntimeRepository(db),
      skills: skillRepo,
      uow: uow,
      sessionDeletion: IndexedSessionDeletion(
        sessions: sessionRepo,
        indexer: indexer,
      ),
      sessionIndexing: IndexedSessionCompletion(
        sessions: sessionRepo,
        indexer: indexer,
      ),
      clock: clock,
      timezones: tz,
      ids: ids,
      deviceId: db.requireDeviceId,
    );
    notes = SessionNoteService(
      sessions: sessionRepo,
      skills: skillRepo,
      tags: TagService(
        tags: DriftTagRepository(db),
        clock: clock,
        ids: ids,
        deviceId: db.requireDeviceId,
      ),
      indexer: indexer,
      uow: uow,
      clock: clock,
      timezones: tz,
      ids: ids,
      deviceId: db.requireDeviceId,
    );
    stats = StatisticsService(
      source: DriftStatisticsSource(db),
      skills: skillRepo,
      clock: clock,
      timezones: tz,
    );
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> timedSession(String skillId, Duration length) async {
    expect((await timer.startStopwatch(skillId)).isSuccess, isTrue);
    clock.advance(length);
    expect((await timer.stop()).isSuccess, isTrue);
    expect((await timer.saveCompletion()).isSuccess, isTrue);
  }

  test('stats totals equal skill totals, split across local days', () async {
    final piano = (await skills.create(name: 'Piano')).valueOrNull!;
    final guitar = (await skills.create(name: 'Guitar')).valueOrNull!;

    // Plain daytime session: 40 minutes of Piano.
    await timedSession(piano.id, const Duration(minutes: 40));

    // Cross-midnight session: 23:00 IST → 01:00 IST (17:30–19:30 UTC).
    clock.advance(const Duration(hours: 8)); // 2026-08-01 ~15:xx UTC
    final beforeMidnight = DateTime.utc(2026, 8, 1, 17, 30);
    clock.advance(beforeMidnight.difference(clock.nowUtc()));
    await timedSession(piano.id, const Duration(hours: 2));

    // Guitar the next local day, 30 minutes.
    clock.advance(const Duration(hours: 5));
    await timedSession(guitar.id, const Duration(minutes: 30));

    // Manual Guitar entry: 1 hour earlier in the month.
    final manual = await notes.createManualSession(
      skillId: guitar.id,
      startAtUtc: DateTime.utc(2026, 7, 20, 9),
      endAtUtc: DateTime.utc(2026, 7, 20, 10),
    );
    expect(manual.isSuccess, isTrue);

    final bundle = await stats.load(const StatsScope.all());

    // Summary total matches the Home/Learning Log source of truth.
    final skillRows = await skillRepo.listActiveSkillsWithProgress();
    final skillTotal = skillRows.fold<int>(
      0,
      (sum, s) => sum + s.completedActiveSeconds,
    );
    expect(bundle.summary.totalActiveSeconds, skillTotal);
    expect(bundle.summary.totalActiveSeconds, (40 + 120 + 30 + 60) * 60);
    expect(bundle.summary.sessionCount, 4);

    // Allocation preserves every second (chart/heatmap consistency).
    final allocated = bundle.dailyTotals.values.fold<int>(0, (a, b) => a + b);
    expect(allocated, skillTotal);

    // The 23:00–01:00 IST session splits an hour onto each local day.
    expect(bundle.dailyTotals[DateTime(2026, 8, 1)], (40 + 60) * 60);
    expect(bundle.dailyTotals[DateTime(2026, 8, 2)], (60 + 30) * 60);

    // Single-skill scope matches that skill's own total.
    final pianoBundle = await stats.load(StatsScope.single(piano.id));
    final pianoRow = skillRows.singleWhere((s) => s.id == piano.id);
    expect(
      pianoBundle.summary.totalActiveSeconds,
      pianoRow.completedActiveSeconds,
    );
    expect(
      pianoBundle.dailyTotals.values.fold<int>(0, (a, b) => a + b),
      pianoRow.completedActiveSeconds,
    );

    // Heatmap deep link: the Aug 2 IST overlap window must include the
    // cross-midnight session that *started* on Aug 1 (start-based date
    // filters would miss it) plus the Guitar session that day.
    final log = LearningLogService(
      sessions: DriftSessionRepository(db),
      skills: skillRepo,
      tags: DriftTagRepository(db),
      indexer: SessionSearchIndexer(db),
    );
    final aug2Start = utcStartOfConfiguredDay(DateTime(2026, 8, 2), tz);
    final aug3Start = utcStartOfConfiguredDay(DateTime(2026, 8, 3), tz);
    final aug2Entries = await log.query(
      LearningLogFilters(overlapStartUtc: aug2Start, overlapEndUtc: aug3Start),
    );
    expect(aug2Entries, hasLength(2));
    expect(
      aug2Entries.map((e) => e.skillName).toSet(),
      unorderedEquals({'Piano', 'Guitar'}),
    );

    // Defense in depth: even if start-based bounds are also set (Jump /
    // filter sheet before clearOverlap), overlap wins so the cross-midnight
    // Piano session that started on Aug 1 remains visible on Aug 2.
    final anded = await log.query(
      LearningLogFilters(
        overlapStartUtc: aug2Start,
        overlapEndUtc: aug3Start,
        startAfterUtc: aug2Start,
        endBeforeUtc: aug3Start,
      ),
    );
    expect(anded, hasLength(2));
    expect(
      anded.map((e) => e.skillName).toSet(),
      unorderedEquals({'Piano', 'Guitar'}),
    );

    // After overlap is cleared, start-based From/To for Aug 2 hide the
    // session that started on Aug 1 (only Guitar remains).
    final startOnly = await log.query(
      LearningLogFilters(startAfterUtc: aug2Start, endBeforeUtc: aug3Start),
    );
    expect(startOnly, hasLength(1));
    expect(startOnly.single.skillName, 'Guitar');

    // The summary table counts the cross-midnight session on both days.
    final rows = stats.summaryRows(
      bundle: bundle,
      granularity: SummaryGranularity.day,
    );
    final aug1Row = rows.singleWhere(
      (r) => r.periodStart == DateTime(2026, 8, 1),
    );
    final aug2Row = rows.singleWhere(
      (r) => r.periodStart == DateTime(2026, 8, 2),
    );
    expect(aug1Row.sessionCount, 2); // 40m daytime + cross-midnight start
    expect(aug2Row.sessionCount, 2); // cross-midnight spill + Guitar
    expect(aug2Row.totalSeconds, (60 + 30) * 60);
  });

  test('overlap day link crosses month boundaries despite paging', () async {
    final piano = (await skills.create(name: 'Piano')).valueOrNull!;

    // 23:00 IST Jul 31 → 01:00 IST Aug 1 (17:30–19:30 UTC Jul 31).
    final crossMonth = await notes.createManualSession(
      skillId: piano.id,
      startAtUtc: DateTime.utc(2026, 7, 31, 17, 30),
      endAtUtc: DateTime.utc(2026, 7, 31, 19, 30),
    );
    expect(crossMonth.isSuccess, isTrue);
    // Plain Aug 1 daytime session.
    final daytime = await notes.createManualSession(
      skillId: piano.id,
      startAtUtc: DateTime.utc(2026, 8, 1, 5),
      endAtUtc: DateTime.utc(2026, 8, 1, 6),
    );
    expect(daytime.isSuccess, isTrue);

    final log = LearningLogService(
      sessions: DriftSessionRepository(db),
      skills: skillRepo,
      tags: DriftTagRepository(db),
      indexer: SessionSearchIndexer(db),
    );
    final filters = LearningLogFilters(
      overlapStartUtc: utcStartOfConfiguredDay(DateTime(2026, 8, 1), tz),
      overlapEndUtc: utcStartOfConfiguredDay(DateTime(2026, 8, 2), tz),
    );
    // Month-paged initial load must not hide the July-started session.
    final state = await log.loadInitial(filters);
    expect(state.entries, hasLength(2));
    expect(state.hasMoreOlder, isFalse);
    expect(state.hasMoreNewer, isFalse);
  });

  test('watchChanges fires when a skill row changes', () async {
    final source = DriftStatisticsSource(db);
    final skill = (await skills.create(name: 'Piano')).valueOrNull!;

    var events = 0;
    final second = Completer<void>();
    final sub = source.watchChanges().listen((_) {
      events += 1;
      if (events >= 2 && !second.isCompleted) second.complete();
    });
    // Let the initial emission land before mutating.
    await Future<void>.delayed(const Duration(milliseconds: 50));

    final updated = await skills.update(id: skill.id, targetSeconds: 42 * 3600);
    expect(updated.isSuccess, isTrue);

    await second.future.timeout(const Duration(seconds: 5));
    await sub.cancel();
  });
}
