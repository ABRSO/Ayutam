import 'dart:async';

import 'package:ayutam/app/ayutam_app.dart';
import 'package:ayutam/app/platform_integration_host.dart';
import 'package:ayutam/app/providers.dart';
import 'package:ayutam/core/id/id_generator.dart';
import 'package:ayutam/core/time/clock_service.dart';
import 'package:ayutam/core/time/timezone_service.dart';
import 'package:ayutam/database/app_database.dart';
import 'package:ayutam/features/settings/domain/settings_repository.dart';
import 'package:ayutam/features/timer/domain/timer_platform_ports.dart';
import 'package:ayutam/features/timer/presentation/completion_screen.dart';
import 'package:ayutam/features/timer/presentation/timer_screen.dart';
import 'package:ayutam/platform/no_op_timer_platform.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class RecordingWindow implements DesktopWindowLifecycle {
  final closes = StreamController<void>.broadcast();
  int hides = 0;
  int shows = 0;
  int quits = 0;

  @override
  Stream<void> get closeRequested => closes.stream;

  @override
  Future<void> ensureReady() async {}

  @override
  void setCloseToTray(bool enabled) {}

  @override
  Future<void> showAndFocus() async {
    shows++;
  }

  @override
  Future<void> hideToTray() async {
    hides++;
  }

  @override
  Future<void> quit() async {
    quits++;
  }

  @override
  Future<void> dispose() => closes.close();
}

class RecordingTray extends NoOpDesktopTrayService {
  var fail = false;

  @override
  Future<void> sync(TimerPlatformProjection projection) async {
    if (fail) {
      throw StateError('Tray unavailable');
    }
    await super.sync(projection);
  }
}

void main() {
  late AppDatabase db;
  late ProviderContainer container;
  late NoOpTimerChromeService chrome;
  late RecordingWindow window;
  late RecordingTray tray;
  late String skillId;

  setUp(() async {
    final clock = FakeClockService();
    const ids = UuidIdGenerator();
    db = AppDatabase.memory(clock: clock, ids: ids);
    await db.ensureSeeded(clock: clock, ids: ids);
    chrome = NoOpTimerChromeService();
    window = RecordingWindow();
    tray = RecordingTray();
    container = ProviderContainer(
      overrides: [
        clockServiceProvider.overrideWithValue(clock),
        timezoneServiceProvider.overrideWithValue(const FakeTimezoneService()),
        idGeneratorProvider.overrideWithValue(ids),
        appDatabaseProvider.overrideWithValue(db),
        timerChromeServiceProvider.overrideWithValue(chrome),
        desktopWindowLifecycleProvider.overrideWithValue(window),
        desktopTrayServiceProvider.overrideWithValue(tray),
        foregroundTimerNotificationProvider.overrideWithValue(
          NoOpForegroundTimerNotification(),
        ),
      ],
    );
    final skill =
        (await container.read(skillServiceProvider).create(name: 'QA Practice'))
            .valueOrNull!;
    skillId = skill.id;
    await container
        .read(timerSessionProvider.notifier)
        .startStopwatch(skill.id);
    await container
        .read(settingsRepositoryProvider)
        .writeValue(
          key: SettingsKeys.closeToTrayExplained,
          valueJson: '"true"',
          updatedAtUtc: clock.nowUtc(),
          sourceDeviceId: await db.requireDeviceId(),
        );
  });

  tearDown(() async {
    container.dispose();
    await window.dispose();
    await db.close();
  });

  Future<void> pumpHost(WidgetTester tester) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          navigatorKey: ayutamNavigatorKey,
          scaffoldMessengerKey: ayutamScaffoldMessengerKey,
          home: const PlatformIntegrationHost(
            child: Scaffold(body: Text('Home')),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    if (!tray.fail) {
      for (var i = 0; i < 20 && !tray.isAvailable; i++) {
        await tester.pump(const Duration(milliseconds: 20));
      }
      expect(tray.isAvailable, isTrue);
    }
  }

  Future<void> waitForChrome(WidgetTester tester) async {
    for (var i = 0; i < 40 && chrome.enterCount == 0; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  testWidgets(
    'saved false chrome settings are respected on first Timer route',
    (tester) async {
      await container.read(settingsServiceProvider).setKeepScreenAwake(false);
      await container
          .read(settingsServiceProvider)
          .setForceLandscapeAndroid(false);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(home: TimerScreen(skillId: skillId)),
        ),
      );
      await waitForChrome(tester);
      final entered = chrome.enterCount;
      final applied = [chrome.keepScreenAwakeActive, chrome.landscapeRequested];
      final persistedAwake = await container
          .read(settingsServiceProvider)
          .keepScreenAwake();
      final persistedLandscape = await container
          .read(settingsServiceProvider)
          .forceLandscapeAndroid();
      await tester.pumpWidget(const SizedBox.shrink());
      expect([persistedAwake, persistedLandscape], [false, false]);
      expect(entered, 1);
      expect(applied, [false, false]);
    },
  );

  testWidgets('unset chrome settings still default to on', (tester) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(home: TimerScreen(skillId: skillId)),
      ),
    );
    await waitForChrome(tester);
    final entered = chrome.enterCount;
    final applied = [chrome.keepScreenAwakeActive, chrome.landscapeRequested];
    await tester.pumpWidget(const SizedBox.shrink());
    expect(entered, 1);
    expect(applied, [true, true]);
  });

  testWidgets(
    'tray Exit restores hidden window before displaying confirmation',
    (tester) async {
      await pumpHost(tester);
      window.closes.add(null);
      await tester.pumpAndSettle();
      expect(window.hides, 1, reason: 'A live tray can hide the window');
      tray.emitAction(TimerPlatformAction.exitApp);
      await tester.pumpAndSettle();
      expect(find.text('Exit Ayutam?'), findsOneWidget);
      expect(
        window.shows,
        greaterThan(0),
        reason: 'The hidden window must be visible before the user can answer',
      );
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox.shrink());
      expect(window.quits, 0);
    },
  );

  testWidgets('close keeps window accessible when tray synchronisation fails', (
    tester,
  ) async {
    tray.fail = true;
    await pumpHost(tester);
    window.closes.add(null);
    await tester.pumpAndSettle();
    expect(window.hides, 0);
    expect(find.text('System tray unavailable'), findsOneWidget);
    await tester.tap(find.text('Keep open'));
    await tester.pumpAndSettle();
    expect(window.hides, 0);
    expect(window.quits, 0);

    window.closes.add(null);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Exit'));
    await tester.pumpAndSettle();
    expect(window.hides, 0);
    expect(window.quits, 1);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('platform Stop replaces a visible timer with one completion', (
    tester,
  ) async {
    await pumpHost(tester);
    unawaited(
      ayutamNavigatorKey.currentState!.push(
        MaterialPageRoute<void>(builder: (_) => TimerScreen(skillId: skillId)),
      ),
    );
    await tester.pumpAndSettle();
    await waitForChrome(tester);
    expect(chrome.keepScreenAwakeActive, isTrue);

    tray.emitAction(TimerPlatformAction.stop);
    await tester.pumpAndSettle();

    expect(
      find.byType(CompletionScreen, skipOffstage: false).evaluate().length,
      1,
    );
    expect(
      find.byType(TimerScreen, skipOffstage: false).evaluate().length,
      0,
      reason: 'Stopping a visible timer should replace its route',
    );
    expect(chrome.keepScreenAwakeActive, isFalse);

    ayutamNavigatorKey.currentState!.pop();
    await tester.pumpAndSettle();
    expect(find.byType(TimerScreen), findsNothing);
    expect(find.text('Running'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });

  testWidgets('platform Stop from home opens one completion route', (
    tester,
  ) async {
    await pumpHost(tester);
    tray.emitAction(TimerPlatformAction.stop);
    await tester.pumpAndSettle();
    expect(find.byType(CompletionScreen), findsOneWidget);
    expect(find.byType(TimerScreen), findsNothing);
    ayutamNavigatorKey.currentState!.pop();
    await tester.pumpAndSettle();
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Running'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
