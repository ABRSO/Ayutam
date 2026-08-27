import 'dart:io';

import 'package:drift/drift.dart';

import 'package:drift/native.dart';

import '../../../database/app_database.dart';
import '../../learning_log/data/session_search_indexer.dart';
import '../domain/backup_models.dart';
import '../domain/backup_store.dart';

/// Drift-backed [BackupStore] for portable export / replace / merge writes.
final class DriftBackupStore implements BackupStore {
  DriftBackupStore(this._db, {this.databasePath});

  final AppDatabase _db;

  /// Absolute path of the live SQLite file when known; null for in-memory DBs.
  final String? databasePath;

  static const _inProgressStatuses = ['active', 'paused', 'completion_pending'];

  @override
  Future<BackupPayload> readPayload() async {
    final skillRows = await _db.select(_db.skills).get();
    final sessionRows = await _db.select(_db.sessions).get();
    final segmentRows = await _db.select(_db.sessionSegments).get();
    final tagRows = await _db.select(_db.tags).get();
    final sessionTagRows = await _db.select(_db.sessionTags).get();
    final settingRows = await _db.select(_db.appSettings).get();
    final deviceRows = await _db.select(_db.deviceIdentity).get();
    final runtimeRow = await (_db.select(
      _db.timerRuntime,
    )..where((t) => t.singletonId.equals(1))).getSingleOrNull();

    final lastVerified = await _latestSuccessfulVerifiedAtMs();
    final lastSuccessfulBackupAtUtc = lastVerified == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(
            lastVerified,
            isUtc: true,
          ).toIso8601String();

    return BackupPayload(
      dataVersion: skilltrackerDataVersion,
      exportedAtUtc: DateTime.now().toUtc().toIso8601String(),
      skills: skillRows.map(_skillRecord).toList(),
      sessions: sessionRows.map(_sessionRecord).toList(),
      sessionSegments: segmentRows.map(_segmentRecord).toList(),
      tags: tagRows.map(_tagRecord).toList(),
      sessionTags: sessionTagRows.map(_sessionTagRecord).toList(),
      settings: settingRows.map(_settingRecord).toList(),
      deviceMetadata: deviceRows.map(_deviceRecord).toList(),
      timerRuntime: runtimeRow == null ? null : _timerRuntimeRecord(runtimeRow),
      backupMetadata: BackupMetadataRecord(
        lastSuccessfulBackupAtUtc: lastSuccessfulBackupAtUtc,
      ),
    );
  }

  @override
  Future<void> applyReplace(BackupPayload payload) => _applyPayload(payload);

  @override
  Future<void> applyMerged(BackupPayload payload) => _applyPayload(payload);

  Future<void> _applyPayload(BackupPayload payload) async {
    await _db.transaction(() async {
      // Drop FK from timer_runtime before wiping sessions.
      await (_db.update(
        _db.timerRuntime,
      )..where((t) => t.singletonId.equals(1))).write(
        const TimerRuntimeCompanion(
          sessionId: Value(null),
          machineState: Value('idle'),
          currentSegmentId: Value(null),
          phasePlannedSeconds: Value(null),
          phaseStartedAtUtc: Value(null),
          phaseAccumulatedSeconds: Value(0),
          currentCycle: Value(1),
          monotonicAnchorMicros: Value(null),
          wallClockAnchorUtc: Value(null),
          lastHeartbeatUtc: Value(null),
          lastCheckpointAtUtc: Value(null),
          recoveryReason: Value(null),
        ),
      );

      await _db.delete(_db.sessionTags).go();
      await _db.delete(_db.sessionSegments).go();
      await _db.delete(_db.sessions).go();
      await _db.delete(_db.tags).go();
      await _db.delete(_db.skills).go();

      // Portable settings only; never touch device-local / non-mergeable keys.
      final mergeableKeys = mergeableSettingsKeys.toList();
      if (mergeableKeys.isNotEmpty) {
        await (_db.delete(
          _db.appSettings,
        )..where((t) => t.key.isIn(mergeableKeys))).go();
      }

      // Local device_identity is never replaced from payload deviceMetadata.

      await _db.batch((batch) {
        batch.insertAll(
          _db.skills,
          payload.skills.map(_skillCompanion).toList(),
        );
        batch.insertAll(_db.tags, payload.tags.map(_tagCompanion).toList());
        batch.insertAll(
          _db.sessions,
          payload.sessions.map(_sessionCompanion).toList(),
        );
        batch.insertAll(
          _db.sessionSegments,
          payload.sessionSegments.map(_segmentCompanion).toList(),
        );
        batch.insertAll(
          _db.sessionTags,
          payload.sessionTags.map(_sessionTagCompanion).toList(),
        );
        for (final setting in payload.settings) {
          if (!mergeableSettingsKeys.contains(setting.key)) continue;
          batch.insert(
            _db.appSettings,
            _settingCompanion(setting),
            onConflict: DoUpdate((_) => _settingCompanion(setting)),
          );
        }
      });

      await _rebuildTimerRuntimeFromSessions();
    });

    await SessionSearchIndexer(_db).rebuildAll();
  }

  Future<void> _rebuildTimerRuntimeFromSessions() async {
    final inProgress =
        await (_db.select(_db.sessions)..where(
              (t) =>
                  t.status.isIn(_inProgressStatuses) & t.deletedAtUtc.isNull(),
            ))
            .get();

    final nowMs = DateTime.now().toUtc().millisecondsSinceEpoch;

    if (inProgress.length != 1) {
      await _db
          .into(_db.timerRuntime)
          .insertOnConflictUpdate(
            TimerRuntimeCompanion.insert(
              singletonId: const Value(1),
              sessionId: const Value(null),
              machineState: const Value('idle'),
              currentSegmentId: const Value(null),
              phasePlannedSeconds: const Value(null),
              phaseStartedAtUtc: const Value(null),
              phaseAccumulatedSeconds: const Value(0),
              currentCycle: const Value(1),
              monotonicAnchorMicros: const Value(null),
              wallClockAnchorUtc: const Value(null),
              lastHeartbeatUtc: const Value(null),
              lastCheckpointAtUtc: const Value(null),
              recoveryReason: const Value(null),
              updatedAtUtc: nowMs,
            ),
          );
      return;
    }

    final session = inProgress.single;
    await _db
        .into(_db.timerRuntime)
        .insertOnConflictUpdate(
          TimerRuntimeCompanion.insert(
            singletonId: const Value(1),
            sessionId: Value(session.id),
            machineState: Value(_machineStateFromSessionStatus(session.status)),
            currentSegmentId: const Value(null),
            phasePlannedSeconds: const Value(null),
            phaseStartedAtUtc: const Value(null),
            phaseAccumulatedSeconds: const Value(0),
            currentCycle: const Value(1),
            monotonicAnchorMicros: const Value(null),
            wallClockAnchorUtc: const Value(null),
            lastHeartbeatUtc: const Value(null),
            lastCheckpointAtUtc: const Value(null),
            recoveryReason: const Value('imported'),
            updatedAtUtc: nowMs,
          ),
        );
  }

  static String _machineStateFromSessionStatus(String status) =>
      switch (status) {
        'active' => 'running',
        'paused' => 'paused',
        'completion_pending' => 'completion_pending',
        _ => 'idle',
      };

  @override
  Future<bool> hasActiveOrPendingSession() async {
    final row =
        await (_db.select(_db.sessions)
              ..where(
                (t) =>
                    t.status.isIn(_inProgressStatuses) &
                    t.deletedAtUtc.isNull(),
              )
              ..limit(1))
            .getSingleOrNull();
    return row != null;
  }

  @override
  Future<DateTime?> lastSuccessfulBackupAt() async {
    final ms = await _latestSuccessfulVerifiedAtMs();
    if (ms == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
  }

  Future<int?> _latestSuccessfulVerifiedAtMs() async {
    final row =
        await (_db.select(_db.backupHistory)
              ..where(
                (t) => t.status.equals('success') & t.verifiedAtUtc.isNotNull(),
              )
              ..orderBy([(t) => OrderingTerm.desc(t.verifiedAtUtc)])
              ..limit(1))
            .getSingleOrNull();
    return row?.verifiedAtUtc;
  }

  @override
  Future<int> sessionsChangedSince(DateTime? watermark) async {
    final query = _db.selectOnly(_db.sessions)
      ..addColumns([_db.sessions.id.count()])
      ..where(_db.sessions.deletedAtUtc.isNull());
    if (watermark != null) {
      query.where(
        _db.sessions.updatedAtUtc.isBiggerThanValue(
          watermark.toUtc().millisecondsSinceEpoch,
        ),
      );
    }
    final row = await query.getSingle();
    return row.read(_db.sessions.id.count()) ?? 0;
  }

  @override
  Future<void> recordBackupAttempt({
    required String id,
    required String backupType,
    required String status,
    required DateTime createdAtUtc,
    String? destinationDisplay,
    DateTime? verifiedAtUtc,
    DateTime? sessionHighWatermarkUtc,
    int skillsCount = 0,
    int sessionsCount = 0,
    int totalActiveSeconds = 0,
    String? fileSha256,
    String? errorCode,
  }) async {
    await _db
        .into(_db.backupHistory)
        .insert(
          BackupHistoryCompanion.insert(
            id: id,
            backupType: backupType,
            destinationDisplay: Value(destinationDisplay),
            createdAtUtc: createdAtUtc.toUtc().millisecondsSinceEpoch,
            verifiedAtUtc: Value(verifiedAtUtc?.toUtc().millisecondsSinceEpoch),
            sessionHighWatermarkUtc: Value(
              sessionHighWatermarkUtc?.toUtc().millisecondsSinceEpoch,
            ),
            skillsCount: Value(skillsCount),
            sessionsCount: Value(sessionsCount),
            totalActiveSeconds: Value(totalActiveSeconds),
            fileSha256: Value(fileSha256),
            status: status,
            errorCode: Value(errorCode),
          ),
        );
  }

  @override
  Future<List<LocalSnapshotInfo>> listSnapshots() async {
    final rows = await (_db.select(
      _db.localSnapshots,
    )..orderBy([(t) => OrderingTerm.desc(t.createdAtUtc)])).get();
    return rows.map(_snapshotInfo).toList();
  }

  @override
  Future<LocalSnapshotInfo> createSnapshot({
    required String id,
    required String reason,
    required String filePath,
    required String fileSha256,
    required int sizeBytes,
    required int schemaVersion,
    required DateTime createdAtUtc,
  }) async {
    await _db
        .into(_db.localSnapshots)
        .insert(
          LocalSnapshotsCompanion.insert(
            id: id,
            filePath: filePath,
            reason: reason,
            createdAtUtc: createdAtUtc.toUtc().millisecondsSinceEpoch,
            schemaVersion: schemaVersion,
            fileSha256: fileSha256,
            sizeBytes: sizeBytes,
            isValid: const Value(1),
          ),
        );
    return LocalSnapshotInfo(
      id: id,
      filePath: filePath,
      reason: reason,
      createdAtUtc: createdAtUtc.toUtc(),
      schemaVersion: schemaVersion,
      fileSha256: fileSha256,
      sizeBytes: sizeBytes,
      isValid: true,
    );
  }

  @override
  Future<void> markSnapshotInvalid(String id) async {
    await (_db.update(_db.localSnapshots)..where((t) => t.id.equals(id))).write(
      const LocalSnapshotsCompanion(isValid: Value(0)),
    );
  }

  @override
  Future<void> deleteSnapshotRow(String id) async {
    await (_db.delete(_db.localSnapshots)..where((t) => t.id.equals(id))).go();
  }

  @override
  Future<String?> liveDatabasePath() async => databasePath;

  @override
  Future<void> vacuumInto(String destPath) async {
    final escaped = destPath.replaceAll("'", "''");
    await _db.customStatement("VACUUM INTO '$escaped'");
  }

  @override
  Future<Uint8List> readFileBytes(String path) => File(path).readAsBytes();

  @override
  Future<void> writeFileBytes(String path, Uint8List bytes) async {
    final file = File(path);
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes, flush: true);
  }

  @override
  Future<void> deleteFileIfExists(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  @override
  Future<BackupPayload> readPayloadFromSnapshotFile(String path) async {
    if (path.startsWith('memory://')) {
      throw StateError('In-memory snapshots cannot be restored from disk.');
    }
    final file = File(path);
    if (!await file.exists()) {
      throw StateError('Snapshot file is missing: $path');
    }
    final snapDb = AppDatabase(NativeDatabase(file));
    try {
      final snapStore = DriftBackupStore(snapDb, databasePath: path);
      return snapStore.readPayload();
    } finally {
      await snapDb.close();
    }
  }

  LocalSnapshotInfo _snapshotInfo(LocalSnapshot row) {
    return LocalSnapshotInfo(
      id: row.id,
      filePath: row.filePath,
      reason: row.reason,
      createdAtUtc: DateTime.fromMillisecondsSinceEpoch(
        row.createdAtUtc,
        isUtc: true,
      ),
      schemaVersion: row.schemaVersion,
      fileSha256: row.fileSha256,
      sizeBytes: row.sizeBytes,
      isValid: row.isValid != 0,
    );
  }

  BackupSkillRecord _skillRecord(SkillRow row) => BackupSkillRecord(
    id: row.id,
    name: row.name,
    descriptionMarkdown: row.descriptionMarkdown,
    targetSeconds: row.targetSeconds,
    createdLocalDate: row.createdLocalDate,
    accentArgb: row.accentArgb,
    status: row.status,
    sortOrder: row.sortOrder,
    createdAtUtc: row.createdAtUtc,
    updatedAtUtc: row.updatedAtUtc,
    sourceDeviceId: row.sourceDeviceId,
    deletedAtUtc: row.deletedAtUtc,
  );

  BackupSessionRecord _sessionRecord(SessionRow row) => BackupSessionRecord(
    id: row.id,
    skillId: row.skillId,
    title: row.title,
    noteMarkdown: row.noteMarkdown,
    mode: row.mode,
    status: row.status,
    source: row.source,
    startAtUtc: row.startAtUtc,
    endAtUtc: row.endAtUtc,
    activeSeconds: row.activeSeconds,
    pausedSeconds: row.pausedSeconds,
    timezoneIdAtCreation: row.timezoneIdAtCreation,
    offsetMinutesAtStart: row.offsetMinutesAtStart,
    createdAtUtc: row.createdAtUtc,
    updatedAtUtc: row.updatedAtUtc,
    sourceDeviceId: row.sourceDeviceId,
    deletedAtUtc: row.deletedAtUtc,
  );

  BackupSegmentRecord _segmentRecord(SessionSegmentRow row) =>
      BackupSegmentRecord(
        id: row.id,
        sessionId: row.sessionId,
        segmentType: row.segmentType,
        pomodoroPhase: row.pomodoroPhase,
        cycleNumber: row.cycleNumber,
        startAtUtc: row.startAtUtc,
        endAtUtc: row.endAtUtc,
        durationSeconds: row.durationSeconds,
        createdAtUtc: row.createdAtUtc,
        updatedAtUtc: row.updatedAtUtc,
      );

  BackupTagRecord _tagRecord(TagRow row) => BackupTagRecord(
    id: row.id,
    name: row.name,
    normalizedName: row.normalizedName,
    createdAtUtc: row.createdAtUtc,
    updatedAtUtc: row.updatedAtUtc,
    sourceDeviceId: row.sourceDeviceId,
  );

  BackupSessionTagRecord _sessionTagRecord(SessionTag row) =>
      BackupSessionTagRecord(sessionId: row.sessionId, tagId: row.tagId);

  BackupSettingRecord _settingRecord(AppSetting row) => BackupSettingRecord(
    key: row.key,
    valueJson: row.valueJson,
    updatedAtUtc: row.updatedAtUtc,
    sourceDeviceId: row.sourceDeviceId,
  );

  BackupDeviceRecord _deviceRecord(DeviceIdentityData row) =>
      BackupDeviceRecord(
        deviceId: row.deviceId,
        createdAtUtc: row.createdAtUtc,
        displayName: row.displayName,
      );

  BackupTimerRuntimeRecord _timerRuntimeRecord(TimerRuntimeData row) =>
      BackupTimerRuntimeRecord(
        singletonId: row.singletonId,
        sessionId: row.sessionId,
        machineState: row.machineState,
        currentSegmentId: row.currentSegmentId,
        phasePlannedSeconds: row.phasePlannedSeconds,
        phaseStartedAtUtc: row.phaseStartedAtUtc,
        phaseAccumulatedSeconds: row.phaseAccumulatedSeconds,
        currentCycle: row.currentCycle,
        monotonicAnchorMicros: row.monotonicAnchorMicros,
        wallClockAnchorUtc: row.wallClockAnchorUtc,
        lastHeartbeatUtc: row.lastHeartbeatUtc,
        lastCheckpointAtUtc: row.lastCheckpointAtUtc,
        recoveryReason: row.recoveryReason,
        updatedAtUtc: row.updatedAtUtc,
      );

  SkillsCompanion _skillCompanion(BackupSkillRecord s) =>
      SkillsCompanion.insert(
        id: s.id,
        name: s.name,
        descriptionMarkdown: Value(s.descriptionMarkdown),
        targetSeconds: Value(s.targetSeconds),
        createdLocalDate: s.createdLocalDate,
        accentArgb: Value(s.accentArgb),
        status: Value(s.status),
        sortOrder: Value(s.sortOrder),
        createdAtUtc: s.createdAtUtc,
        updatedAtUtc: s.updatedAtUtc,
        sourceDeviceId: s.sourceDeviceId,
        deletedAtUtc: Value(s.deletedAtUtc),
      );

  SessionsCompanion _sessionCompanion(BackupSessionRecord s) =>
      SessionsCompanion.insert(
        id: s.id,
        skillId: s.skillId,
        title: Value(s.title),
        noteMarkdown: Value(s.noteMarkdown),
        mode: Value(s.mode),
        status: s.status,
        source: Value(s.source),
        startAtUtc: s.startAtUtc,
        endAtUtc: Value(s.endAtUtc),
        activeSeconds: Value(s.activeSeconds),
        pausedSeconds: Value(s.pausedSeconds),
        timezoneIdAtCreation: s.timezoneIdAtCreation,
        offsetMinutesAtStart: s.offsetMinutesAtStart,
        createdAtUtc: s.createdAtUtc,
        updatedAtUtc: s.updatedAtUtc,
        sourceDeviceId: s.sourceDeviceId,
        deletedAtUtc: Value(s.deletedAtUtc),
      );

  SessionSegmentsCompanion _segmentCompanion(BackupSegmentRecord s) =>
      SessionSegmentsCompanion.insert(
        id: s.id,
        sessionId: s.sessionId,
        segmentType: s.segmentType,
        pomodoroPhase: Value(s.pomodoroPhase),
        cycleNumber: Value(s.cycleNumber),
        startAtUtc: s.startAtUtc,
        endAtUtc: Value(s.endAtUtc),
        durationSeconds: Value(s.durationSeconds),
        createdAtUtc: s.createdAtUtc,
        updatedAtUtc: s.updatedAtUtc,
      );

  TagsCompanion _tagCompanion(BackupTagRecord t) => TagsCompanion.insert(
    id: t.id,
    name: t.name,
    normalizedName: t.normalizedName,
    createdAtUtc: t.createdAtUtc,
    updatedAtUtc: t.updatedAtUtc,
    sourceDeviceId: t.sourceDeviceId,
  );

  SessionTagsCompanion _sessionTagCompanion(BackupSessionTagRecord t) =>
      SessionTagsCompanion.insert(sessionId: t.sessionId, tagId: t.tagId);

  AppSettingsCompanion _settingCompanion(BackupSettingRecord s) =>
      AppSettingsCompanion.insert(
        key: s.key,
        valueJson: s.valueJson,
        updatedAtUtc: s.updatedAtUtc,
        sourceDeviceId: s.sourceDeviceId,
      );
}
