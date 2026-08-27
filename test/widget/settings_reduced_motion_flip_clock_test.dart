import 'package:ayutam/app/ayutam_app.dart';
import 'package:ayutam/app/providers.dart';
import 'package:ayutam/bootstrap.dart';
import 'package:ayutam/core/id/id_generator.dart';
import 'package:ayutam/core/time/clock_service.dart';
import 'package:ayutam/core/time/timezone_service.dart';
import 'package:ayutam/database/app_database.dart';
import 'package:ayutam/features/settings/presentation/settings_screen.dart';
import 'package:ayutam/features/timer/presentation/widgets/flip_clock.dart';
import 'package:ayutam/features/timer/presentation/widgets/flip_digit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'Settings Reduced motion persists and disables FlipClock 3D transitions',
    (tester) async {
      final clock = FakeClockService();
      const ids = UuidIdGenerator();
      final db = AppDatabase.memory(clock: clock, ids: ids);
      final container = await bootstrap(
        clock: clock,
        ids: ids,
        database: db,
        timezones: const FakeTimezoneService(),
      );
      addTearDown(() async {
        container.dispose();
        await db.close();
      });

      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            builder: (context, child) {
              return ReducedMotionScope(child: child!);
            },
            home: const _SettingsFlipClockHarness(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final flipTransforms = find.descendant(
        of: find.byType(FlipClock),
        matching: find.byType(Transform),
      );
      expect(container.read(reducedMotionProvider).asData?.value, isFalse);

      await tester.tap(find.byKey(const ValueKey('advance-clock')));
      await tester.pump();
      expect(flipTransforms, findsOneWidget);
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(SwitchListTile, 'Reduced motion'));
      await tester.pumpAndSettle();

      expect(
        await container.read(settingsServiceProvider).reducedMotion(),
        isTrue,
      );
      expect(container.read(reducedMotionProvider).asData?.value, isTrue);
      expect(
        tester
            .widgetList<FlipDigit>(
              find.descendant(
                of: find.byType(FlipClock),
                matching: find.byType(FlipDigit),
              ),
            )
            .every((digit) => digit.reduceMotion),
        isTrue,
      );

      await tester.tap(find.byKey(const ValueKey('advance-clock')));
      await tester.pump();
      expect(flipTransforms, findsNothing);
    },
  );
}

class _SettingsFlipClockHarness extends StatefulWidget {
  const _SettingsFlipClockHarness();

  @override
  State<_SettingsFlipClockHarness> createState() =>
      _SettingsFlipClockHarnessState();
}

class _SettingsFlipClockHarnessState extends State<_SettingsFlipClockHarness> {
  var _totalSeconds = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const Expanded(child: SettingsScreen()),
          SizedBox(
            width: 480,
            height: 180,
            child: FlipClock(totalSeconds: _totalSeconds),
          ),
          TextButton(
            key: const ValueKey('advance-clock'),
            onPressed: () => setState(() => _totalSeconds += 1),
            child: const Text('Advance clock'),
          ),
        ],
      ),
    );
  }
}
