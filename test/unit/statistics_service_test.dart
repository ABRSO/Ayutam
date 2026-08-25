import 'package:ayutam/core/time/clock_service.dart';
import 'package:ayutam/core/time/timezone_service.dart';
import 'package:ayutam/features/skills/domain/skill.dart';
import 'package:ayutam/features/skills/domain/skill_repository.dart';
import 'package:ayutam/features/statistics/application/statistics_service.dart';
import 'package:ayutam/features/statistics/domain/statistics_models.dart';
import 'package:ayutam/features/statistics/domain/statistics_source.dart';
import 'package:flutter_test/flutter_test.dart';

final class _FakeSource implements StatisticsSource {
  _FakeSource({this.slices = const [], this.sessions = const []});

  List<WorkSlice> slices;
  List<CompletedSessionStat> sessions;

  @override
  Future<List<WorkSlice>> completedWorkSlices({Set<String>? skillIds}) async {
    if (skillIds == null) return slices;
    return slices.where((s) => skillIds.contains(s.skillId)).toList();
  }

  @override
  Future<List<CompletedSessionStat>> completedSessions({
    Set<String>? skillIds,
  }) async {
    if (skillIds == null) return sessions;
    return sessions.where((s) => skillIds.contains(s.skillId)).toList();
  }

  @override
  Stream<void> watchChanges() => const Stream.empty();
}

final class _FakeSkills implements SkillRepository {
  _FakeSkills(this.byId);

  final Map<String, Skill> byId;

  @override
  Future<Skill?> findById(String id) async => byId[id];

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

Skill _skill(String id, {int targetSeconds = 36000000}) => Skill(
  id: id,
  name: id,
  targetSeconds: targetSeconds,
  createdLocalDate: '2026-01-01',
  status: SkillStatus.active,
  sortOrder: 0,
  createdAtUtc: DateTime.utc(2026, 1, 1),
  updatedAtUtc: DateTime.utc(2026, 1, 1),
  sourceDeviceId: 'device',
);

void main() {
  // Fixed "now": 2026-08-13 12:00 UTC; configured zone UTC so local day ==
  // UTC day and fixtures stay easy to read.
  final now = DateTime.utc(2026, 8, 13, 12);
  final today = DateTime(2026, 8, 13);
  const tz = FakeTimezoneService();

  WorkSlice sliceOn(
    DateTime day,
    int seconds, {
    String skill = 'a',
    int hour = 9,
  }) => WorkSlice(
    skillId: skill,
    startAtUtc: DateTime.utc(day.year, day.month, day.day, hour),
    endAtUtc: DateTime.utc(
      day.year,
      day.month,
      day.day,
      hour,
    ).add(Duration(seconds: seconds)),
  );

  CompletedSessionStat sessionOn(
    DateTime day,
    int seconds, {
    String skill = 'a',
  }) => CompletedSessionStat(
    skillId: skill,
    startAtUtc: DateTime.utc(day.year, day.month, day.day, 9),
    activeSeconds: seconds,
  );

  StatisticsService service(
    _FakeSource source, {
    Map<String, Skill> skills = const {},
  }) {
    return StatisticsService(
      source: source,
      skills: _FakeSkills(skills),
      clock: FakeClockService(initialUtc: now),
      timezones: tz,
    );
  }

  group('streak', () {
    test('counts consecutive qualifying days including today', () async {
      final source = _FakeSource(
        slices: [
          sliceOn(today, 150),
          sliceOn(today.subtract(const Duration(days: 1)), 200),
          sliceOn(today.subtract(const Duration(days: 2)), 3600),
          // Gap on day -3 breaks the chain.
          sliceOn(today.subtract(const Duration(days: 4)), 3600),
        ],
      );
      final bundle = await service(source).load(const StatsScope.all());
      expect(bundle.summary.streakDays, 3);
    });

    test('today below threshold keeps yesterday-ending streak alive', () async {
      final source = _FakeSource(
        slices: [
          sliceOn(today, 60), // below 120s
          sliceOn(today.subtract(const Duration(days: 1)), 121),
          sliceOn(today.subtract(const Duration(days: 2)), 130),
        ],
      );
      final bundle = await service(source).load(const StatsScope.all());
      expect(bundle.summary.streakDays, 2);
    });

    test('a 119-second day does not qualify', () async {
      final source = _FakeSource(
        slices: [
          sliceOn(today, 3600),
          sliceOn(today.subtract(const Duration(days: 1)), 119),
          sliceOn(today.subtract(const Duration(days: 2)), 3600),
        ],
      );
      final bundle = await service(source).load(const StatsScope.all());
      expect(bundle.summary.streakDays, 1);
    });

    test('no qualifying today or yesterday means zero', () async {
      final source = _FakeSource(
        slices: [sliceOn(today.subtract(const Duration(days: 2)), 3600)],
      );
      final bundle = await service(source).load(const StatsScope.all());
      expect(bundle.summary.streakDays, 0);
    });

    test('streak spans all skills even in a single-skill scope', () async {
      final source = _FakeSource(
        slices: [
          sliceOn(today, 3600, skill: 'b'),
          sliceOn(today.subtract(const Duration(days: 1)), 3600, skill: 'a'),
        ],
        sessions: [sessionOn(today.subtract(const Duration(days: 1)), 3600)],
      );
      final bundle = await service(
        source,
        skills: {'a': _skill('a')},
      ).load(const StatsScope.single('a'));
      // Scoped totals exclude skill b, but the streak still counts both days.
      expect(bundle.summary.streakDays, 2);
      expect(bundle.dailyTotals.containsKey(today), isFalse);
    });

    test('a cross-midnight session can qualify both local days', () async {
      // 200 seconds spanning midnight: 100s before, 100s after — with a 120s
      // threshold neither day qualifies alone; with 60s both would.
      final source = _FakeSource(
        slices: [
          WorkSlice(
            skillId: 'a',
            startAtUtc: DateTime.utc(2026, 8, 12, 23, 59, 20),
            endAtUtc: DateTime.utc(2026, 8, 13, 0, 0, 40),
          ),
          sliceOn(today, 200),
        ],
      );
      final bundle = await service(source).load(const StatsScope.all());
      // Today has 200 + 40 = 240s (qualifies); yesterday only 40s (no).
      expect(bundle.summary.streakDays, 1);
    });
  });

  group('4-week average and projection', () {
    test('averages the previous 28 complete days, excluding today', () async {
      final source = _FakeSource(
        slices: [
          sliceOn(today, 10 * 3600), // excluded: today is partial
          sliceOn(today.subtract(const Duration(days: 1)), 4 * 3600),
          sliceOn(today.subtract(const Duration(days: 28)), 4 * 3600),
          sliceOn(today.subtract(const Duration(days: 29)), 9 * 3600), // out
        ],
      );
      final bundle = await service(source).load(const StatsScope.all());
      expect(bundle.summary.fourWeekAverageWeeklySeconds, 2 * 3600);
    });

    test('projection = remaining at the weekly rate, ceiling days', () async {
      // 7h/week rate → 1h/day. Target 100h, done 20h → 80h → 80 days.
      final slices = <WorkSlice>[
        for (var i = 1; i <= 28; i++)
          sliceOn(today.subtract(Duration(days: i)), 3600),
      ];
      final sessions = [
        sessionOn(today.subtract(const Duration(days: 1)), 20 * 3600),
      ];
      final source = _FakeSource(slices: slices, sessions: sessions);
      final bundle = await service(
        source,
        skills: {'a': _skill('a', targetSeconds: 100 * 3600)},
      ).load(const StatsScope.single('a'));

      expect(
        bundle.summary.projectedCompletionDay,
        today.add(const Duration(days: 80)),
      );
    });

    test('projection unavailable when the target is reached', () async {
      final source = _FakeSource(
        slices: [
          for (var i = 1; i <= 28; i++)
            sliceOn(today.subtract(Duration(days: i)), 3600),
        ],
        sessions: [
          sessionOn(today.subtract(const Duration(days: 1)), 200 * 3600),
        ],
      );
      final bundle = await service(
        source,
        skills: {'a': _skill('a', targetSeconds: 100 * 3600)},
      ).load(const StatsScope.single('a'));
      expect(bundle.summary.projectedCompletionDay, isNull);
      expect(bundle.summary.remainingSeconds, 0);
    });

    test('projection unavailable with under a week of history', () async {
      final source = _FakeSource(
        slices: [sliceOn(today.subtract(const Duration(days: 2)), 2 * 3600)],
        sessions: [
          sessionOn(today.subtract(const Duration(days: 2)), 2 * 3600),
        ],
      );
      final bundle = await service(
        source,
        skills: {'a': _skill('a', targetSeconds: 100 * 3600)},
      ).load(const StatsScope.single('a'));
      expect(bundle.summary.projectedCompletionDay, isNull);
    });

    test('projection unavailable when the 4-week average is zero', () async {
      final source = _FakeSource(
        slices: [sliceOn(today.subtract(const Duration(days: 40)), 2 * 3600)],
        sessions: [
          sessionOn(today.subtract(const Duration(days: 40)), 2 * 3600),
        ],
      );
      final bundle = await service(
        source,
        skills: {'a': _skill('a', targetSeconds: 100 * 3600)},
      ).load(const StatsScope.single('a'));
      expect(bundle.summary.fourWeekAverageWeeklySeconds, 0);
      expect(bundle.summary.projectedCompletionDay, isNull);
    });
  });

  group('cumulative series', () {
    test('daily series carries history from before the window', () {
      final daily = {
        DateTime(2026, 8, 1): 3600,
        DateTime(2026, 8, 10): 3600,
        DateTime(2026, 8, 12): 7200,
      };
      final points = StatisticsService.cumulativeSeries(
        daily: daily,
        windowStart: DateTime(2026, 8, 10),
        windowEnd: DateTime(2026, 8, 13),
        aggregation: ChartAggregation.daily,
      );
      expect(points.map((p) => p.cumulativeSeconds), [
        7200,
        7200,
        14400,
        14400,
      ]);
      expect(points.first.day, DateTime(2026, 8, 10));
      expect(points.last.day, DateTime(2026, 8, 13));
    });

    test('empty daily map still emits a zero series for the window', () {
      final points = StatisticsService.cumulativeSeries(
        daily: const {},
        windowStart: DateTime(2026, 8, 1),
        windowEnd: DateTime(2026, 8, 3),
        aggregation: ChartAggregation.daily,
      );
      expect(points.map((p) => p.cumulativeSeconds), [0, 0, 0]);
    });

    test('weekly buckets close on Sundays and at the window end', () {
      final daily = {
        DateTime(2026, 8, 3): 3600, // Monday
        DateTime(2026, 8, 9): 3600, // Sunday (same ISO week)
        DateTime(2026, 8, 10): 3600, // next Monday
      };
      final points = StatisticsService.cumulativeSeries(
        daily: daily,
        windowStart: DateTime(2026, 8, 3),
        windowEnd: DateTime(2026, 8, 12),
        aggregation: ChartAggregation.weekly,
      );
      expect(points, hasLength(2));
      expect(points[0].day, DateTime(2026, 8, 9));
      expect(points[0].cumulativeSeconds, 7200);
      expect(points[1].day, DateTime(2026, 8, 12));
      expect(points[1].cumulativeSeconds, 10800);
    });

    test('auto aggregation thresholds match the spec', () {
      expect(
        StatisticsService.aggregationForSpanDays(31),
        ChartAggregation.daily,
      );
      expect(
        StatisticsService.aggregationForSpanDays(32),
        ChartAggregation.weekly,
      );
      expect(
        StatisticsService.aggregationForSpanDays(186),
        ChartAggregation.weekly,
      );
      expect(
        StatisticsService.aggregationForSpanDays(187),
        ChartAggregation.monthly,
      );
    });
  });

  group('summary table', () {
    test('weekly rows compute totals, averages, change, and New', () async {
      final lastMonday = today.subtract(Duration(days: today.weekday - 1));
      final prevMonday = lastMonday.subtract(const Duration(days: 7));
      final source = _FakeSource(
        slices: [
          sliceOn(prevMonday, 2 * 3600),
          sliceOn(prevMonday.add(const Duration(days: 1)), 2 * 3600),
          sliceOn(lastMonday, 6 * 3600),
        ],
        sessions: [
          sessionOn(prevMonday, 2 * 3600),
          sessionOn(prevMonday.add(const Duration(days: 1)), 2 * 3600),
          sessionOn(lastMonday, 6 * 3600),
        ],
      );
      final statsService = service(source);
      final bundle = await statsService.load(const StatsScope.all());
      final rows = statsService.summaryRows(
        bundle: bundle,
        granularity: SummaryGranularity.week,
      );

      expect(rows, hasLength(2));
      // Newest first.
      expect(rows[0].periodStart, lastMonday);
      expect(rows[0].totalSeconds, 6 * 3600);
      expect(rows[0].sessionCount, 1);
      expect(rows[0].averageSessionSeconds, 6 * 3600);
      expect(rows[0].activeDays, 1);
      expect(rows[0].changePercent, closeTo(50, 0.001));
      expect(rows[1].periodStart, prevMonday);
      expect(rows[1].totalSeconds, 4 * 3600);
      expect(rows[1].activeDays, 2);
      // First period has no prior — em dash, not "New".
      expect(rows[1].changePercent, isNull);
      expect(rows[1].isNew, isFalse);
    });

    test('cross-midnight sessions count on both day rows', () async {
      // 23:00 Aug 12 → 01:00 Aug 13 (UTC zone): one session, one slice.
      final start = DateTime.utc(2026, 8, 12, 23);
      final end = DateTime.utc(2026, 8, 13, 1);
      final source = _FakeSource(
        slices: [WorkSlice(skillId: 'a', startAtUtc: start, endAtUtc: end)],
        sessions: [
          CompletedSessionStat(
            skillId: 'a',
            startAtUtc: start,
            endAtUtc: end,
            activeSeconds: 7200,
          ),
        ],
      );
      final statsService = service(source);
      final bundle = await statsService.load(const StatsScope.all());
      final rows = statsService.summaryRows(
        bundle: bundle,
        granularity: SummaryGranularity.day,
      );

      final aug12 = rows.singleWhere(
        (r) => r.periodStart == DateTime(2026, 8, 12),
      );
      final aug13 = rows.singleWhere(
        (r) => r.periodStart == DateTime(2026, 8, 13),
      );
      // One hour allocated to each day; the session counts once per day, so
      // neither row shows practice time with zero sessions.
      expect(aug12.totalSeconds, 3600);
      expect(aug12.sessionCount, 1);
      expect(aug12.averageSessionSeconds, 3600);
      expect(aug13.totalSeconds, 3600);
      expect(aug13.sessionCount, 1);
      // A week row counts the same session once, not twice.
      final weekRows = statsService.summaryRows(
        bundle: bundle,
        granularity: SummaryGranularity.week,
      );
      final week = weekRows.singleWhere(
        (r) => r.periodStart == DateTime(2026, 8, 10),
      );
      expect(week.sessionCount, 1);
      expect(week.totalSeconds, 7200);
    });

    test(
      'session ending exactly at midnight stays on the earlier day',
      () async {
        // 23:00 → 00:00 sharp: all seconds allocate to Aug 12, so Aug 13 must
        // not report a session with zero practice time.
        final start = DateTime.utc(2026, 8, 12, 23);
        final end = DateTime.utc(2026, 8, 13);
        final source = _FakeSource(
          slices: [WorkSlice(skillId: 'a', startAtUtc: start, endAtUtc: end)],
          sessions: [
            CompletedSessionStat(
              skillId: 'a',
              startAtUtc: start,
              endAtUtc: end,
              activeSeconds: 3600,
            ),
          ],
        );
        final statsService = service(source);
        final bundle = await statsService.load(const StatsScope.all());
        final rows = statsService.summaryRows(
          bundle: bundle,
          granularity: SummaryGranularity.day,
        );

        final aug12 = rows.singleWhere(
          (r) => r.periodStart == DateTime(2026, 8, 12),
        );
        expect(aug12.totalSeconds, 3600);
        expect(aug12.sessionCount, 1);
        // "Today" (Aug 13) exists as a row but received nothing.
        final aug13 = rows.singleWhere(
          (r) => r.periodStart == DateTime(2026, 8, 13),
        );
        expect(aug13.totalSeconds, 0);
        expect(aug13.sessionCount, 0);
      },
    );

    test('a period after a zero period is marked New', () async {
      final start = today.subtract(const Duration(days: 2));
      final source = _FakeSource(
        slices: [sliceOn(start, 3600), sliceOn(today, 3600)],
        sessions: [sessionOn(start, 3600), sessionOn(today, 3600)],
      );
      final statsService = service(source);
      final bundle = await statsService.load(const StatsScope.all());
      final rows = statsService.summaryRows(
        bundle: bundle,
        granularity: SummaryGranularity.day,
      );

      expect(rows, hasLength(3));
      expect(rows[0].periodStart, today);
      expect(rows[0].isNew, isTrue);
      expect(rows[0].changePercent, isNull);
      expect(rows[1].totalSeconds, 0);
      // Positive prior → a plain −100% drop; em dash is only for zero-vs-zero.
      expect(rows[1].changePercent, closeTo(-100, 0.001));
      expect(rows[1].isNew, isFalse);
    });
  });

  group('heatmap buckets', () {
    test('fixed bucket edges match the product spec', () {
      expect(heatmapBucketFor(0), HeatmapBucket.none);
      expect(heatmapBucketFor(1), HeatmapBucket.upTo30m);
      expect(heatmapBucketFor(1800), HeatmapBucket.upTo30m);
      expect(heatmapBucketFor(1801), HeatmapBucket.upTo1h);
      expect(heatmapBucketFor(3600), HeatmapBucket.upTo1h);
      expect(heatmapBucketFor(3601), HeatmapBucket.upTo2h);
      expect(heatmapBucketFor(7200), HeatmapBucket.upTo2h);
      expect(heatmapBucketFor(7201), HeatmapBucket.upTo4h);
      expect(heatmapBucketFor(14400), HeatmapBucket.upTo4h);
      expect(heatmapBucketFor(14401), HeatmapBucket.over4h);
    });
  });

  group('scope', () {
    test('compare scope keeps per-skill series separate', () async {
      final source = _FakeSource(
        slices: [
          sliceOn(today, 3600, skill: 'a'),
          sliceOn(today, 1800, skill: 'b'),
          sliceOn(today, 900, skill: 'c'),
        ],
        sessions: [
          sessionOn(today, 3600, skill: 'a'),
          sessionOn(today, 1800, skill: 'b'),
          sessionOn(today, 900, skill: 'c'),
        ],
      );
      final bundle = await service(source).load(StatsScope.compare({'a', 'b'}));

      expect(bundle.dailyTotalsBySkill.keys, unorderedEquals(['a', 'b']));
      expect(bundle.dailyTotals[today], 5400);
      expect(bundle.summary.totalActiveSeconds, 5400);
      expect(bundle.summary.sessionCount, 2);
    });
  });
}
