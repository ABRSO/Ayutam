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
                    FlipDigit(digit: digit, reduceMotion: true),
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
  });

  group('FlipClock', () {
    testWidgets('exposes one combined semantics label', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FlipClock(totalSeconds: 3661, reduceMotion: true),
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
