import 'package:ayutam/core/id/id_generator.dart';
import 'package:ayutam/core/time/clock_service.dart';
import 'package:ayutam/database/app_database.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late FakeClockService clock;
  late UuidIdGenerator ids;

  setUp(() async {
    clock = FakeClockService(initialUtc: DateTime.utc(2026, 7, 22, 12));
    ids = const UuidIdGenerator();
    db = AppDatabase.memory(clock: clock, ids: ids);
    await db.ensureSeeded(clock: clock, ids: ids);
  });

  tearDown(() async {
    await db.close();
  });

  test('opens schema and seeds a stable device identity', () async {
    final deviceId = await db.requireDeviceId();
    expect(deviceId, isNotEmpty);

    final again = await db.requireDeviceId();
    expect(again, deviceId);

    final runtime = await db.select(db.timerRuntime).getSingle();
    expect(runtime.singletonId, 1);
    expect(runtime.machineState, 'idle');
  });

  test('re-seeding is idempotent for device_id', () async {
    final first = await db.requireDeviceId();
    await db.ensureSeeded(clock: clock, ids: ids);
    final second = await db.requireDeviceId();
    expect(second, first);
  });
}
