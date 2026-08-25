import 'dart:convert';
import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:meta/meta.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/result/result.dart';
import '../../../core/time/clock_service.dart';
import '../../../core/time/timezone_service.dart';
import '../domain/backup_models.dart';
import '../domain/backup_store.dart';
import 'backup_validator.dart';
import 'merge_engine.dart';
import 'skilltracker_codec.dart';

/// Portable backup export / import / status (ADR-004, ADR-012).
final class BackupService {
  BackupService({
    required BackupStore store,
    required BackupFileIo files,
    required ClockService clock,
    required TimezoneService timezones,
    required Future<String> Function() deviceId,
    required Future<String> Function() applicationVersion,
    required Future<String> Function() snapshotsDirectory,
    required String Function() newId,
    SkilltrackerCodec codec = const SkilltrackerCodec(),
    MergeEngine mergeEngine = const MergeEngine(),
    String platform = 'unknown',
  }) : _store = store,
       _files = files,
       _clock = clock,
       _timezones = timezones,
       _deviceId = deviceId,
       _applicationVersion = applicationVersion,
       _snapshotsDirectory = snapshotsDirectory,
       _newId = newId,
       _codec = codec,
       _mergeEngine = mergeEngine,
       _platform = platform;

  final BackupStore _store;
  final BackupFileIo _files;
  final ClockService _clock;
  final TimezoneService _timezones;
  final Future<String> Function() _deviceId;
  final Future<String> Function() _applicationVersion;
  final Future<String> Function() _snapshotsDirectory;
  final String Function() _newId;
  final SkilltrackerCodec _codec;
  final MergeEngine _mergeEngine;
  final String _platform;

  static final _fileStamp = DateFormat('yyyy-MM-dd-HHmmss');

  Future<BackupStatus> status({
    Duration reminderInterval = const Duration(days: 7),
  }) async {
    final last = await _store.lastSuccessfulBackupAt();
    final changed = await _store.sessionsChangedSince(last);
    final never = last == null;
    final due = never || _clock.nowUtc().difference(last) >= reminderInterval;
    return BackupStatus(
      lastSuccessfulBackupAtUtc: last,
      sessionsChangedSinceBackup: changed,
      reminderEnabled: true,
      due: due,
      neverBackedUp: never,
    );
  }

  /// Export verified `.skilltracker`. Marks history successful only after verify.
  Future<Result<String>> exportSkilltracker() async {
    final attemptId = _newId();
    final now = _clock.nowUtc();
    try {
      final payload = await _store.readPayload();
      final summary = payload.computeSummary();
      final payloadBytes = encodePayloadBytes(payload);
      final device = await _deviceId();
      final appVersion = await _applicationVersion();
      final manifest = BackupManifest(
        format: skilltrackerFormat,
        formatVersion: skilltrackerFormatVersion,
        createdAtUtc: now.toUtc().toIso8601String(),
        applicationVersion: appVersion,
        databaseSchemaVersion: AppConstants.schemaVersion,
        sourcePlatform: _platform,
        sourceDeviceId: device,
        timezone: _timezones.ianaId,
        encrypted: false,
        compression: 'zip-deflate',
        payloadPath: 'payload/data.json',
        payloadMediaType: 'application/json',
        payloadSha256: '',
        payloadUncompressedBytes: payloadBytes.length,
        summary: summary,
      );
      final zip = _codec.encode(
        manifestWithoutPayloadHash: manifest,
        payloadJsonBytes: payloadBytes,
      );
      final suggested =
          'ayutam-backup-${_fileStamp.format(now.toLocal())}.skilltracker';
      final savedPath = await _files.saveBytes(
        bytes: zip,
        suggestedName: suggested,
        extension: 'skilltracker',
        mimeType: 'application/zip',
        relativeDocumentsSubdir: 'Ayutam/backups',
      );
      if (savedPath == null) {
        await _store.recordBackupAttempt(
          id: attemptId,
          backupType: 'skilltracker',
          status: 'cancelled',
          createdAtUtc: now,
          errorCode: 'CANCELLED',
        );
        return const Failure(
          AppFailure(code: 'BACKUP-CANCEL', message: 'Export cancelled.'),
        );
      }

      // Verify-before-success using the bytes we just produced (and any
      // readable on-disk copy). Never update verified_at from the JKS/signing
      // path — only from archive re-parse.
      final written = await _store.liveDatabasePath() == null
          ? zip
          : await _readIfPossible(savedPath) ?? zip;
      final verified = _codec.decode(written, fileName: suggested);
      if (verified is Failure<DecodedSkilltracker>) {
        await _store.recordBackupAttempt(
          id: attemptId,
          backupType: 'skilltracker',
          status: 'failed',
          createdAtUtc: now,
          destinationDisplay: savedPath,
          fileSha256: sha256Hex(zip),
          errorCode: verified.error.code,
        );
        return Failure(verified.error);
      }
      final decoded = (verified as Success<DecodedSkilltracker>).value;
      final semantic = validateBackupPayload(decoded.payload);
      if (semantic is Failure<void>) {
        await _store.recordBackupAttempt(
          id: attemptId,
          backupType: 'skilltracker',
          status: 'failed',
          createdAtUtc: now,
          destinationDisplay: savedPath,
          fileSha256: sha256Hex(zip),
          errorCode: semantic.error.code,
        );
        return Failure(semantic.error);
      }

      await _store.recordBackupAttempt(
        id: attemptId,
        backupType: 'skilltracker',
        status: 'success',
        createdAtUtc: now,
        destinationDisplay: savedPath,
        verifiedAtUtc: _clock.nowUtc(),
        sessionHighWatermarkUtc: now,
        skillsCount: summary.skills,
        sessionsCount: summary.sessions,
        totalActiveSeconds: summary.completedActiveSeconds,
        fileSha256: sha256Hex(zip),
      );
      return Success(savedPath);
    } catch (e) {
      await _store.recordBackupAttempt(
        id: attemptId,
        backupType: 'skilltracker',
        status: 'failed',
        createdAtUtc: now,
        errorCode: 'BACKUP-EXPORT',
      );
      return Failure(
        AppFailure(code: 'BACKUP-EXPORT', message: 'Export failed.', cause: e),
      );
    }
  }

  /// Export to an in-memory ZIP for tests (still verify-before-success).
  @visibleForTesting
  Future<Result<Uint8List>> exportSkilltrackerBytes() async {
    final attemptId = _newId();
    final now = _clock.nowUtc();
    final payload = await _store.readPayload();
    final summary = payload.computeSummary();
    final payloadBytes = encodePayloadBytes(payload);
    final device = await _deviceId();
    final appVersion = await _applicationVersion();
    final manifest = BackupManifest(
      format: skilltrackerFormat,
      formatVersion: skilltrackerFormatVersion,
      createdAtUtc: now.toUtc().toIso8601String(),
      applicationVersion: appVersion,
      databaseSchemaVersion: AppConstants.schemaVersion,
      sourcePlatform: _platform,
      sourceDeviceId: device,
      timezone: _timezones.ianaId,
      encrypted: false,
      compression: 'zip-deflate',
      payloadPath: 'payload/data.json',
      payloadMediaType: 'application/json',
      payloadSha256: '',
      payloadUncompressedBytes: payloadBytes.length,
      summary: summary,
    );
    final zip = _codec.encode(
      manifestWithoutPayloadHash: manifest,
      payloadJsonBytes: payloadBytes,
    );
    final verified = _codec.decode(zip, fileName: 'test.skilltracker');
    if (verified is Failure<DecodedSkilltracker>) {
      await _store.recordBackupAttempt(
        id: attemptId,
        backupType: 'skilltracker',
        status: 'failed',
        createdAtUtc: now,
        fileSha256: sha256Hex(zip),
        errorCode: verified.error.code,
      );
      return Failure(verified.error);
    }
    final semantic = validateBackupPayload(
      (verified as Success<DecodedSkilltracker>).value.payload,
    );
    if (semantic is Failure<void>) {
      await _store.recordBackupAttempt(
        id: attemptId,
        backupType: 'skilltracker',
        status: 'failed',
        createdAtUtc: now,
        fileSha256: sha256Hex(zip),
        errorCode: semantic.error.code,
      );
      return Failure(semantic.error);
    }
    await _store.recordBackupAttempt(
      id: attemptId,
      backupType: 'skilltracker',
      status: 'success',
      createdAtUtc: now,
      destinationDisplay: 'memory',
      verifiedAtUtc: _clock.nowUtc(),
      sessionHighWatermarkUtc: now,
      skillsCount: summary.skills,
      sessionsCount: summary.sessions,
      totalActiveSeconds: summary.completedActiveSeconds,
      fileSha256: sha256Hex(zip),
    );
    return Success(zip);
  }

  Future<Uint8List?> _readIfPossible(String path) async {
    try {
      return await _store.readFileBytes(path);
    } catch (_) {
      return null;
    }
  }

  Future<Result<ImportPreview>> previewImport() async {
    final opened = await _files.openBackupFile();
    if (opened == null) {
      return const Failure(
        AppFailure(code: 'BACKUP-CANCEL', message: 'Import cancelled.'),
      );
    }
    return previewImportBytes(bytes: opened.bytes, fileName: opened.fileName);
  }

  @visibleForTesting
  Future<Result<ImportPreview>> previewImportBytes({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final decoded = _codec.decode(bytes, fileName: fileName);
    if (decoded is Failure<DecodedSkilltracker>) {
      return Failure(decoded.error);
    }
    final value = (decoded as Success<DecodedSkilltracker>).value;
    final semantic = validateBackupPayload(value.payload);
    if (semantic is Failure<void>) {
      return Failure(semantic.error);
    }
    final local = await _store.readPayload();
    final merged = _mergeEngine.merge(local: local, incoming: value.payload);
    return Success(
      ImportPreview(
        fileName: fileName,
        manifest: value.manifest,
        payload: value.payload,
        checksumOk: true,
        conflicts: merged.conflicts,
        localHasActiveOrPending: await _store.hasActiveOrPendingSession(),
      ),
    );
  }

  Future<Result<void>> applyImport({
    required ImportPreview preview,
    required ImportMode mode,
    ConflictResolution conflictResolution = ConflictResolution.keepCurrent,
    Map<String, ConflictResolution> perItem = const {},
    bool restoreActiveTimer = false,
  }) async {
    final snap = await createSafetySnapshot(
      reason: mode == ImportMode.replace ? 'pre_replace' : 'pre_merge',
    );
    if (snap is Failure<LocalSnapshotInfo>) {
      return Failure(snap.error);
    }

    final local = await _store.readPayload();
    late BackupPayload toApply;
    if (mode == ImportMode.replace) {
      toApply = preview.payload;
    } else {
      final merged = _mergeEngine.merge(
        local: local,
        incoming: preview.payload,
        defaultResolution: conflictResolution,
        perItem: perItem,
      );
      toApply = merged.payload;
    }
    if (!restoreActiveTimer) {
      toApply = _forceIdleSessions(toApply);
    }

    try {
      if (mode == ImportMode.replace) {
        await _store.applyReplace(toApply);
      } else {
        await _store.applyMerged(toApply);
      }
      return const Success(null);
    } catch (e) {
      return Failure(
        AppFailure(
          code: 'BACKUP-IMPORT',
          message:
              'Import failed; your previous data should be unchanged. '
              'A safety snapshot was created.',
          cause: e,
        ),
      );
    }
  }

  BackupPayload _forceIdleSessions(BackupPayload payload) {
    final sessions = payload.sessions.map((s) {
      if (s.deletedAtUtc == null &&
          (s.status == 'active' ||
              s.status == 'paused' ||
              s.status == 'completion_pending')) {
        return BackupSessionRecord(
          id: s.id,
          skillId: s.skillId,
          title: s.title,
          noteMarkdown: s.noteMarkdown,
          mode: s.mode,
          status: 'completed',
          source: s.source,
          startAtUtc: s.startAtUtc,
          endAtUtc: s.endAtUtc ?? s.startAtUtc,
          activeSeconds: s.activeSeconds,
          pausedSeconds: s.pausedSeconds,
          timezoneIdAtCreation: s.timezoneIdAtCreation,
          offsetMinutesAtStart: s.offsetMinutesAtStart,
          createdAtUtc: s.createdAtUtc,
          updatedAtUtc: s.updatedAtUtc,
          sourceDeviceId: s.sourceDeviceId,
          deletedAtUtc: s.deletedAtUtc,
        );
      }
      return s;
    }).toList();
    return BackupPayload(
      dataVersion: payload.dataVersion,
      exportedAtUtc: payload.exportedAtUtc,
      skills: payload.skills,
      sessions: sessions,
      sessionSegments: payload.sessionSegments,
      tags: payload.tags,
      sessionTags: payload.sessionTags,
      settings: payload.settings,
      deviceMetadata: payload.deviceMetadata,
      timerRuntime: null,
      backupMetadata: payload.backupMetadata,
    );
  }

  Future<Result<LocalSnapshotInfo>> createSafetySnapshot({
    required String reason,
  }) async {
    final path = await _store.liveDatabasePath();
    final id = _newId();
    final now = _clock.nowUtc();
    if (path == null) {
      final info = await _store.createSnapshot(
        id: id,
        reason: reason,
        filePath: 'memory://$id',
        fileSha256: sha256Hex(utf8.encode(id)),
        sizeBytes: 0,
        schemaVersion: AppConstants.schemaVersion,
        createdAtUtc: now,
      );
      await _pruneSnapshots();
      return Success(info);
    }

    try {
      final dir = await _snapshotsDirectory();
      final dest = '$dir${PlatformPath.sep}snapshot-$id.sqlite';
      await _store.vacuumInto(dest);
      final bytes = await _store.readFileBytes(dest);
      final info = await _store.createSnapshot(
        id: id,
        reason: reason,
        filePath: dest,
        fileSha256: sha256Hex(bytes),
        sizeBytes: bytes.length,
        schemaVersion: AppConstants.schemaVersion,
        createdAtUtc: now,
      );
      await _pruneSnapshots(keep: 3);
      return Success(info);
    } catch (e) {
      return Failure(
        AppFailure(
          code: 'BACKUP-SNAPSHOT',
          message: 'Could not create a safety snapshot.',
          cause: e,
        ),
      );
    }
  }

  Future<void> _pruneSnapshots({int keep = 3}) async {
    final list = await _store.listSnapshots();
    list.sort((a, b) => b.createdAtUtc.compareTo(a.createdAtUtc));
    for (final old in list.skip(keep)) {
      await _store.deleteSnapshotRow(old.id);
    }
  }

  Future<List<LocalSnapshotInfo>> listSnapshots() => _store.listSnapshots();

  /// Restore a local safety snapshot (replace live data after a new snapshot).
  Future<Result<void>> restoreSnapshot(LocalSnapshotInfo snapshot) async {
    if (!snapshot.isValid) {
      return const Failure(
        AppFailure(
          code: 'BACKUP-SNAPSHOT-INVALID',
          message: 'This snapshot is marked invalid and cannot be restored.',
        ),
      );
    }
    if (snapshot.filePath.startsWith('memory://')) {
      return const Failure(
        AppFailure(
          code: 'BACKUP-SNAPSHOT-MEM',
          message: 'This snapshot has no on-disk file to restore.',
        ),
      );
    }
    try {
      final payload = await _store.readPayloadFromSnapshotFile(
        snapshot.filePath,
      );
      final semantic = validateBackupPayload(payload);
      if (semantic is Failure<void>) {
        return Failure(semantic.error);
      }
      final guard = await createSafetySnapshot(reason: 'pre_restore');
      if (guard is Failure<LocalSnapshotInfo>) {
        return Failure(guard.error);
      }
      await _store.applyReplace(_forceIdleSessions(payload));
      return const Success(null);
    } catch (e) {
      return Failure(
        AppFailure(
          code: 'BACKUP-RESTORE',
          message: 'Could not restore the safety snapshot.',
          cause: e,
        ),
      );
    }
  }
}

/// Tiny path separator helper so application code stays free of `dart:io`.
abstract final class PlatformPath {
  static const sep = '/';
}
