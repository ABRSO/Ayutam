import 'package:ayutam/app/ayutam_app.dart';
import 'package:ayutam/app/providers.dart';
import 'package:ayutam/bootstrap.dart';
import 'package:ayutam/core/id/id_generator.dart';
import 'package:ayutam/core/time/clock_service.dart';
import 'package:ayutam/core/time/timezone_service.dart';
import 'package:ayutam/database/app_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeClockService clock;
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() async {
    clock = FakeClockService(initialUtc: DateTime.utc(2026, 8, 13, 12));
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

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const AyutamApp()),
    );
    await tester.pumpAndSettle();
  }

  void useViewSize(WidgetTester tester, Size size) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('app loads Skills empty shell with local database', (
    tester,
  ) async {
    await pumpApp(tester);

    expect(find.text('Ayutam'), findsWidgets);
    expect(find.textContaining('Create your first skill'), findsOneWidget);
    expect(find.text('Skills'), findsOneWidget);
    expect(find.text('Learning Log'), findsOneWidget);
    expect(find.text('Statistics'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });

  testWidgets('rail navigation appears on wide layouts', (tester) async {
    useViewSize(tester, const Size(1400, 900));
    await pumpApp(tester);

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('system back from Statistics returns to Skills then exits', (
    tester,
  ) async {
    useViewSize(tester, const Size(400, 800));
    await pumpApp(tester);

    await tester.tap(find.text('Statistics'));
    await tester.pumpAndSettle();
    expect(container.read(appShellIndexProvider), 2);

    // canPop is false on non-Skills tabs: pop is consumed by switching home.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(container.read(appShellIndexProvider), 0);
    expect(find.textContaining('Create your first skill'), findsOneWidget);

    // From Skills, a further system back is not remapped to another tab
    // (canPop true → framework may exit the app).
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(container.read(appShellIndexProvider), 0);
  });

  testWidgets('Escape from Settings returns to Skills on desktop', (
    tester,
  ) async {
    useViewSize(tester, const Size(1400, 900));
    await pumpApp(tester);

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(container.read(appShellIndexProvider), 3);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(container.read(appShellIndexProvider), 0);
  });
}
