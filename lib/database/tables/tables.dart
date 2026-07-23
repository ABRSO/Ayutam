import 'package:drift/drift.dart';

/// Skills tracked by the user.
class Skills extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get descriptionMarkdown => text().nullable()();
  IntColumn get targetSeconds =>
      integer().withDefault(const Constant(36000000))();
  TextColumn get createdLocalDate => text()();
  IntColumn get accentArgb => integer().nullable()();
  TextColumn get status => text().withDefault(const Constant('active'))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  IntColumn get createdAtUtc => integer()();
  IntColumn get updatedAtUtc => integer()();
  TextColumn get sourceDeviceId => text()();
  IntColumn get deletedAtUtc => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Practice sessions (completed, active, paused, or completion_pending).
class Sessions extends Table {
  TextColumn get id => text()();
  TextColumn get skillId => text().references(Skills, #id)();
  TextColumn get title => text().nullable()();
  TextColumn get noteMarkdown => text().nullable()();
  TextColumn get mode => text().withDefault(const Constant('stopwatch'))();
  TextColumn get status => text()();
  TextColumn get source => text().withDefault(const Constant('timer'))();
  IntColumn get startAtUtc => integer()();
  IntColumn get endAtUtc => integer().nullable()();
  IntColumn get activeSeconds => integer().withDefault(const Constant(0))();
  IntColumn get pausedSeconds => integer().withDefault(const Constant(0))();
  TextColumn get timezoneIdAtCreation => text()();
  IntColumn get offsetMinutesAtStart => integer()();
  IntColumn get createdAtUtc => integer()();
  IntColumn get updatedAtUtc => integer()();
  TextColumn get sourceDeviceId => text()();
  IntColumn get deletedAtUtc => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Work / pause / pomodoro_break intervals for a session.
class SessionSegments extends Table {
  TextColumn get id => text()();
  TextColumn get sessionId =>
      text().references(Sessions, #id, onDelete: KeyAction.cascade)();
  TextColumn get segmentType => text()();
  TextColumn get pomodoroPhase => text().nullable()();
  IntColumn get cycleNumber => integer().nullable()();
  IntColumn get startAtUtc => integer()();
  IntColumn get endAtUtc => integer().nullable()();
  IntColumn get durationSeconds => integer().withDefault(const Constant(0))();
  IntColumn get createdAtUtc => integer()();
  IntColumn get updatedAtUtc => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Singleton operational timer state (`singleton_id` always 1).
class TimerRuntime extends Table {
  IntColumn get singletonId => integer()();
  TextColumn get sessionId => text().nullable().references(Sessions, #id)();
  TextColumn get machineState => text().withDefault(const Constant('idle'))();
  TextColumn get currentSegmentId => text().nullable()();
  IntColumn get phasePlannedSeconds => integer().nullable()();
  IntColumn get phaseStartedAtUtc => integer().nullable()();
  IntColumn get phaseAccumulatedSeconds =>
      integer().withDefault(const Constant(0))();
  IntColumn get currentCycle => integer().withDefault(const Constant(1))();
  IntColumn get monotonicAnchorMicros => integer().nullable()();
  IntColumn get wallClockAnchorUtc => integer().nullable()();
  IntColumn get lastHeartbeatUtc => integer().nullable()();
  IntColumn get lastCheckpointAtUtc => integer().nullable()();
  TextColumn get recoveryReason => text().nullable()();
  IntColumn get updatedAtUtc => integer()();

  @override
  Set<Column<Object>> get primaryKey => {singletonId};
}

class Tags extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get normalizedName => text()();
  IntColumn get createdAtUtc => integer()();
  IntColumn get updatedAtUtc => integer()();
  TextColumn get sourceDeviceId => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('SessionTag')
class SessionTags extends Table {
  TextColumn get sessionId =>
      text().references(Sessions, #id, onDelete: KeyAction.cascade)();
  TextColumn get tagId =>
      text().references(Tags, #id, onDelete: KeyAction.cascade)();

  @override
  Set<Column<Object>> get primaryKey => {sessionId, tagId};
}

class AppSettings extends Table {
  TextColumn get key => text()();
  TextColumn get valueJson => text()();
  IntColumn get updatedAtUtc => integer()();
  TextColumn get sourceDeviceId => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

class BackupHistory extends Table {
  TextColumn get id => text()();
  TextColumn get backupType => text()();
  TextColumn get destinationDisplay => text().nullable()();
  IntColumn get createdAtUtc => integer()();
  IntColumn get verifiedAtUtc => integer().nullable()();
  IntColumn get sessionHighWatermarkUtc => integer().nullable()();
  IntColumn get skillsCount => integer().withDefault(const Constant(0))();
  IntColumn get sessionsCount => integer().withDefault(const Constant(0))();
  IntColumn get totalActiveSeconds =>
      integer().withDefault(const Constant(0))();
  TextColumn get fileSha256 => text().nullable()();
  TextColumn get status => text()();
  TextColumn get errorCode => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class LocalSnapshots extends Table {
  TextColumn get id => text()();
  TextColumn get filePath => text()();
  TextColumn get reason => text()();
  IntColumn get createdAtUtc => integer()();
  IntColumn get schemaVersion => integer()();
  TextColumn get fileSha256 => text()();
  IntColumn get sizeBytes => integer()();
  IntColumn get isValid => integer().withDefault(const Constant(1))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Random local device identity (no hardware identifiers).
class DeviceIdentity extends Table {
  TextColumn get deviceId => text()();
  IntColumn get createdAtUtc => integer()();
  TextColumn get displayName => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {deviceId};
}

class SchemaMetadata extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}
