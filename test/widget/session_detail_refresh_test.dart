import 'package:ayutam/app/providers.dart';
import 'package:ayutam/bootstrap.dart';
import 'package:ayutam/core/id/id_generator.dart';
import 'package:ayutam/core/time/clock_service.dart';
import 'package:ayutam/core/time/timezone_service.dart';
import 'package:ayutam/database/app_database.dart';
import 'package:ayutam/features/learning_log/presentation/session_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('mobile detail shows persisted title after list invalidation', (
    tester,
  ) async {
    final clock = FakeClockService(initialUtc: DateTime.utc(2026, 8, 6, 12));
    const ids = UuidIdGenerator();
    final db = AppDatabase.memory(clock: clock, ids: ids);
    final container = await bootstrap(
      clock: clock,
      ids: ids,
      database: db,
      timezones: const FakeTimezoneService(),
    );

    final skill =
        (await container.read(skillServiceProvider).create(name: 'Piano'))
            .valueOrNull!;
    final created = await container
        .read(sessionNoteServiceProvider)
        .createManualSession(
          skillId: skill.id,
          startAtUtc: DateTime.utc(2026, 8, 1, 10),
          endAtUtc: DateTime.utc(2026, 8, 1, 11),
          title: 'Old title',
        );
    final sessionId = created.valueOrNull!.session!.id;
    final stale = (await container
        .read(learningLogServiceProvider)
        .getEntry(sessionId))!;

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: SessionDetailScreen(sessionId: sessionId, entries: [stale]),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Old title'), findsWidgets);

    final updated = await container
        .read(sessionNoteServiceProvider)
        .updateCompletedSession(
          sessionId: sessionId,
          title: 'New title',
          updateTitle: true,
        );
    expect(updated.isSuccess, isTrue);

    container.invalidate(learningLogEntryProvider(sessionId));
    container.invalidate(learningLogListProvider);
    await tester.pumpAndSettle();

    expect(find.text('New title'), findsWidgets);
    expect(find.text('Old title'), findsNothing);

    await db.close();
    container.dispose();
  });
}
