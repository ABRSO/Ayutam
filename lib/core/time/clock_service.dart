/// Injectable wall + monotonic clock for timer math and tests.
abstract class ClockService {
  /// Current UTC wall-clock time.
  DateTime nowUtc();

  /// Monotonic elapsed microseconds since an arbitrary epoch (process-local).
  int monotonicMicros();
}

/// Production clock using [DateTime.now] and [Stopwatch].
final class SystemClockService implements ClockService {
  SystemClockService() : _stopwatch = Stopwatch()..start();

  final Stopwatch _stopwatch;

  @override
  DateTime nowUtc() => DateTime.now().toUtc();

  @override
  int monotonicMicros() => _stopwatch.elapsedMicroseconds;
}

/// Deterministic clock for unit tests.
final class FakeClockService implements ClockService {
  FakeClockService({DateTime? initialUtc, int initialMonotonicMicros = 0})
    : _utc = (initialUtc ?? DateTime.utc(2026, 7, 22, 12)).toUtc(),
      _monotonicMicros = initialMonotonicMicros;

  DateTime _utc;
  int _monotonicMicros;

  @override
  DateTime nowUtc() => _utc;

  @override
  int monotonicMicros() => _monotonicMicros;

  void advance(Duration duration) {
    _utc = _utc.add(duration);
    _monotonicMicros += duration.inMicroseconds;
  }

  void setUtc(DateTime value) {
    _utc = value.toUtc();
  }
}
