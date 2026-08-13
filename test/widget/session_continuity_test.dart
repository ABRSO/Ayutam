import 'package:ayutam/app/ayutam_app.dart';
import 'package:ayutam/app/providers.dart';
import 'package:ayutam/bootstrap.dart';
import 'package:ayutam/core/id/id_generator.dart';
import 'package:ayutam/core/time/clock_service.dart';
import 'package:ayutam/core/time/timezone_service.dart';
import 'package:ayutam/database/app_database.dart';
import 'package:ayutam/features/skills/domain/skill.dart';
import 'package:ayutam/features/timer/domain/timer_enums.dart';
import 'package:ayutam/features/skills/presentation/skills_screen.dart';
import 'package:ayutam/features/timer/presentation/completion_screen.dart';
import 'package:ayutam/features/timer/presentation/pre_session_sheet.dart';
import 'package:ayutam/features/timer/presentation/session_heartbeat.dart';
import 'package:ayutam/features/timer/presentation/timer_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeClockService clock;
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() async {
    clock = FakeClockService(initialUtc: DateTime.utc(2026, 7, 22, 12));
    const ids = UuidIdGenerator();
    db = AppDatabase.memory(clock: clock, ids: ids);
    container = await bootstrap(
      clock: clock,
      ids: ids,
      database: db,
      timezones: const FakeTimezoneService(),
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  Future<Skill> createSkill(String name) async {
    final result = await container
        .read(skillServiceProvider)
        .create(name: name);
    container.invalidate(activeSkillsProvider);
    container.invalidate(allSkillsProvider);
    return result.valueOrNull!;
  }

  Future<void> pumpSheet(WidgetTester tester, Skill skill) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(body: PreSessionSheet(skill: skill)),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('pre-session conflict', () {
    testWidgets('offers start and cancel when no session is active', (
      tester,
    ) async {
      final skill = await createSkill('Piano');
      await pumpSheet(tester, skill);

      expect(find.text('Start'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Open active timer'), findsNothing);
    });

    testWidgets('offers open / stop-and-start / cancel for another skill', (
      tester,
    ) async {
      final piano = await createSkill('Piano');
      final guitar = await createSkill('Guitar');
      await container
          .read(timerSessionProvider.notifier)
          .startStopwatch(piano.id);

      await pumpSheet(tester, guitar);

      expect(find.text('Open active timer'), findsOneWidget);
      expect(find.text('Stop active and start this'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Start'), findsNothing);
      expect(find.textContaining('Piano'), findsOneWidget);
    });

    testWidgets('omits stop-and-start when the same skill is running', (
      tester,
    ) async {
      final piano = await createSkill('Piano');
      await container
          .read(timerSessionProvider.notifier)
          .startStopwatch(piano.id);

      await pumpSheet(tester, piano);

      expect(find.text('Open active timer'), findsOneWidget);
      expect(find.text('Stop active and start this'), findsNothing);
      expect(find.text('Start'), findsNothing);
    });
  });

  group('session heartbeat', () {
    testWidgets('keeps beating while the timer route is not on screen', (
      tester,
    ) async {
      final piano = await createSkill('Piano');
      await container
          .read(timerSessionProvider.notifier)
          .startStopwatch(piano.id);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const SessionHeartbeat(
            interval: Duration(milliseconds: 100),
            child: MaterialApp(home: Scaffold(body: Text('Home'))),
          ),
        ),
      );
      await tester.pump();

      final before = container
          .read(timerSessionProvider)
          .value!
          .runtime
          .lastHeartbeatUtc;

      clock.advance(const Duration(minutes: 45));
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pumpAndSettle();

      final after = container
          .read(timerSessionProvider)
          .value!
          .runtime
          .lastHeartbeatUtc;
      expect(after!.isAfter(before!), isTrue);
      expect(after.difference(clock.nowUtc()).inSeconds.abs(), lessThan(2));
    });

    testWidgets('stops beating once the session is no longer running', (
      tester,
    ) async {
      final piano = await createSkill('Piano');
      final notifier = container.read(timerSessionProvider.notifier);
      await notifier.startStopwatch(piano.id);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const SessionHeartbeat(
            interval: Duration(milliseconds: 100),
            child: MaterialApp(home: Scaffold(body: Text('Home'))),
          ),
        ),
      );
      await tester.pump();

      await notifier.pause();
      await tester.pump();

      final before = container
          .read(timerSessionProvider)
          .value!
          .runtime
          .lastHeartbeatUtc;
      clock.advance(const Duration(minutes: 45));
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pumpAndSettle();

      final after = container
          .read(timerSessionProvider)
          .value!
          .runtime
          .lastHeartbeatUtc;
      expect(after, before);
    });
  });

  group('cold-start timer navigation', () {
    testWidgets('back returns to Skills without stopping the session', (
      tester,
    ) async {
      final piano = await createSkill('Piano');
      await container
          .read(timerSessionProvider.notifier)
          .startStopwatch(piano.id);

      // New container + app boot simulates process death → recoverOnStartup.
      final cold = await bootstrap(
        clock: clock,
        ids: const UuidIdGenerator(),
        database: db,
        timezones: const FakeTimezoneService(),
      );
      addTearDown(cold.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(container: cold, child: const AyutamApp()),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TimerScreen), findsOneWidget);
      expect(find.byTooltip('Back'), findsOneWidget);

      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();

      expect(find.byType(TimerScreen), findsNothing);
      expect(find.text('Ayutam'), findsWidgets);
      expect(
        cold.read(timerSessionProvider).value!.runtime.machineState,
        TimerMachineState.running,
      );
      expect(find.textContaining('Session still running'), findsOneWidget);
    });
  });

  testWidgets('Stop → Completion → Back → Play → Open → Completion screen', (
    tester,
  ) async {
    final piano = await createSkill('Piano');
    final notifier = container.read(timerSessionProvider.notifier);
    await notifier.startStopwatch(piano.id);
    clock.advance(const Duration(minutes: 3));
    await notifier.stop();

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: SkillsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Play'));
    await tester.tap(find.text('Play'));
    await tester.pumpAndSettle();
    expect(find.text('Open completion'), findsOneWidget);

    await tester.tap(find.text('Open completion'));
    await tester.pumpAndSettle();

    expect(find.byType(CompletionScreen), findsOneWidget);
    expect(find.text('Session complete'), findsOneWidget);
    expect(find.byType(TimerScreen), findsNothing);
  });

  testWidgets('long session warns and does not auto-stop', (tester) async {
    final piano = await createSkill('Piano');
    await container
        .read(timerSessionProvider.notifier)
        .startStopwatch(piano.id);
    clock.advance(const Duration(hours: 8));

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(home: TimerScreen(skillId: piano.id)),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Long session'), findsOneWidget);
    expect(find.textContaining('will not auto-stop'), findsWidgets);
    expect(
      container.read(timerSessionProvider).value!.runtime.machineState,
      TimerMachineState.running,
    );
  });
}
