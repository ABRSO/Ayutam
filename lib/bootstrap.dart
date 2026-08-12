import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/providers.dart';
import 'core/id/id_generator.dart';
import 'core/time/clock_service.dart';
import 'core/time/timezone_service.dart';
import 'database/app_database.dart';
import 'platform/device_timezone.dart';

/// Opens the database and returns a [ProviderContainer] ready for the app.
Future<ProviderContainer> bootstrap({
  ClockService? clock,
  IdGenerator? ids,
  AppDatabase? database,
  TimezoneService? timezones,
}) async {
  final clockService = clock ?? SystemClockService();
  final idGenerator = ids ?? const UuidIdGenerator();
  final db =
      database ?? await AppDatabase.open(clock: clockService, ids: idGenerator);
  if (database != null) {
    await db.ensureSeeded(clock: clockService, ids: idGenerator);
  }

  final timezoneService =
      timezones ?? IanaTimezoneService(ianaId: await resolveDeviceIanaId());

  return ProviderContainer(
    overrides: [
      clockServiceProvider.overrideWithValue(clockService),
      timezoneServiceProvider.overrideWithValue(timezoneService),
      idGeneratorProvider.overrideWithValue(idGenerator),
      appDatabaseProvider.overrideWithValue(db),
    ],
  );
}
