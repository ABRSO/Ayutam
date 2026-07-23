import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ayutam/core/theme/skill_accent_palette.dart';
import 'package:ayutam/features/timer/presentation/widgets/timer_icon_control.dart';

void main() {
  test('nextAccent prefers unused palette colours', () {
    final first = SkillAccentPalette.colors.first;
    final second = SkillAccentPalette.nextAccent([
      SkillAccentPalette.toArgb(first),
    ]);
    expect(second, isNot(equals(first)));
    expect(SkillAccentPalette.colors.contains(second), isTrue);
  });

  testWidgets('Pause and Stop expose semantics labels', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Row(
            children: [
              TimerIconControl(
                tooltip: 'Pause',
                semanticLabel: 'Pause stopwatch',
                icon: Icons.pause,
                onPressed: () {},
              ),
              TimerIconControl(
                tooltip: 'Stop',
                semanticLabel: 'Stop stopwatch',
                icon: Icons.stop,
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.bySemanticsLabel('Pause stopwatch'), findsOneWidget);
    expect(find.bySemanticsLabel('Stop stopwatch'), findsOneWidget);
  });
}
