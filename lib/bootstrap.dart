import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/providers.dart';
import 'core/id/id_generator.dart';
import 'core/time/clock_service.dart';
import 'database/app_database.dart';

/// Opens the database and returns a [ProviderContainer] ready for the app.
Future<ProviderContainer> bootstrap({
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
      idGeneratorProvider.overrideWithValue(idGenerator),
      appDatabaseProvider.overrideWithValue(db),
    ],
  );
}
