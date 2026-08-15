import 'package:ayutam/core/time/timezone_service.dart';
import 'package:ayutam/features/statistics/application/daily_allocation.dart';
import 'package:ayutam/features/statistics/domain/statistics_models.dart';
import 'package:flutter_test/flutter_test.dart';

/// Offset changes at a fixed UTC instant (DST-style transition for tests).
final class _SteppedTimezone implements TimezoneService {
  const _SteppedTimezone({
    required this.beforeOffset,
    required this.afterOffset,
    required this.switchAtUtc,
  });

  final int beforeOffset;
  final int afterOffset;
  final DateTime switchAtUtc;

  @override
  String get ianaId => 'Test/Stepped';

  @override
  int offsetMinutesAt(DateTime utc, {String? ianaId}) =>
      utc.isBefore(switchAtUtc) ? beforeOffset : afterOffset;
}

void main() {
  const kolkata = FakeTimezoneService(
    ianaId: 'Asia/Kolkata',
    offsetMinutes: 330,
  );
  const newYorkFixed = FakeTimezoneService(
    ianaId: 'America/New_York',
    offsetMinutes: -300,
  );

  WorkSlice slice(String skill, DateTime start, DateTime end) =>
      WorkSlice(skillId: skill, startAtUtc: start, endAtUtc: end);

  test('same-day slice lands on one configured-timezone day', () {
    // 10:00–11:30 IST on 2026-08-10 (04:30–06:00 UTC).
    final totals = allocateDailySeconds([
      slice(
        'a',
        DateTime.utc(2026, 8, 10, 4, 30),
        DateTime.utc(2026, 8, 10, 6),
      ),
    ], kolkata);

    expect(totals, {DateTime(2026, 8, 10): 5400});
  });

  test('cross-midnight slice splits across both local days', () {
    // 23:00 IST Aug 10 → 01:00 IST Aug 11 (17:30–19:30 UTC Aug 10).
    final totals = allocateDailySeconds([
      slice(
        'a',
        DateTime.utc(2026, 8, 10, 17, 30),
        DateTime.utc(2026, 8, 10, 19, 30),
      ),
    ], kolkata);

    expect(totals, {DateTime(2026, 8, 10): 3600, DateTime(2026, 8, 11): 3600});
  });

  test('negative offsets split on the local midnight, not UTC midnight', () {
    // 23:30 → 00:30 local at UTC-5 = 04:30–05:30 UTC the next day.
    final totals = allocateDailySeconds([
      slice(
        'a',
        DateTime.utc(2026, 8, 11, 4, 30),
        DateTime.utc(2026, 8, 11, 5, 30),
      ),
    ], newYorkFixed);

    expect(totals, {DateTime(2026, 8, 10): 1800, DateTime(2026, 8, 11): 1800});
  });

  test('a multi-day slice allocates every covered day', () {
    // 50 hours starting at local midnight Aug 10 (UTC 2026-08-09 18:30).
    final start = DateTime.utc(2026, 8, 9, 18, 30);
    final totals = allocateDailySeconds([
      slice('a', start, start.add(const Duration(hours: 50))),
    ], kolkata);

    expect(totals, {
      DateTime(2026, 8, 10): 86400,
      DateTime(2026, 8, 11): 86400,
      DateTime(2026, 8, 12): 7200,
    });
  });

  test('slice ending exactly at local midnight stays on the earlier day', () {
    // 23:00 → 24:00 IST Aug 10 (17:30–18:30 UTC).
    final totals = allocateDailySeconds([
      slice(
        'a',
        DateTime.utc(2026, 8, 10, 17, 30),
        DateTime.utc(2026, 8, 10, 18, 30),
      ),
    ], kolkata);

    expect(totals, {DateTime(2026, 8, 10): 3600});
  });

  test('zero-length slices contribute nothing', () {
    final at = DateTime.utc(2026, 8, 10, 12);
    expect(allocateDailySeconds([slice('a', at, at)], kolkata), isEmpty);
  });

  test('multiple slices accumulate per day across skills', () {
    final totals = allocateDailySeconds([
      slice('a', DateTime.utc(2026, 8, 10, 4), DateTime.utc(2026, 8, 10, 5)),
      slice(
        'b',
        DateTime.utc(2026, 8, 10, 6),
        DateTime.utc(2026, 8, 10, 6, 30),
      ),
    ], kolkata);

    expect(totals, {DateTime(2026, 8, 10): 5400});
  });

  test('offset change mid-slice still splits with one refinement', () {
    // Offset jumps +60 → +120 during the slice; the local midnight moves an
    // hour earlier in UTC terms. Total seconds must be preserved.
    final tz = _SteppedTimezone(
      beforeOffset: 60,
      afterOffset: 120,
      switchAtUtc: DateTime.utc(2026, 3, 29, 1),
    );
    final start = DateTime.utc(2026, 3, 28, 21);
    final end = DateTime.utc(2026, 3, 29, 3);
    final totals = allocateDailySeconds([slice('a', start, end)], tz);

    final sum = totals.values.fold<int>(0, (a, b) => a + b);
    expect(sum, end.difference(start).inSeconds);
    expect(
      totals.keys,
      containsAll([DateTime(2026, 3, 28), DateTime(2026, 3, 29)]),
    );
  });

  test('mergeDailyTotals sums overlapping days', () {
    final merged = mergeDailyTotals([
      {DateTime(2026, 8, 10): 100, DateTime(2026, 8, 11): 50},
      {DateTime(2026, 8, 10): 25},
    ]);
    expect(merged, {DateTime(2026, 8, 10): 125, DateTime(2026, 8, 11): 50});
  });
}
