import 'dart:async';
import 'dart:io';

import 'package:ayutam/app/app_shell.dart';
import 'package:ayutam/app/ayutam_app.dart';
import 'package:ayutam/app/platform_integration_host.dart';
import 'package:ayutam/app/providers.dart';
import 'package:ayutam/core/id/id_generator.dart';
import 'package:ayutam/core/time/clock_service.dart';
import 'package:ayutam/core/time/timezone_service.dart';
import 'package:ayutam/database/app_database.dart';
import 'package:ayutam/features/timer/domain/timer_enums.dart';
import 'package:ayutam/features/timer/domain/timer_platform_ports.dart';
import 'package:ayutam/features/timer/presentation/completion_screen.dart';
import 'package:ayutam/features/timer/presentation/session_heartbeat.dart';
import 'package:ayutam/features/timer/presentation/timer_screen.dart';
import 'package:ayutam/platform/no_op_timer_platform.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

class RecordingWindow implements DesktopWindowLifecycle {
  final closes = StreamController<void>.broadcast();
  int hides = 0;
  int quits = 0;

  @override
  Stream<void> get closeRequested => closes.stream;

  @override
  Future<void> ensureReady() async {}

  @override
  void setCloseToTray(bool enabled) {}

  @override
  Future<void> showAndFocus() async {}

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

void main() {
  late FakeClockService clock;
  late AppDatabase db;
  late ProviderContainer container;
  late RecordingWindow window;
  late NoOpDesktopTrayService tray;

  setUp(() async {
    clock = FakeClockService(initialUtc: DateTime.utc(2026, 9, 23, 12));
    const ids = UuidIdGenerator();
    db = AppDatabase.memory(clock: clock, ids: ids);
    await db.ensureSeeded(clock: clock, ids: ids);
    window = RecordingWindow();
    tray = NoOpDesktopTrayService();
    container = ProviderContainer(
      overrides: [
        clockServiceProvider.overrideWithValue(clock),
        timezoneServiceProvider.overrideWithValue(const FakeTimezoneService()),
        idGeneratorProvider.overrideWithValue(ids),
        appDatabaseProvider.overrideWithValue(db),
        timerChromeServiceProvider.overrideWithValue(NoOpTimerChromeService()),
        desktopWindowLifecycleProvider.overrideWithValue(window),
        desktopTrayServiceProvider.overrideWithValue(tray),
        foregroundTimerNotificationProvider.overrideWithValue(
          NoOpForegroundTimerNotification(),
        ),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await window.dispose();
    await db.close();
  });

  void useDesktopSize(WidgetTester tester) {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Future<String> startSession() async {
    final skill =
        (await container.read(skillServiceProvider).create(name: 'Piano'))
            .valueOrNull!;
    await container
        .read(timerSessionProvider.notifier)
        .startStopwatch(skill.id);
    return skill.id;
  }

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const AyutamApp()),
    );
    await tester.pumpAndSettle();
  }

  TimerMachineState? machineState() =>
      container.read(timerSessionProvider).asData?.value.runtime.machineState;

  group('app-lifetime hosts', () {
    testWidgets('survive Save → home and still handle window close', (
      tester,
    ) async {
      useDesktopSize(tester);
      await startSession();
      await pumpApp(tester);
      expect(find.byType(TimerScreen), findsOneWidget);

      tray.emitAction(TimerPlatformAction.stop);
      await tester.pumpAndSettle();
      expect(find.byType(CompletionScreen), findsOneWidget);

      await tester.ensureVisible(find.text('Save Session'));
      await tester.tap(find.text('Save Session'));
      await tester.pumpAndSettle();
      expect(find.byType(AppShell), findsOneWidget);
      expect(find.byType(CompletionScreen), findsNothing);

      expect(find.byType(SessionHeartbeat), findsOneWidget);
      expect(find.byType(PlatformIntegrationHost), findsOneWidget);
      expect(find.byType(DropTarget), findsOneWidget);

      window.closes.add(null);
      await tester.pumpAndSettle();
      expect(window.quits, 1, reason: 'X after a saved session must quit');
    });

    testWidgets('survive pushAndRemoveUntil of every route', (tester) async {
      useDesktopSize(tester);
      await pumpApp(tester);
      unawaited(
        ayutamNavigatorKey.currentState!.pushAndRemoveUntil(
          MaterialPageRoute<void>(builder: (_) => const AppShell()),
          (_) => false,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(PlatformIntegrationHost), findsOneWidget);
      expect(find.byType(DropTarget), findsOneWidget);

      window.closes.add(null);
      await tester.pumpAndSettle();
      expect(window.quits, 1);
    });

    testWidgets('repeated close while a prompt is open shows one dialog', (
      tester,
    ) async {
      useDesktopSize(tester);
      await startSession();
      await pumpApp(tester);

      window.closes.add(null);
      window.closes.add(null);
      await tester.pumpAndSettle();
      expect(find.text('Close hides to tray'), findsOneWidget);
      await tester.tap(find.text('Got it'));
      await tester.pumpAndSettle();
      expect(window.hides, 1);
      expect(window.quits, 0);
    });
  });

  group('timer Space shortcut', () {
    testWidgets('Space pauses and resumes on the Timer screen', (tester) async {
      useDesktopSize(tester);
      await startSession();
      await pumpApp(tester);
      expect(find.byType(TimerScreen), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(machineState(), TimerMachineState.paused);

      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(machineState(), TimerMachineState.running);
    });

    testWidgets('Space on a focused control activates only that control', (
      tester,
    ) async {
      useDesktopSize(tester);
      await startSession();
      await pumpApp(tester);

      // Back button, then Pause.
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      final focused = FocusManager.instance.primaryFocus?.context;
      expect(
        focused?.findAncestorWidgetOfExactType<IconButton>(),
        isNotNull,
        reason: 'Tab should move focus onto a timer control',
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(
        machineState(),
        TimerMachineState.paused,
        reason: 'One Space must toggle once, not screen + button',
      );
    });

    testWidgets('Space does nothing to the session outside the Timer', (
      tester,
    ) async {
      useDesktopSize(tester);
      await startSession();
      await pumpApp(tester);

      ayutamNavigatorKey.currentState!.pop();
      await tester.pumpAndSettle();
      expect(find.byType(TimerScreen), findsNothing);

      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(machineState(), TimerMachineState.running);
    });
  });

  group('drag-and-drop import after Save → home', () {
    Future<void> replaceHomeRoute(WidgetTester tester) async {
      unawaited(
        ayutamNavigatorKey.currentState!.pushAndRemoveUntil(
          MaterialPageRoute<void>(builder: (_) => const AppShell()),
          (_) => false,
        ),
      );
      await tester.pumpAndSettle();
    }

    /// Same channel messages the Windows plugin sends for a real OLE drop.
    Future<void> platformDrop(WidgetTester tester, List<String> paths) async {
      const codec = StandardMethodCodec();
      final messenger = tester.binding.defaultBinaryMessenger;
      Future<void> send(String method, Object? args) {
        return messenger.handlePlatformMessage(
          'desktop_drop',
          codec.encodeMethodCall(MethodCall(method, args)),
          (_) {},
        );
      }

      await tester.runAsync(() async {
        await send('entered', <double>[200, 200]);
        await send('updated', <double>[210, 210]);
        await send('performOperation', paths);
      });
    }

    Future<void> settleIo(WidgetTester tester, Finder until) async {
      for (var i = 0; i < 40 && until.evaluate().isEmpty; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)),
        );
        await tester.pump(const Duration(milliseconds: 50));
      }
      await tester.pumpAndSettle();
    }

    testWidgets('a dropped backup opens the import preview', (tester) async {
      PackageInfo.setMockInitialValues(
        appName: 'Ayutam',
        packageName: 'com.ayutam.ayutam',
        version: '0.6.0',
        buildNumber: '6',
        buildSignature: '',
      );
      useDesktopSize(tester);
      await startSession();
      clock.advance(const Duration(minutes: 5));
      await container.read(timerSessionProvider.notifier).stop();
      await container.read(timerSessionProvider.notifier).saveCompletion();
      await pumpApp(tester);
      await replaceHomeRoute(tester);

      final file = (await tester.runAsync(() async {
        final exported = await container
            .read(backupServiceProvider)
            .exportSkilltrackerBytes();
        final bytes = exported.when(
          success: (b) => b,
          failure: (f) => throw StateError('${f.code} ${f.message} ${f.cause}'),
        );
        final dir = await Directory.systemTemp.createTemp('ayutam_drop');
        addTearDown(() => dir.delete(recursive: true));
        return File('${dir.path}${Platform.pathSeparator}backup.skilltracker')
          ..writeAsBytesSync(bytes);
      }))!;

      await platformDrop(tester, [file.path]);
      await settleIo(tester, find.text('Merge'));

      expect(find.text('Merge'), findsOneWidget);
      expect(find.text('Replace all local data'), findsOneWidget);
    });

    testWidgets('an unsupported file is rejected without reading it', (
      tester,
    ) async {
      useDesktopSize(tester);
      await pumpApp(tester);
      await replaceHomeRoute(tester);

      await platformDrop(tester, [r'C:\does-not-exist\notes.txt']);
      await tester.pumpAndSettle();
      expect(
        find.text('Unsupported file. Use .skilltracker, .json, or .sqlite.'),
        findsOneWidget,
      );
    });

    testWidgets('two files at once are rejected', (tester) async {
      useDesktopSize(tester);
      await pumpApp(tester);
      await replaceHomeRoute(tester);

      await platformDrop(tester, ['a.skilltracker', 'b.skilltracker']);
      await tester.pumpAndSettle();
      expect(find.text('Drop a single backup file.'), findsOneWidget);
    });
  });

  group('Skills Ctrl+N', () {
    Future<void> pressCtrlN(WidgetTester tester) async {
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyN);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();
    }

    testWidgets('opens the New skill editor once', (tester) async {
      useDesktopSize(tester);
      await pumpApp(tester);

      await pressCtrlN(tester);
      expect(find.text('New skill'), findsOneWidget);

      await pressCtrlN(tester);
      expect(find.text('New skill'), findsOneWidget);
    });

    testWidgets('is inactive on other tabs', (tester) async {
      useDesktopSize(tester);
      await pumpApp(tester);
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();

      await pressCtrlN(tester);
      expect(find.text('New skill'), findsNothing);
    });

    testWidgets('plain N does nothing', (tester) async {
      useDesktopSize(tester);
      await pumpApp(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyN);
      await tester.pumpAndSettle();
      expect(find.text('New skill'), findsNothing);
    });
  });
}
