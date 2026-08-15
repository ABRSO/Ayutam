import 'package:ayutam/core/id/id_generator.dart';
import 'package:ayutam/core/time/clock_service.dart';
import 'package:ayutam/core/time/timezone_service.dart';
import 'package:ayutam/database/app_database.dart';
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
import 'package:ayutam/features/timer/data/drift_session_repository.dart';
import 'package:ayutam/features/timer/data/drift_unit_of_work.dart';
import 'package:flutter_test/flutter_test.dart';

/// Synthetic multi-year fixture (≥10k sessions) for Learning Log latency baseline.
void main() {
  test(
    '10k session fixture list/search smoke + latency baseline',
    () async {
      final clock = FakeClockService(initialUtc: DateTime.utc(2020, 1, 1, 12));
      final ids = const UuidIdGenerator();
      final db = AppDatabase.memory(clock: clock, ids: ids);
      await db.ensureSeeded(clock: clock, ids: ids);

      final skillRepo = DriftSkillRepository(db);
      final sessionRepo = DriftSessionRepository(db);
      final tagRepo = DriftTagRepository(db);
      final uow = DriftUnitOfWork(db);
      final indexer = SessionSearchIndexer(db);
      final skills = SkillService(
        skills: skillRepo,
        sessions: sessionRepo,
        searchReindexing: IndexedSkillRename(indexer),
        clock: clock,
        timezones: const FakeTimezoneService(),
        ids: ids,
        deviceId: db.requireDeviceId,
      );
      final tags = TagService(
        tags: tagRepo,
        clock: clock,
        ids: ids,
        deviceId: db.requireDeviceId,
      );
      final notes = SessionNoteService(
        sessions: sessionRepo,
        skills: skillRepo,
        tags: tags,
        indexer: indexer,
        uow: uow,
        clock: clock,
        timezones: const FakeTimezoneService(),
        ids: ids,
        deviceId: db.requireDeviceId,
      );
      final log = LearningLogService(
        sessions: sessionRepo,
        skills: skillRepo,
        tags: tagRepo,
        indexer: indexer,
      );

      final skillA = (await skills.create(name: 'Piano')).valueOrNull!.id;
      final skillB = (await skills.create(name: 'Guitar')).valueOrNull!.id;
      const total = 10000;
      final needleId = await _seedSessions(
        notes: notes,
        clock: clock,
        skillA: skillA,
        skillB: skillB,
        total: total,
      );

      final month = CalendarMonth.fromLocal(
        DateTime.utc(2018, 1, 1, 12).toLocal(),
      );
      final listSw = Stopwatch()..start();
      final page = await log.queryMonth(const LearningLogFilters(), month);
      listSw.stop();
      expect(page.entries, isNotEmpty);
      expect(page.entries.length, lessThan(total));
      expect(page.hasMoreNewer, isTrue);

      final searchSw = Stopwatch()..start();
      final found = await log.query(
        const LearningLogFilters(query: 'NeedleTokenZzz'),
      );
      searchSw.stop();
      expect(found, hasLength(1));
      expect(found.single.session.id, needleId);

      // Soft target <300ms on mid hardware; always record for phase notes.
      // ignore: avoid_print
      print(
        'LEARNING_LOG_LATENCY month_list_ms=${listSw.elapsedMilliseconds} '
        'search_ms=${searchSw.elapsedMilliseconds} sessions=$total '
        'month_rows=${page.entries.length}',
      );

      // Statistics over the same fixture: full-history load stays fast enough
      // to run on the UI isolate ([database.md] §4 — cache/isolate offload
      // only after profiling says otherwise).
      final stats = StatisticsService(
        source: DriftStatisticsSource(db),
        skills: skillRepo,
        clock: clock,
        timezones: const FakeTimezoneService(),
      );
      final statsSw = Stopwatch()..start();
      final bundle = await stats.load(const StatsScope.all());
      statsSw.stop();
      expect(bundle.summary.sessionCount, total);
      final allocated = bundle.dailyTotals.values.fold<int>(0, (a, b) => a + b);
      expect(allocated, bundle.summary.totalActiveSeconds);
      // ignore: avoid_print
      print(
        'STATS_LATENCY load_ms=${statsSw.elapsedMilliseconds} '
        'sessions=$total days=${bundle.dailyTotals.length}',
      );
      expect(statsSw.elapsedMilliseconds, lessThan(2000));

      await db.close();
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );
}

Future<String> _seedSessions({
  required SessionNoteService notes,
  required FakeClockService clock,
  required String skillA,
  required String skillB,
  required int total,
}) async {
  late String needleId;
  final base = DateTime.utc(2018, 1, 1, 10);
  for (var i = 0; i < total; i++) {
    final skillId = i.isEven ? skillA : skillB;
    final start = base.add(Duration(hours: i * 3));
    final end = start.add(const Duration(minutes: 25));
    clock.setUtc(end);
    final isNeedle = i == total ~/ 2;
    final result = await notes.createManualSession(
      skillId: skillId,
      startAtUtc: start,
      endAtUtc: end,
      title: isNeedle ? 'Needle session' : 'Session $i',
      noteMarkdown: isNeedle
          ? 'NeedleTokenZzz deliberate practice'
          : 'Routine notes for session $i',
      tagNames: i % 7 == 0 ? ['bulk'] : const [],
      allowOverlap: true,
    );
    final session = result.valueOrNull!.session!;
    if (isNeedle) needleId = session.id;
  }
  return needleId;
}
