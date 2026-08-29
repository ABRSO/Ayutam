import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ayutam/app/desktop_timer_shortcuts.dart';
import 'package:ayutam/app/providers.dart';
import 'package:ayutam/platform/no_op_timer_platform.dart';

void main() {
  testWidgets('Space is ignored while a TextField is focused', (tester) async {
    final container = ProviderContainer(
      overrides: [
        foregroundTimerNotificationProvider.overrideWithValue(
          NoOpForegroundTimerNotification(),
        ),
        desktopTrayServiceProvider.overrideWithValue(NoOpDesktopTrayService()),
        timerChromeServiceProvider.overrideWithValue(NoOpTimerChromeService()),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: DesktopTimerShortcuts(
            child: Scaffold(body: TextField(autofocus: true)),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'hello');
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('hello'), findsOneWidget);
  });
}
