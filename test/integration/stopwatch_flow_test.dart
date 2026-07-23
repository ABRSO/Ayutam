import 'package:ayutam/bootstrap.dart';
import 'package:ayutam/core/id/id_generator.dart';
import 'package:ayutam/core/time/clock_service.dart';
import 'package:ayutam/database/app_database.dart';
import 'package:ayutam/app/providers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('integration: create → start → pause → resume → stop → save', () async {
    final clock = FakeClockService(initialUtc: DateTime.utc(2026, 7, 23, 10));
    const ids = UuidIdGenerator();
    final db = AppDatabase.memory(clock: clock, ids: ids);
    final container = await bootstrap(clock: clock, ids: ids, database: db);

    final skillService = container.read(skillServiceProvider);
    final timer = container.read(stopwatchTimerServiceProvider);

    final created = await skillService.create(name: 'Chess');
    expect(created.isSuccess, isTrue);
    final skillId = created.valueOrNull!.id;

    expect((await timer.startStopwatch(skillId)).isSuccess, isTrue);
    clock.advance(const Duration(minutes: 4));
    expect((await timer.pause()).isSuccess, isTrue);
    clock.advance(const Duration(minutes: 1));
    expect((await timer.resume()).isSuccess, isTrue);
    clock.advance(const Duration(minutes: 6));
    expect((await timer.stop()).isSuccess, isTrue);
    expect((await timer.saveCompletion()).isSuccess, isTrue);

    final skills = await skillService.listActive();
    expect(skills.single.completedActiveSeconds, 10 * 60);

    await db.close();
    container.dispose();
  });
}
