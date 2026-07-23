import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';

import '../core/constants/app_constants.dart';
import '../core/id/id_generator.dart';
import '../core/time/clock_service.dart';
import 'tables/tables.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Skills,
    Sessions,
    SessionSegments,
    TimerRuntime,
    Tags,
    SessionTags,
    AppSettings,
    BackupHistory,
    LocalSnapshots,
    DeviceIdentity,
    SchemaMetadata,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  /// Opens the on-device database under the application support directory.
  static Future<AppDatabase> open({
    required ClockService clock,
    required IdGenerator ids,
  }) async {
    final db = AppDatabase(
      LazyDatabase(() async {
        final dir = await getApplicationSupportDirectory();
        final file = File(p.join(dir.path, 'ayutam.sqlite'));
        if (Platform.isAndroid) {
          await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
        }
        final cachebase = (await getTemporaryDirectory()).path;
        sqlite3.tempDirectory = cachebase;
        return NativeDatabase.createInBackground(file);
      }),
    );
    await db.ensureSeeded(clock: clock, ids: ids);
    return db;
  }

  /// In-memory database for tests.
  factory AppDatabase.memory({
    required ClockService clock,
    required IdGenerator ids,
  }) {
    final db = AppDatabase(NativeDatabase.memory());
    // Seed synchronously after open via ensureSeeded in callers.
    return db;
  }

  @override
  int get schemaVersion => AppConstants.schemaVersion;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
      await customStatement('PRAGMA foreign_keys = ON');
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_skills_status_sort '
        'ON skills (status, sort_order)',
      );
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_sessions_skill_status_start '
        'ON sessions (skill_id, status, start_at_utc DESC)',
      );
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_sessions_status_start '
        'ON sessions (status, start_at_utc DESC)',
      );
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_sessions_updated '
        'ON sessions (updated_at_utc)',
      );
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_segments_session_start '
        'ON session_segments (session_id, start_at_utc)',
      );
      await customStatement(
        'CREATE UNIQUE INDEX IF NOT EXISTS idx_tags_normalized '
        'ON tags (normalized_name)',
      );
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  /// Ensures device identity and idle timer_runtime row exist.
  Future<void> ensureSeeded({
    required ClockService clock,
    required IdGenerator ids,
  }) async {
    final nowMs = clock.nowUtc().millisecondsSinceEpoch;

    final devices = await select(deviceIdentity).get();
    if (devices.isEmpty) {
      await into(deviceIdentity).insert(
        DeviceIdentityCompanion.insert(deviceId: ids.v4(), createdAtUtc: nowMs),
      );
    }

    final runtime = await (select(
      timerRuntime,
    )..where((t) => t.singletonId.equals(1))).getSingleOrNull();
    if (runtime == null) {
      await into(timerRuntime).insert(
        TimerRuntimeCompanion.insert(
          singletonId: const Value(1),
          machineState: const Value('idle'),
          updatedAtUtc: nowMs,
        ),
      );
    }

    final meta = await (select(
      schemaMetadata,
    )..where((t) => t.key.equals('data_format_version'))).getSingleOrNull();
    if (meta == null) {
      await into(schemaMetadata).insert(
        SchemaMetadataCompanion.insert(key: 'data_format_version', value: '1'),
      );
    }
  }

  Future<String> requireDeviceId() async {
    final row = await select(deviceIdentity).getSingle();
    return row.deviceId;
  }
}
