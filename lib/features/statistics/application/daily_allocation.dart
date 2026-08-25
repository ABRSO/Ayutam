import '../../../core/time/timezone_service.dart';
import '../domain/statistics_models.dart';

/// Splits closed work segments across configured-timezone midnights and sums
/// active seconds per local calendar day ([database.md] §4: never assign a
/// cross-midnight session to its start date only).
///
/// Keys are date-only `DateTime(y, m, d)` values matching
/// [configuredLocalDayAt]. DST-shifted midnights are handled with one offset
/// refinement; a progress guard keeps the loop finite on pathological rules.
Map<DateTime, int> allocateDailySeconds(
  Iterable<WorkSlice> slices,
  TimezoneService timezones,
) {
  final totals = <DateTime, int>{};
  for (final slice in slices) {
    var cursor = slice.startAtUtc.toUtc();
    final end = slice.endAtUtc.toUtc();
    while (cursor.isBefore(end)) {
      final day = configuredLocalDayAt(cursor, timezones);
      var boundary = _nextLocalMidnightUtc(cursor, timezones);
      if (!boundary.isAfter(cursor)) {
        // Defensive: malformed offsets must not hang allocation.
        boundary = cursor.add(const Duration(hours: 1));
      }
      final sliceEnd = boundary.isBefore(end) ? boundary : end;
      final seconds = sliceEnd.difference(cursor).inSeconds;
      if (seconds > 0) {
        totals.update(day, (v) => v + seconds, ifAbsent: () => seconds);
      }
      cursor = sliceEnd;
    }
  }
  return totals;
}

/// UTC instant of the next local midnight after [utc] in the configured zone.
DateTime _nextLocalMidnightUtc(DateTime utc, TimezoneService timezones) {
  final offset = timezones.offsetMinutesAt(utc);
  final local = utc.add(Duration(minutes: offset));
  final nextWallMidnight = DateTime.utc(
    local.year,
    local.month,
    local.day,
  ).add(const Duration(days: 1));
  var candidate = nextWallMidnight.subtract(Duration(minutes: offset));
  // A DST change between now and midnight moves the boundary; one refinement
  // with the offset at the candidate instant is enough for real rules.
  final refined = timezones.offsetMinutesAt(candidate);
  if (refined != offset) {
    candidate = nextWallMidnight.subtract(Duration(minutes: refined));
  }
  return candidate;
}

/// Merges per-day maps (e.g. per-skill allocations into a combined series).
Map<DateTime, int> mergeDailyTotals(Iterable<Map<DateTime, int>> maps) {
  final merged = <DateTime, int>{};
  for (final map in maps) {
    for (final entry in map.entries) {
      merged.update(
        entry.key,
        (v) => v + entry.value,
        ifAbsent: () => entry.value,
      );
    }
  }
  return merged;
}
