import 'dart:io';

import 'package:ayutam/core/constants/app_constants.dart';
import 'package:ayutam/core/id/id_generator.dart';
import 'package:ayutam/core/time/clock_service.dart';
import 'package:ayutam/database/app_database.dart';
import 'package:ayutam/features/learning_log/data/session_search_indexer.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';

/// Builds a v1-on-disk schema (no FTS), inserts a completed session, then
/// opens with schema v2 and asserts migration backfills `session_search`.
void main() {
  late Directory tempDir;
  late FakeClockService clock;
  late UuidIdGenerator ids;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('ayutam_mig_');
    clock = FakeClockService(initialUtc: DateTime.utc(2026, 8, 1, 12));
    ids = const UuidIdGenerator();
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  test('schema 1→2 creates FTS and backfills searchable rows', () async {
    final dbPath = p.join(tempDir.path, 'v1.sqlite');
    final skillId = ids.v4();
    final sessionId = ids.v4();
    final deviceId = ids.v4();
    final now = clock.nowUtc().millisecondsSinceEpoch;

    // Create v1 database without going through AppDatabase schemaVersion 2.
    final raw = sqlite3.open(dbPath);
    raw.execute('PRAGMA foreign_keys = ON');
    raw.execute('''
CREATE TABLE skills (
  id TEXT NOT NULL PRIMARY KEY,
  name TEXT NOT NULL,
  description_markdown TEXT NULL,
  target_seconds INTEGER NOT NULL DEFAULT 36000000,
  created_local_date TEXT NOT NULL,
  accent_argb INTEGER NULL,
  status TEXT NOT NULL DEFAULT 'active',
  sort_order INTEGER NOT NULL DEFAULT 0,
  created_at_utc INTEGER NOT NULL,
  updated_at_utc INTEGER NOT NULL,
  source_device_id TEXT NOT NULL,
  deleted_at_utc INTEGER NULL
);
''');
    raw.execute('''
CREATE TABLE sessions (
  id TEXT NOT NULL PRIMARY KEY,
  skill_id TEXT NOT NULL REFERENCES skills (id),
  title TEXT NULL,
  note_markdown TEXT NULL,
  mode TEXT NOT NULL DEFAULT 'stopwatch',
  status TEXT NOT NULL,
  source TEXT NOT NULL DEFAULT 'timer',
  start_at_utc INTEGER NOT NULL,
  end_at_utc INTEGER NULL,
  active_seconds INTEGER NOT NULL DEFAULT 0,
  paused_seconds INTEGER NOT NULL DEFAULT 0,
  timezone_id_at_creation TEXT NOT NULL,
  offset_minutes_at_start INTEGER NOT NULL,
  created_at_utc INTEGER NOT NULL,
  updated_at_utc INTEGER NOT NULL,
  source_device_id TEXT NOT NULL,
  deleted_at_utc INTEGER NULL
);
''');
    raw.execute('''
CREATE TABLE session_segments (
  id TEXT NOT NULL PRIMARY KEY,
  session_id TEXT NOT NULL REFERENCES sessions (id) ON DELETE CASCADE,
  segment_type TEXT NOT NULL,
  pomodoro_phase TEXT NULL,
  cycle_number INTEGER NULL,
  start_at_utc INTEGER NOT NULL,
  end_at_utc INTEGER NULL,
  duration_seconds INTEGER NOT NULL DEFAULT 0,
  created_at_utc INTEGER NOT NULL,
  updated_at_utc INTEGER NOT NULL
);
''');
    raw.execute('''
CREATE TABLE timer_runtime (
  singleton_id INTEGER NOT NULL PRIMARY KEY,
  session_id TEXT NULL REFERENCES sessions (id),
  machine_state TEXT NOT NULL DEFAULT 'idle',
  current_segment_id TEXT NULL,
  phase_planned_seconds INTEGER NULL,
  phase_started_at_utc INTEGER NULL,
  phase_accumulated_seconds INTEGER NOT NULL DEFAULT 0,
  current_cycle INTEGER NOT NULL DEFAULT 1,
  monotonic_anchor_micros INTEGER NULL,
  wall_clock_anchor_utc INTEGER NULL,
  last_heartbeat_utc INTEGER NULL,
  last_checkpoint_at_utc INTEGER NULL,
  recovery_reason TEXT NULL,
  updated_at_utc INTEGER NOT NULL
);
''');
    raw.execute('''
CREATE TABLE tags (
  id TEXT NOT NULL PRIMARY KEY,
  name TEXT NOT NULL,
  normalized_name TEXT NOT NULL,
  created_at_utc INTEGER NOT NULL,
  updated_at_utc INTEGER NOT NULL,
  source_device_id TEXT NOT NULL
);
''');
    raw.execute('''
CREATE TABLE session_tags (
  session_id TEXT NOT NULL REFERENCES sessions (id) ON DELETE CASCADE,
  tag_id TEXT NOT NULL REFERENCES tags (id) ON DELETE CASCADE,
  PRIMARY KEY (session_id, tag_id)
);
''');
    raw.execute('''
CREATE TABLE app_settings (
  key TEXT NOT NULL PRIMARY KEY,
  value_json TEXT NOT NULL,
  updated_at_utc INTEGER NOT NULL,
  source_device_id TEXT NOT NULL
);
''');
    raw.execute('''
CREATE TABLE backup_history (
  id TEXT NOT NULL PRIMARY KEY,
  backup_type TEXT NOT NULL,
  destination_display TEXT NULL,
  created_at_utc INTEGER NOT NULL,
  verified_at_utc INTEGER NULL,
  session_high_watermark_utc INTEGER NULL,
  skills_count INTEGER NOT NULL DEFAULT 0,
  sessions_count INTEGER NOT NULL DEFAULT 0,
  total_active_seconds INTEGER NOT NULL DEFAULT 0,
  file_sha256 TEXT NULL,
  status TEXT NOT NULL,
  error_code TEXT NULL
);
''');
    raw.execute('''
CREATE TABLE local_snapshots (
  id TEXT NOT NULL PRIMARY KEY,
  file_path TEXT NOT NULL,
  reason TEXT NOT NULL,
  created_at_utc INTEGER NOT NULL,
  schema_version INTEGER NOT NULL,
  file_sha256 TEXT NOT NULL,
  size_bytes INTEGER NOT NULL,
  is_valid INTEGER NOT NULL DEFAULT 1
);
''');
    raw.execute('''
CREATE TABLE device_identity (
  device_id TEXT NOT NULL PRIMARY KEY,
  created_at_utc INTEGER NOT NULL,
  display_name TEXT NULL
);
''');
    raw.execute('''
CREATE TABLE schema_metadata (
  key TEXT NOT NULL PRIMARY KEY,
  value TEXT NOT NULL
);
''');
    // Drift user_version = 1
    raw.execute('PRAGMA user_version = 1');

    raw.execute(
      'INSERT INTO device_identity (device_id, created_at_utc) VALUES (?, ?)',
      [deviceId, now],
    );
    raw.execute(
      'INSERT INTO timer_runtime (singleton_id, machine_state, updated_at_utc) '
      "VALUES (1, 'idle', ?)",
      [now],
    );
    raw.execute(
      'INSERT INTO skills (id, name, target_seconds, created_local_date, '
      'status, sort_order, created_at_utc, updated_at_utc, source_device_id) '
      "VALUES (?, 'Piano', 36000000, '2026-08-01', 'active', 0, ?, ?, ?)",
      [skillId, now, now, deviceId],
    );
    raw.execute(
      'INSERT INTO sessions (id, skill_id, title, note_markdown, mode, status, '
      'source, start_at_utc, end_at_utc, active_seconds, paused_seconds, '
      'timezone_id_at_creation, offset_minutes_at_start, created_at_utc, '
      'updated_at_utc, source_device_id) VALUES '
      "(?, ?, 'Scales', 'Practiced **chromatic** scales', 'stopwatch', "
      "'completed', 'timer', ?, ?, 600, 0, 'UTC', 0, ?, ?, ?)",
      [sessionId, skillId, now - 600000, now, now, now, deviceId],
    );
    raw.close();

    expect(AppConstants.schemaVersion, 2);

    final db = AppDatabase(NativeDatabase(File(dbPath)));
    // Opening triggers migration 1→2.
    await db.customSelect('SELECT 1').get();

    final indexer = SessionSearchIndexer(db);
    final idsFound = await indexer.searchSessionIds('chromatic');
    expect(idsFound, contains(sessionId));

    final byTitle = await indexer.searchSessionIds('Scales');
    expect(byTitle, contains(sessionId));

    final bySkill = await indexer.searchSessionIds('Piano');
    expect(bySkill, contains(sessionId));

    await db.close();
  });

  test('fresh schema v2 creates session_search on create', () async {
    final db = AppDatabase.memory(clock: clock, ids: ids);
    await db.ensureSeeded(clock: clock, ids: ids);

    final rows = await db
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type='table' "
          "AND name='session_search'",
        )
        .get();
    expect(rows, isNotEmpty);

    await db.close();
  });
}
