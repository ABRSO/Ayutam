import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ayutam/features/timer/presentation/widgets/flip_clock.dart';
import 'package:ayutam/features/timer/presentation/widgets/flip_digit.dart';

void main() {
  group('flipClockDigits', () {
    test('pads hours to at least two digits', () {
      final digits = flipClockDigits(65);
      expect(digits.hours, [0, 0]);
      expect(digits.minutes, [0, 1]);
      expect(digits.seconds, [0, 5]);
    });

    test('expands hours beyond 99 unbounded', () {
      final digits = flipClockDigits(100 * 3600 + 2 * 60 + 3);
      expect(digits.hours, [1, 0, 0]);
      expect(digits.minutes, [0, 2]);
      expect(digits.seconds, [0, 3]);
      expect(formatFlipClockDuration(100 * 3600 + 2 * 60 + 3), '100:02:03');
    });

    test('59 seconds and 00 carry produce independent digit lists', () {
      expect(flipClockDigits(59).seconds, [5, 9]);
      expect(flipClockDigits(60).seconds, [0, 0]);
      expect(flipClockDigits(49).seconds, [4, 9]);
      expect(flipClockDigits(50).seconds, [5, 0]);
    });
  });

  group('FlipDigit', () {
    testWidgets('updates digit without animation when reduceMotion', (
      tester,
    ) async {
      var digit = 1;
      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              return Scaffold(
                body: Column(
                  children: [
                    FlipDigit(
                      digit: digit,
                      width: 48,
                      height: 72,
                      reduceMotion: true,
                    ),
                    TextButton(
                      onPressed: () => setState(() => digit = 2),
                      child: const Text('bump'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );

      expect(find.text('1'), findsWidgets);
      await tester.tap(find.text('bump'));
      await tester.pump();
      expect(find.text('2'), findsWidgets);
    });

    testWidgets('mechanical flip settles on next digit after duration', (
      tester,
    ) async {
      var digit = 9;
      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              return Scaffold(
                body: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FlipDigit(digit: digit, width: 64, height: 96),
                      TextButton(
                        onPressed: () => setState(() => digit = 0),
                        child: const Text('flip'),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      );

      expect(find.text('9'), findsWidgets);
      await tester.tap(find.text('flip'));
      await tester.pump();
      // Mid flip — both layers may still be in the tree.
      await tester.pump(const Duration(milliseconds: 240));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('0'), findsWidgets);
    });

    testWidgets('queues a newer value while a flip is in progress', (
      tester,
    ) async {
      var digit = 1;
      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              return Scaffold(
                body: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FlipDigit(digit: digit, width: 64, height: 96),
                      TextButton(
                        onPressed: () => setState(() => digit += 1),
                        child: const Text('bump'),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('bump')); // 1 → 2
      await tester.pump();
      await tester.tap(find.text('bump')); // queue 3
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1000));
      expect(find.text('3'), findsWidgets);
    });
  });

  group('FlipClock', () {
    testWidgets('exposes one combined semantics label', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 800,
                height: 240,
                child: FlipClock(totalSeconds: 3661, reduceMotion: true),
              ),
            ),
          ),
        ),
      );

      expect(
        tester.getSemantics(find.byType(FlipClock)),
        matchesSemantics(label: 'Duration 01:01:01', isReadOnly: true),
      );
    });
  });
}
