import 'package:ayutam/app/providers.dart';
import 'package:ayutam/bootstrap.dart';
import 'package:ayutam/core/id/id_generator.dart';
import 'package:ayutam/core/time/clock_service.dart';
import 'package:ayutam/core/time/timezone_service.dart';
import 'package:ayutam/database/app_database.dart';
import 'package:ayutam/features/statistics/domain/statistics_models.dart';
import 'package:ayutam/features/statistics/presentation/cumulative_chart.dart';
import 'package:ayutam/features/statistics/presentation/practice_heatmap.dart';
import 'package:ayutam/features/statistics/presentation/statistics_screen.dart';
import 'package:ayutam/features/statistics/presentation/summary_table.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeClockService clock;
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() async {
    clock = FakeClockService(initialUtc: DateTime.utc(2026, 8, 6, 12));
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

  Future<String> completedSession({
    String skill = 'Piano',
    Duration length = const Duration(minutes: 10),
  }) async {
    final created = await container
        .read(skillServiceProvider)
        .create(name: skill);
    final skillId = created.valueOrNull!.id;
    final notifier = container.read(timerSessionProvider.notifier);
    expect(await notifier.startStopwatch(skillId), isNull);
    clock.advance(length);
    expect(await notifier.stop(), isNull);
    expect(await notifier.saveCompletion(), isNull);
    container.invalidate(activeSkillsProvider);
    container.invalidate(allSkillsProvider);
    return skillId;
  }

  Future<void> pumpStats(WidgetTester tester) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: StatisticsScreen()),
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

  // The screen arms a real midnight timer; unmount so the fake-async
  // pending-timer guard stays green at the end of each test.
  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
  }

  testWidgets('shows the guided empty state with no completed sessions', (
    tester,
  ) async {
    await pumpStats(tester);
    expect(
      find.text('Complete a session to begin building your progress chart.'),
      findsOneWidget,
    );
    await unmount(tester);
  });

  testWidgets('summary card and cumulative chart render with data', (
    tester,
  ) async {
    await completedSession();
    await pumpStats(tester);

    expect(find.text('Total active'), findsOneWidget);
    expect(find.text('10m'), findsWidgets);
    expect(find.text('4-week average'), findsOneWidget);
    expect(find.text('Streak'), findsOneWidget);
    expect(find.text('1 day'), findsOneWidget);
    expect(find.byType(CumulativeChartView), findsOneWidget);
    expect(find.byType(LineChart), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('mobile segmented control reaches heatmap and summary table', (
    tester,
  ) async {
    useViewSize(tester, const Size(800, 800));
    await completedSession();
    await pumpStats(tester);

    expect(find.byType(SegmentedButton<int>), findsOneWidget);
    expect(find.byType(TabBar), findsNothing);

    await tester.tap(find.text('Activity'));
    await tester.pumpAndSettle();
    expect(find.byType(PracticeHeatmap), findsOneWidget);
    expect(find.text('Last 12 months'), findsOneWidget);

    await tester.tap(find.text('Summary'));
    await tester.pumpAndSettle();
    expect(find.byType(SummaryTableView), findsOneWidget);
    expect(find.text('Period'), findsOneWidget);
    expect(find.text('Sessions'), findsWidgets);
    await unmount(tester);
  });

  testWidgets('desktop tabs reach heatmap and summary table', (tester) async {
    useViewSize(tester, const Size(1280, 800));
    await completedSession();
    await pumpStats(tester);

    expect(find.byType(TabBar), findsOneWidget);
    expect(find.byType(SegmentedButton<int>), findsNothing);
    expect(find.text('Cumulative'), findsOneWidget);
    expect(find.text('Heatmap'), findsOneWidget);
    expect(find.text('Summary Table'), findsOneWidget);

    await tester.tap(find.text('Heatmap'));
    await tester.pumpAndSettle();
    expect(find.byType(PracticeHeatmap), findsOneWidget);
    expect(find.text('Last 12 months'), findsOneWidget);

    await tester.tap(find.text('Summary Table'));
    await tester.pumpAndSettle();
    expect(find.byType(SummaryTableView), findsOneWidget);
    expect(find.text('Period'), findsOneWidget);
    expect(find.text('Sessions'), findsWidgets);
    await unmount(tester);
  });

  testWidgets('heatmap day popover opens a filtered Learning Log', (
    tester,
  ) async {
    useViewSize(tester, const Size(800, 800));
    await completedSession();
    await pumpStats(tester);

    await tester.tap(find.text('Activity'));
    await tester.pumpAndSettle();

    // Today's cell (fixed clock): semantics label carries date + duration.
    final semantics = tester.ensureSemantics();
    final todayCell = find.bySemanticsLabel(RegExp(r'6 Aug 2026: 10m'));
    expect(todayCell, findsOneWidget);
    await tester.tap(todayCell);
    await tester.pumpAndSettle();

    expect(find.text('Thursday, 6 August 2026'), findsOneWidget);
    expect(find.textContaining('Total practice: 10m'), findsOneWidget);

    await tester.tap(find.text('Open in Learning Log'));
    await tester.pumpAndSettle();
    semantics.dispose();

    expect(container.read(appShellIndexProvider), 1);
    final filters = container.read(learningLogFiltersProvider);
    // Overlap window (not start-based) so cross-midnight sessions that
    // contributed to this day are included.
    expect(filters.overlapStartUtc, DateTime.utc(2026, 8, 6));
    expect(filters.overlapEndUtc, DateTime.utc(2026, 8, 7));
    expect(filters.startAfterUtc, isNull);
    expect(filters.endBeforeUtc, isNull);
    await unmount(tester);
  });

  testWidgets('day rollover reloads on app resume', (tester) async {
    await completedSession();
    await pumpStats(tester);
    expect(find.text('1 day'), findsOneWidget);

    // Two local days later with no new practice: streak grace has expired.
    clock.advance(const Duration(hours: 49));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expect(find.text('0 days'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('idle screen rolls over via the midnight timer', (tester) async {
    await completedSession();
    await pumpStats(tester);
    expect(find.text('1 day'), findsOneWidget);

    // No interaction, no lifecycle event: the armed timer alone must reload
    // once fake time passes the configured-local midnight.
    clock.advance(const Duration(hours: 49));
    await tester.pump(const Duration(hours: 13));
    await tester.pumpAndSettle();

    expect(find.text('0 days'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('fullscreen keeps the picked custom range', (tester) async {
    final bundle = StatsBundle(
      summary: const StatsSummary(
        totalActiveSeconds: 3600,
        sessionCount: 1,
        streakDays: 0,
        fourWeekAverageWeeklySeconds: 0,
      ),
      dailyTotals: {DateTime(2026, 8, 1): 3600},
      dailyTotalsBySkill: const {},
      sessions: const [],
      firstActivityDay: DateTime(2026, 8, 1),
      hasAnyCompletedSession: true,
      generatedForDay: DateTime(2026, 8, 6),
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: CumulativeChartView(
              bundle: bundle,
              scope: const StatsScope.all(),
              skills: const [],
              initialRange: ChartRange.custom,
              initialCustomRange: DateTimeRange(
                start: DateTime(2026, 8, 1),
                end: DateTime(2026, 8, 5),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('1 Aug'), findsOneWidget);

    await tester.tap(find.byTooltip('Fullscreen'));
    await tester.pumpAndSettle();

    expect(find.text('Cumulative practice'), findsOneWidget);
    // The fullscreen chart (background route is offstage) still renders the
    // custom window's first axis label; the old bug silently fell back to
    // the last 30 days, which has no 1 Aug label.
    expect(find.text('1 Aug'), findsOneWidget);
  });

  testWidgets('single-skill scope shows progress and projection line', (
    tester,
  ) async {
    final skillId = await completedSession();
    container.read(statsScopeProvider.notifier).set(StatsScope.single(skillId));
    await pumpStats(tester);

    expect(find.text('Progress'), findsWidgets);
    expect(find.text('Remaining'), findsOneWidget);
    expect(find.textContaining('Projection unavailable'), findsOneWidget);
    await unmount(tester);
  });
}
