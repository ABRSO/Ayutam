import 'dart:math' as math;

import 'package:intl/intl.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/time/clock_service.dart';
import '../../../core/time/timezone_service.dart';
import '../../skills/domain/skill_repository.dart';
import '../domain/statistics_models.dart';
import '../domain/statistics_source.dart';
import 'daily_allocation.dart';

/// Aggregates completed practice into the Statistics metrics
/// ([product-spec] §2.6 and §4 calculation definitions).
final class StatisticsService {
  StatisticsService({
    required StatisticsSource source,
    required SkillRepository skills,
    required ClockService clock,
    required TimezoneService timezones,
    this.streakMinimumSeconds = AppConstants.streakMinimumSecondsDefault,
  }) : _source = source,
       _skills = skills,
       _clock = clock,
       _timezones = timezones;

  final StatisticsSource _source;
  final SkillRepository _skills;
  final ClockService _clock;
  final TimezoneService _timezones;
  final int streakMinimumSeconds;

  Future<StatsBundle> load(StatsScope scope) async {
    // The global streak always spans every skill, so fetch all slices once
    // and filter in memory for the scoped metrics.
    final allSlices = await _source.completedWorkSlices();
    final scopedIds = scope.filterIds;
    final scopedSlices = scopedIds == null
        ? allSlices
        : allSlices.where((s) => scopedIds.contains(s.skillId)).toList();
    final sessions = await _source.completedSessions(skillIds: scopedIds);
    // Every completed session (timer or manual) carries work segments, so the
    // unscoped slice list doubles as the "anything completed at all" check.
    final anyCompleted = allSlices.isNotEmpty || sessions.isNotEmpty;

    // Single pass: group slices per skill, then allocate each group once so
    // comparison lines and the combined series share the work.
    final slicesBySkill = <String, List<WorkSlice>>{};
    for (final slice in scopedSlices) {
      slicesBySkill.putIfAbsent(slice.skillId, () => []).add(slice);
    }
    final bySkill = <String, Map<DateTime, int>>{
      for (final entry in slicesBySkill.entries)
        entry.key: allocateDailySeconds(entry.value, _timezones),
    };
    final daily = mergeDailyTotals(bySkill.values);
    final allDaily = scopedIds == null
        ? daily
        : allocateDailySeconds(allSlices, _timezones);

    final today = configuredLocalDayAt(_clock.nowUtc(), _timezones);
    final totalActive = sessions.fold<int>(
      0,
      (sum, s) => sum + s.activeSeconds,
    );
    final weeklyAvg = _fourWeekAverageWeeklySeconds(daily, today);

    double? progress;
    int? remaining;
    int? target;
    DateTime? projected;
    if (scope.kind == StatsScopeKind.single) {
      final skill = await _skills.findById(scope.singleSkillId!);
      if (skill != null) {
        target = skill.targetSeconds;
        progress = target <= 0 ? null : totalActive / target;
        remaining = math.max(target - totalActive, 0);
        projected = _projectedCompletionDay(
          remainingSeconds: remaining,
          weeklyAverageSeconds: weeklyAvg,
          firstActivityDay: _earliestDay(daily),
          today: today,
        );
      }
    }

    return StatsBundle(
      summary: StatsSummary(
        totalActiveSeconds: totalActive,
        sessionCount: sessions.length,
        streakDays: _streakDays(allDaily, today),
        fourWeekAverageWeeklySeconds: weeklyAvg,
        progressFraction: progress,
        remainingSeconds: remaining,
        targetSeconds: target,
        projectedCompletionDay: projected,
      ),
      dailyTotals: daily,
      dailyTotalsBySkill: bySkill,
      sessions: sessions,
      firstActivityDay: _earliestDay(daily),
      hasAnyCompletedSession: anyCompleted,
      generatedForDay: today,
    );
  }

  Stream<void> watchChanges() => _source.watchChanges();

  /// Consecutive qualifying days ending today, or — “today grace”
  /// ([product-spec] §4) — ending yesterday while today is still below the
  /// threshold.
  int _streakDays(Map<DateTime, int> allSkillsDaily, DateTime today) {
    bool qualifies(DateTime day) =>
        (allSkillsDaily[day] ?? 0) >= streakMinimumSeconds;

    var anchor = today;
    if (!qualifies(anchor)) {
      anchor = today.subtract(const Duration(days: 1));
      if (!qualifies(anchor)) return 0;
    }
    var streak = 0;
    var day = anchor;
    while (qualifies(day)) {
      streak += 1;
      day = day.subtract(const Duration(days: 1));
    }
    return streak;
  }

  /// Active seconds allocated to the previous 28 complete local days ÷ 4
  /// (today is partial and excluded) — [product-spec] §4.
  int _fourWeekAverageWeeklySeconds(Map<DateTime, int> daily, DateTime today) {
    var total = 0;
    for (var i = 1; i <= 28; i++) {
      total += daily[today.subtract(Duration(days: i))] ?? 0;
    }
    return total ~/ 4;
  }

  /// Remaining ÷ weekly average → local day; null when the target is reached,
  /// the average is zero, or history spans under ~7 days ([product-spec] §4).
  DateTime? _projectedCompletionDay({
    required int remainingSeconds,
    required int weeklyAverageSeconds,
    required DateTime? firstActivityDay,
    required DateTime today,
  }) {
    if (remainingSeconds <= 0 || weeklyAverageSeconds <= 0) return null;
    if (firstActivityDay == null) return null;
    if (today.difference(firstActivityDay).inDays < 7) return null;
    final days = remainingSeconds / (weeklyAverageSeconds / 7.0);
    return today.add(Duration(days: days.ceil()));
  }

  static DateTime? _earliestDay(Map<DateTime, int> daily) {
    DateTime? earliest;
    for (final day in daily.keys) {
      if (earliest == null || day.isBefore(earliest)) earliest = day;
    }
    return earliest;
  }

  /// Auto aggregation: daily ≤ 31 days, weekly to ~6 months, monthly beyond.
  static ChartAggregation aggregationForSpanDays(int days) {
    if (days <= 31) return ChartAggregation.daily;
    if (days <= 186) return ChartAggregation.weekly;
    return ChartAggregation.monthly;
  }

  /// Cumulative points over [windowStart]..[windowEnd] (date-only, both
  /// inclusive). Values include history before the window so the curve is a
  /// true running total.
  static List<CumulativePoint> cumulativeSeries({
    required Map<DateTime, int> daily,
    required DateTime windowStart,
    required DateTime windowEnd,
    required ChartAggregation aggregation,
  }) {
    if (windowEnd.isBefore(windowStart)) return const [];
    var carried = 0;
    for (final entry in daily.entries) {
      if (entry.key.isBefore(windowStart)) carried += entry.value;
    }

    final points = <CumulativePoint>[];
    var running = carried;
    var bucketEnd = _bucketEnd(windowStart, aggregation, windowEnd);
    var day = windowStart;
    var bucketHasDays = false;
    while (!day.isAfter(windowEnd)) {
      running += daily[day] ?? 0;
      bucketHasDays = true;
      if (day == bucketEnd || day == windowEnd) {
        points.add(CumulativePoint(day: day, cumulativeSeconds: running));
        final next = day.add(const Duration(days: 1));
        bucketEnd = _bucketEnd(next, aggregation, windowEnd);
        bucketHasDays = false;
      }
      day = day.add(const Duration(days: 1));
    }
    if (bucketHasDays && points.isNotEmpty) {
      points.add(CumulativePoint(day: windowEnd, cumulativeSeconds: running));
    }
    return points;
  }

  static DateTime _bucketEnd(
    DateTime from,
    ChartAggregation aggregation,
    DateTime cap,
  ) {
    DateTime end;
    switch (aggregation) {
      case ChartAggregation.daily:
        end = from;
      case ChartAggregation.weekly:
        // ISO weeks: Monday start, so the bucket closes on Sunday.
        end = from.add(Duration(days: DateTime.daysPerWeek - from.weekday));
      case ChartAggregation.monthly:
        end = DateTime(from.year, from.month + 1, 0);
    }
    return end.isAfter(cap) ? cap : end;
  }

  /// Summary-table rows, newest period first ([product-spec] §2.6).
  ///
  /// A session counts in every period its local-day span touches (so a
  /// cross-midnight session matches the allocated totals on both days), but
  /// only once per period.
  List<SummaryPeriodRow> summaryRows({
    required StatsBundle bundle,
    required SummaryGranularity granularity,
  }) {
    final today = configuredLocalDayAt(_clock.nowUtc(), _timezones);
    final first = _firstDataDay(bundle, today);
    if (first == null) return const [];

    // Session index per covered local day; sessions rarely span > 2 days.
    // The end instant is exclusive (like the allocator's half-open
    // segments): a session ending exactly at local midnight belongs to the
    // day before, which received all of its seconds.
    final sessionsByDay = <DateTime, List<int>>{};
    for (var i = 0; i < bundle.sessions.length; i++) {
      final session = bundle.sessions[i];
      final startDay = configuredLocalDayAt(session.startAtUtc, _timezones);
      final endInstant = session.endAtUtc ?? session.startAtUtc;
      var endDay = configuredLocalDayAt(
        endInstant.isAfter(session.startAtUtc)
            ? endInstant.subtract(const Duration(seconds: 1))
            : endInstant,
        _timezones,
      );
      if (endDay.isBefore(startDay)) endDay = startDay;
      for (
        var day = startDay;
        !day.isAfter(endDay);
        day = day.add(const Duration(days: 1))
      ) {
        sessionsByDay.putIfAbsent(day, () => []).add(i);
      }
    }

    final rows = <SummaryPeriodRow>[];
    int? previousTotal;
    var start = _periodStart(first, granularity);
    while (!start.isAfter(today)) {
      final end = _periodEndInclusive(start, granularity);
      var total = 0;
      var activeDays = 0;
      final periodSessions = <int>{};
      for (
        var day = start;
        !day.isAfter(end) && !day.isAfter(today);
        day = day.add(const Duration(days: 1))
      ) {
        final seconds = bundle.dailyTotals[day] ?? 0;
        total += seconds;
        if (seconds > 0) activeDays += 1;
        periodSessions.addAll(sessionsByDay[day] ?? const []);
      }
      final sessionCount = periodSessions.length;
      final prior = previousTotal;
      rows.add(
        SummaryPeriodRow(
          periodStart: start,
          label: _periodLabel(start, end, granularity),
          totalSeconds: total,
          sessionCount: sessionCount,
          averageSessionSeconds: sessionCount == 0 ? 0 : total ~/ sessionCount,
          activeDays: activeDays,
          changePercent: (prior == null || prior == 0)
              ? null
              : (total - prior) / prior * 100,
          isNew: prior != null && prior == 0 && total > 0,
        ),
      );
      previousTotal = total;
      start = end.add(const Duration(days: 1));
    }
    return rows.reversed.toList();
  }

  DateTime? _firstDataDay(StatsBundle bundle, DateTime today) {
    var first = bundle.firstActivityDay;
    for (final session in bundle.sessions) {
      final day = configuredLocalDayAt(session.startAtUtc, _timezones);
      if (first == null || day.isBefore(first)) first = day;
    }
    if (first != null && first.isAfter(today)) return today;
    return first;
  }

  static DateTime _periodStart(DateTime day, SummaryGranularity granularity) {
    return switch (granularity) {
      SummaryGranularity.day => day,
      // Product spec defaults the week start to Monday until Settings ships.
      SummaryGranularity.week => day.subtract(
        Duration(days: day.weekday - DateTime.monday),
      ),
      SummaryGranularity.month => DateTime(day.year, day.month, 1),
      SummaryGranularity.year => DateTime(day.year, 1, 1),
    };
  }

  static DateTime _periodEndInclusive(
    DateTime start,
    SummaryGranularity granularity,
  ) {
    return switch (granularity) {
      SummaryGranularity.day => start,
      SummaryGranularity.week => start.add(const Duration(days: 6)),
      SummaryGranularity.month => DateTime(start.year, start.month + 1, 0),
      SummaryGranularity.year => DateTime(start.year, 12, 31),
    };
  }

  static String _periodLabel(
    DateTime start,
    DateTime end,
    SummaryGranularity granularity,
  ) {
    return switch (granularity) {
      SummaryGranularity.day => DateFormat('d MMM y').format(start),
      SummaryGranularity.week =>
        '${DateFormat('d MMM').format(start)} – '
            '${DateFormat('d MMM y').format(end)}',
      SummaryGranularity.month => DateFormat('MMMM y').format(start),
      SummaryGranularity.year => DateFormat('y').format(start),
    };
  }
}
