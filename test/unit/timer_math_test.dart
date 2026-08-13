import 'package:ayutam/features/timer/domain/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('remapClosedSegments preserves work/pause ratios and types', () {
    final oldStart = DateTime.utc(2026, 8, 1, 10);
    final oldEnd = DateTime.utc(2026, 8, 1, 10, 12);
    final segments = [
      SessionSegment(
        id: 'a',
        sessionId: 's',
        segmentType: SegmentType.work,
        startAtUtc: oldStart,
        endAtUtc: oldStart.add(const Duration(minutes: 5)),
        durationSeconds: 300,
        createdAtUtc: oldStart,
        updatedAtUtc: oldStart,
      ),
      SessionSegment(
        id: 'b',
        sessionId: 's',
        segmentType: SegmentType.pause,
        startAtUtc: oldStart.add(const Duration(minutes: 5)),
        endAtUtc: oldStart.add(const Duration(minutes: 7)),
        durationSeconds: 120,
        createdAtUtc: oldStart,
        updatedAtUtc: oldStart,
      ),
      SessionSegment(
        id: 'c',
        sessionId: 's',
        segmentType: SegmentType.work,
        startAtUtc: oldStart.add(const Duration(minutes: 7)),
        endAtUtc: oldEnd,
        durationSeconds: 300,
        createdAtUtc: oldStart,
        updatedAtUtc: oldStart,
      ),
    ];

    var n = 0;
    final remapped = TimerMath.remapClosedSegments(
      sessionId: 's',
      segments: segments,
      oldStartUtc: oldStart,
      oldEndUtc: oldEnd,
      newStartUtc: DateTime.utc(2026, 8, 1, 12),
      newEndUtc: DateTime.utc(2026, 8, 1, 12, 24),
      nowUtc: DateTime.utc(2026, 8, 6),
      nextId: () {
        n += 1;
        return 'n$n';
      },
    );

    expect(remapped.map((s) => s.segmentType), [
      SegmentType.work,
      SegmentType.pause,
      SegmentType.work,
    ]);
    expect(
      TimerMath.activeSecondsFromSegments(
        segments: remapped,
        nowUtc: DateTime.utc(2026, 8, 6),
      ),
      20 * 60,
    );
    expect(
      TimerMath.pausedSecondsFromSegments(
        segments: remapped,
        nowUtc: DateTime.utc(2026, 8, 6),
      ),
      4 * 60,
    );
    expect(remapped.first.startAtUtc, DateTime.utc(2026, 8, 1, 12));
    expect(remapped.last.endAtUtc, DateTime.utc(2026, 8, 1, 12, 24));
  });
}
