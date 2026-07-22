import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/id/id_generator.dart';
import '../core/logging/app_logger.dart';
import '../core/time/clock_service.dart';
import '../database/app_database.dart';

final clockServiceProvider = Provider<ClockService>((ref) {
  return SystemClockService();
});

final idGeneratorProvider = Provider<IdGenerator>((ref) {
  return const UuidIdGenerator();
});

final appLoggerProvider = Provider<AppLogger>((ref) {
  return const ConsoleAppLogger();
});

/// Opened during [bootstrap]. Override in tests with an in-memory DB.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  throw StateError(
    'appDatabaseProvider was read before bootstrap completed. '
    'Override this provider after AppDatabase.open.',
  );
});

final deviceIdProvider = FutureProvider<String>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  return db.requireDeviceId();
});
