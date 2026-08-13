/// Pure domain models for Statistics ([product-spec] §2.6, §4).
library;

/// A closed `work` segment of a completed session (allocation input).
final class WorkSlice {
  const WorkSlice({
    required this.skillId,
    required this.startAtUtc,
    required this.endAtUtc,
  });

  final String skillId;
  final DateTime startAtUtc;
  final DateTime endAtUtc;
}

/// Lightweight completed-session row for counts and averages.
final class CompletedSessionStat {
  const CompletedSessionStat({
    required this.skillId,
    required this.startAtUtc,
    required this.activeSeconds,
    this.endAtUtc,
  });

  final String skillId;
  final DateTime startAtUtc;

  /// Needed so cross-midnight sessions count on every local day they touch.
  final DateTime? endAtUtc;
  final int activeSeconds;
}

enum StatsScopeKind { all, single, compare }

/// Which skills the Statistics screen aggregates over.
final class StatsScope {
  const StatsScope.all()
    : kind = StatsScopeKind.all,
      skillIds = const {},
      _singleId = null;

  const StatsScope.single(String skillId)
    : kind = StatsScopeKind.single,
      skillIds = const {},
      _singleId = skillId;

  StatsScope.compare(Set<String> ids)
    : kind = StatsScopeKind.compare,
      skillIds = Set.unmodifiable(ids),
      _singleId = null;

  final StatsScopeKind kind;
  final Set<String> skillIds;
  final String? _singleId;

  static const int maxCompare = 5;

  String? get singleSkillId => _singleId;

  /// Skill ids to filter queries by; null means every skill.
  Set<String>? get filterIds => switch (kind) {
    StatsScopeKind.all => null,
    StatsScopeKind.single => {_singleId!},
    StatsScopeKind.compare => skillIds,
  };

  @override
  bool operator ==(Object other) =>
      other is StatsScope &&
      other.kind == kind &&
      other._singleId == _singleId &&
      other.skillIds.length == skillIds.length &&
      other.skillIds.containsAll(skillIds);

  @override
  int get hashCode => Object.hash(kind, _singleId, skillIds.length);
}

/// Summary card metrics ([product-spec] §2.6 “Summary metrics”).
final class StatsSummary {
  const StatsSummary({
    required this.totalActiveSeconds,
    required this.sessionCount,
    required this.streakDays,
    required this.fourWeekAverageWeeklySeconds,
    this.progressFraction,
    this.remainingSeconds,
    this.targetSeconds,
    this.projectedCompletionDay,
  });

  final int totalActiveSeconds;
  final int sessionCount;

  /// Global streak — always across all skills regardless of scope.
  final int streakDays;

  /// Active seconds per week over the previous 28 complete local days ÷ 4.
  final int fourWeekAverageWeeklySeconds;

  /// Single-skill scope only.
  final double? progressFraction;
  final int? remainingSeconds;
  final int? targetSeconds;

  /// Local calendar day; null when not calculable ([product-spec] §4).
  final DateTime? projectedCompletionDay;
}

/// One line on the cumulative chart.
final class CumulativeLine {
  const CumulativeLine({
    required this.skillId,
    required this.label,
    required this.points,
    this.accentArgb,
  });

  /// Null for the combined all-skills line.
  final String? skillId;
  final String label;
  final int? accentArgb;

  /// Ascending by [CumulativePoint.day].
  final List<CumulativePoint> points;
}

final class CumulativePoint {
  const CumulativePoint({required this.day, required this.cumulativeSeconds});

  /// Local calendar day (date-only) the bucket ends on.
  final DateTime day;
  final int cumulativeSeconds;
}

enum ChartRange { week, month, threeMonths, sixMonths, year, all, custom }

/// Auto aggregation per [product-spec] §2.6: daily ≤ 31d, weekly to 6 months,
/// monthly beyond.
enum ChartAggregation { daily, weekly, monthly }

/// Heatmap intensity buckets ([product-spec] §2.6).
enum HeatmapBucket { none, upTo30m, upTo1h, upTo2h, upTo4h, over4h }

HeatmapBucket heatmapBucketFor(int seconds) {
  if (seconds <= 0) return HeatmapBucket.none;
  if (seconds <= 30 * 60) return HeatmapBucket.upTo30m;
  if (seconds <= 60 * 60) return HeatmapBucket.upTo1h;
  if (seconds <= 2 * 3600) return HeatmapBucket.upTo2h;
  if (seconds <= 4 * 3600) return HeatmapBucket.upTo4h;
  return HeatmapBucket.over4h;
}

enum SummaryGranularity { day, week, month, year }

/// One row of the summary table ([product-spec] §2.6 “Summary table”).
final class SummaryPeriodRow {
  const SummaryPeriodRow({
    required this.periodStart,
    required this.label,
    required this.totalSeconds,
    required this.sessionCount,
    required this.averageSessionSeconds,
    required this.activeDays,
    required this.changePercent,
    required this.isNew,
  });

  /// First local day of the period (date-only).
  final DateTime periodStart;
  final String label;
  final int totalSeconds;
  final int sessionCount;
  final int averageSessionSeconds;
  final int activeDays;

  /// Null → no comparable prior period (em dash unless [isNew]).
  final double? changePercent;

  /// Prior period zero and this one positive → “New”.
  final bool isNew;
}

/// Everything the Statistics screen needs for one scope.
final class StatsBundle {
  const StatsBundle({
    required this.summary,
    required this.dailyTotals,
    required this.dailyTotalsBySkill,
    required this.sessions,
    required this.firstActivityDay,
    required this.hasAnyCompletedSession,
    required this.generatedForDay,
  });

  final StatsSummary summary;

  /// Scope-filtered allocated seconds per local day (date-only keys).
  final Map<DateTime, int> dailyTotals;

  /// Per-skill allocation for comparison lines (scope-filtered).
  final Map<String, Map<DateTime, int>> dailyTotalsBySkill;

  /// Scope-filtered completed sessions (summary-table counts).
  final List<CompletedSessionStat> sessions;

  /// Earliest allocated local day in scope; null when no history.
  final DateTime? firstActivityDay;

  /// Whether any completed session exists at all (empty-state routing).
  final bool hasAnyCompletedSession;

  /// Configured local day the streak / 4-week average / projection were
  /// computed for. The screen reloads when the calendar day rolls past it.
  final DateTime generatedForDay;
}
