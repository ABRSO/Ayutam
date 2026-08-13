import 'package:ayutam/core/id/id_generator.dart';
import 'package:ayutam/core/time/clock_service.dart';
import 'package:ayutam/database/app_database.dart';
import 'package:ayutam/features/settings/application/settings_service.dart';
import 'package:ayutam/features/settings/data/drift_settings_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reduced motion defaults off and persists', () async {
    final clock = FakeClockService();
    const ids = UuidIdGenerator();
    final db = AppDatabase.memory(clock: clock, ids: ids);
    await db.ensureSeeded(clock: clock, ids: ids);
    final service = SettingsService(
      settings: DriftSettingsRepository(db),
      clock: clock,
      deviceId: () async => 'device',
    );

    expect(await service.reducedMotion(), isFalse);
    await service.setReducedMotion(true);
    expect(await service.reducedMotion(), isTrue);
    expect(await service.watchReducedMotion().first, isTrue);

    await db.close();
  });
}
