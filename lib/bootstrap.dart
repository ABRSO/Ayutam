import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/providers.dart';
import 'core/id/id_generator.dart';
import 'core/time/clock_service.dart';
import 'core/time/timezone_service.dart';
import 'database/app_database.dart';

/// Opens the database and returns a [ProviderContainer] ready for the app.
///
/// [timezones] must be provided by the caller so tests can inject a fake
/// without loading native timezone plugins.
Future<ProviderContainer> bootstrap({
  required TimezoneService timezones,
  ClockService? clock,
  IdGenerator? ids,
  AppDatabase? database,
}) async {
  final clockService = clock ?? SystemClockService();
  final idGenerator = ids ?? const UuidIdGenerator();
  final db =
      database ?? await AppDatabase.open(clock: clockService, ids: idGenerator);
  if (database != null) {
    await db.ensureSeeded(clock: clockService, ids: idGenerator);
  }

  return ProviderContainer(
    overrides: [
      clockServiceProvider.overrideWithValue(clockService),
      timezoneServiceProvider.overrideWithValue(timezones),
      idGeneratorProvider.overrideWithValue(idGenerator),
      appDatabaseProvider.overrideWithValue(db),
    ],
  );
}
