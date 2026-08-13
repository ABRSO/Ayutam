import 'package:ayutam/app/providers.dart';
import 'package:ayutam/bootstrap.dart';
import 'package:ayutam/core/id/id_generator.dart';
import 'package:ayutam/core/time/clock_service.dart';
import 'package:ayutam/core/time/timezone_service.dart';
import 'package:ayutam/database/app_database.dart';
import 'package:ayutam/features/skills/presentation/skills_screen.dart';
import 'package:flutter/material.dart';
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

  Future<void> createSkill(String name) async {
    await container.read(skillServiceProvider).create(name: name);
    container.invalidate(activeSkillsProvider);
    container.invalidate(allSkillsProvider);
  }

  Future<void> pumpHome(WidgetTester tester) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: SkillsScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  void useViewSize(WidgetTester tester, Size size) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('desktop: New Skill in toolbar, no FAB, centered list', (
    tester,
  ) async {
    useViewSize(tester, const Size(1280, 800));
    await createSkill('Piano');
    await pumpHome(tester);

    // ux-spec §4.2: Create in toolbar on desktop, not a FAB.
    expect(find.byType(FloatingActionButton), findsNothing);
    expect(find.text('New Skill'), findsOneWidget);

    // Centered list with max width ~900–1100.
    final listSize = tester.getSize(find.byType(ListView));
    expect(listSize.width, lessThanOrEqualTo(1000));
    final listLeft = tester.getTopLeft(find.byType(ListView)).dx;
    expect(listLeft, greaterThan(0));

    await tester.tap(find.text('New Skill'));
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsOneWidget);
  });

  testWidgets('mobile: New Skill stays a FAB', (tester) async {
    useViewSize(tester, const Size(400, 800));
    await createSkill('Piano');
    await pumpHome(tester);

    expect(find.byType(FloatingActionButton), findsOneWidget);
  });

  testWidgets('search with no matches names the search, not the filter', (
    tester,
  ) async {
    useViewSize(tester, const Size(400, 800));
    await createSkill('Piano');
    await pumpHome(tester);

    await tester.tap(find.byTooltip('Search skills'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'xyz');
    await tester.pumpAndSettle();

    expect(find.text('No skills match your search.'), findsOneWidget);
    expect(find.text('No skills in progress.'), findsNothing);

    // Without a query the filter-specific message returns.
    await tester.enterText(find.byType(TextField), '');
    await tester.pumpAndSettle();
    expect(find.text('Piano'), findsOneWidget);
  });
}
