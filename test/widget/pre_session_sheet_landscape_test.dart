import 'package:ayutam/app/providers.dart';
import 'package:ayutam/bootstrap.dart';
import 'package:ayutam/core/id/id_generator.dart';
import 'package:ayutam/core/time/clock_service.dart';
import 'package:ayutam/core/time/timezone_service.dart';
import 'package:ayutam/database/app_database.dart';
import 'package:ayutam/features/skills/domain/skill.dart';
import 'package:ayutam/features/timer/presentation/pre_session_sheet.dart';
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
    return result.valueOrNull!;
  }

  Future<void> pumpSheetAtSize(
    WidgetTester tester,
    Skill skill,
    Size size,
  ) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

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

  void expectActionsReachable(WidgetTester tester, List<String> labels) {
    expect(tester.takeException(), isNull);
    final viewportBottom = tester.getRect(find.byType(PreSessionSheet)).bottom;
    for (final label in labels) {
      final finder = find.text(label);
      expect(finder, findsOneWidget);
      expect(
        tester.getTopLeft(finder).dy,
        lessThan(viewportBottom),
        reason: '$label top must be inside the sheet viewport',
      );
    }
  }

  testWidgets('start and cancel stay reachable in short landscape', (
    tester,
  ) async {
    final skill = await createSkill('AI');
    await pumpSheetAtSize(tester, skill, const Size(800, 360));

    expectActionsReachable(tester, ['Start', 'Cancel']);

    await tester.tap(find.text('Cancel'));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'open active timer and cancel stay reachable in short landscape',
    (tester) async {
      final skill = await createSkill('AI');
      await container
          .read(timerSessionProvider.notifier)
          .startStopwatch(skill.id);

      await pumpSheetAtSize(tester, skill, const Size(800, 360));

      expectActionsReachable(tester, ['Open active timer', 'Cancel']);

      await tester.ensureVisible(find.text('Cancel'));
      await tester.tap(find.text('Cancel'));
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('conflict actions stay reachable with three buttons', (
    tester,
  ) async {
    final piano = await createSkill('Piano');
    final guitar = await createSkill('Guitar');
    await container
        .read(timerSessionProvider.notifier)
        .startStopwatch(piano.id);

    await pumpSheetAtSize(tester, guitar, const Size(800, 360));

    expectActionsReachable(tester, [
      'Open active timer',
      'Stop active and start this',
      'Cancel',
    ]);
  });
}
