import 'package:ayutam/app/ayutam_app.dart';
import 'package:ayutam/bootstrap.dart';
import 'package:ayutam/core/id/id_generator.dart';
import 'package:ayutam/core/time/clock_service.dart';
import 'package:ayutam/database/app_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('app loads Skills empty shell with local database', (
    tester,
  ) async {
    final clock = FakeClockService();
    const ids = UuidIdGenerator();
    final db = AppDatabase.memory(clock: clock, ids: ids);
    final container = await bootstrap(clock: clock, ids: ids, database: db);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const AyutamApp()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ayutam'), findsWidgets);
    expect(find.textContaining('Create your first skill'), findsOneWidget);
    expect(find.text('Skills'), findsOneWidget);
    expect(find.text('Learning Log'), findsOneWidget);
    expect(find.text('Statistics'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);

    await db.close();
    container.dispose();
  });

  testWidgets('rail navigation appears on wide layouts', (tester) async {
    final clock = FakeClockService();
    const ids = UuidIdGenerator();
    final db = AppDatabase.memory(clock: clock, ids: ids);
    final container = await bootstrap(clock: clock, ids: ids, database: db);

    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const AyutamApp()),
    );
    await tester.pumpAndSettle();

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);

    await db.close();
    container.dispose();
  });
}
