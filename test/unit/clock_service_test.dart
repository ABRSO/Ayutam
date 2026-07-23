import 'package:ayutam/core/time/clock_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FakeClockService', () {
    test('starts at the configured UTC time', () {
      final clock = FakeClockService(
        initialUtc: DateTime.utc(2026, 1, 15, 10, 30),
        initialMonotonicMicros: 1_000_000,
      );

      expect(clock.nowUtc(), DateTime.utc(2026, 1, 15, 10, 30));
      expect(clock.monotonicMicros(), 1_000_000);
    });

    test('advance moves wall and monotonic clocks together', () {
      final clock = FakeClockService(initialUtc: DateTime.utc(2026, 7, 22, 12));

      clock.advance(const Duration(minutes: 5, seconds: 30));

      expect(clock.nowUtc(), DateTime.utc(2026, 7, 22, 12, 5, 30));
      expect(
        clock.monotonicMicros(),
        const Duration(minutes: 5, seconds: 30).inMicroseconds,
      );
    });
  });
}
