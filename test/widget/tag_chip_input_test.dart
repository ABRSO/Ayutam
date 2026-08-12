import 'package:ayutam/app/providers.dart';
import 'package:ayutam/bootstrap.dart';
import 'package:ayutam/core/id/id_generator.dart';
import 'package:ayutam/core/time/clock_service.dart';
import 'package:ayutam/core/time/timezone_service.dart';
import 'package:ayutam/database/app_database.dart';
import 'package:ayutam/features/learning_log/presentation/widgets/tag_chip_input.dart';
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

  testWidgets('commitPending adds typed text without pressing Enter', (
    tester,
  ) async {
    final controller = TagChipInputController();
    var tags = <String>[];

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: TagChipInput(
              controller: controller,
              tags: tags,
              onChanged: (next) => tags = next,
            ),
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), 'tag1');
    await tester.pump();

    expect(tags, isEmpty);
    expect(find.text('tag1'), findsOneWidget);
    expect(find.byType(InputChip), findsNothing);

    final committed = controller.commitPending();
    await tester.pump();

    expect(committed, ['tag1']);
    expect(tags, ['tag1']);
  });

  testWidgets('commitPending after unmount still returns typed tag', (
    tester,
  ) async {
    final controller = TagChipInputController();
    var tags = <String>[];

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: TagChipInput(
              controller: controller,
              tags: tags,
              onChanged: (next) => tags = next,
            ),
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), 'kept');
    await tester.pump();

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: Scaffold(body: SizedBox.shrink())),
      ),
    );
    await tester.pump();

    expect(controller.commitPending(notify: false), ['kept']);
  });

  test('tag service persists names used by filters', () async {
    final tags = container.read(tagServiceProvider);
    final created = await tags.ensureTag('tag1');
    expect(created.isSuccess, isTrue);
    final found = await tags.findByName('TAG1');
    expect(found?.name, 'tag1');
    final listed = await tags.listAll();
    expect(listed.map((t) => t.name), contains('tag1'));
  });
}
