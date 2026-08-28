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

      // Verify-before-success: re-read the saved file only (never fall back to
      // the in-memory zip). exportSkilltrackerBytes() is the test path.
      final Uint8List written;
      try {
        written = await _files.readBytes(savedPath);
      } catch (e) {
        await _store.recordBackupAttempt(
          id: attemptId,
          backupType: 'skilltracker',
          status: 'failed',
          createdAtUtc: now,
          destinationDisplay: savedPath,
          fileSha256: sha256Hex(zip),
          errorCode: 'BACKUP-VERIFY-READ',
        );
        return Failure(
          AppFailure(
            code: 'BACKUP-VERIFY-READ',
            message: 'Could not re-read the saved backup for verification.',
            cause: e,
          ),
        );
      }

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
        fileSha256: sha256Hex(written),
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

  /// Standalone JSON export (same logical payload; hash exact payload bytes).
  Future<Result<String>> exportJson() async {
    final attemptId = _newId();
    final now = _clock.nowUtc();
    try {
      final payload = await _store.readPayload();
      final summary = payload.computeSummary();
      final payloadBytes = encodePayloadBytes(payload);
      final device = await _deviceId();
      final appVersion = await _applicationVersion();
      final dataJson = jsonDecode(utf8.decode(payloadBytes)) as Object?;
      final envelope = <String, Object?>{
        'format': portableJsonFormat,
        'formatVersion': portableJsonFormatVersion,
        'applicationVersion': appVersion,
        'databaseSchemaVersion': AppConstants.schemaVersion,
        'createdAtUtc': now.toUtc().toIso8601String(),
        'sourcePlatform': _platform,
        'sourceDeviceId': device,
        'timezone': _timezones.ianaId,
        'data': dataJson,
        'dataSha256': sha256Hex(payloadBytes),
      };
      final fileBytes = Uint8List.fromList(
        utf8.encode(const JsonEncoder.withIndent('  ').convert(envelope)),
      );
      final suggested =
          'ayutam-backup-${_fileStamp.format(now.toLocal())}.json';
      final savedPath = await _files.saveBytes(
        bytes: fileBytes,
        suggestedName: suggested,
        extension: 'json',
        mimeType: 'application/json',
        relativeDocumentsSubdir: 'Ayutam/backups',
      );
      if (savedPath == null) {
        await _store.recordBackupAttempt(
          id: attemptId,
          backupType: 'json',
          status: 'cancelled',
          createdAtUtc: now,
          errorCode: 'CANCELLED',
        );
        return const Failure(
          AppFailure(code: 'BACKUP-CANCEL', message: 'Export cancelled.'),
        );
      }

      final Uint8List written;
      try {
        written = await _files.readBytes(savedPath);
      } catch (e) {
        await _store.recordBackupAttempt(
          id: attemptId,
          backupType: 'json',
          status: 'failed',
          createdAtUtc: now,
          destinationDisplay: savedPath,
          fileSha256: sha256Hex(fileBytes),
          errorCode: 'BACKUP-VERIFY-READ',
        );
        return Failure(
          AppFailure(
            code: 'BACKUP-VERIFY-READ',
            message: 'Could not re-read the saved backup for verification.',
            cause: e,
          ),
        );
      }

      final decoded = _decodePortableJson(written, fileName: suggested);
      if (decoded is Failure<(BackupManifest, BackupPayload)>) {
        await _store.recordBackupAttempt(
          id: attemptId,
          backupType: 'json',
          status: 'failed',
          createdAtUtc: now,
          destinationDisplay: savedPath,
          fileSha256: sha256Hex(fileBytes),
          errorCode: decoded.error.code,
        );
        return Failure(decoded.error);
      }
      final semantic = validateBackupPayload(
        (decoded as Success<(BackupManifest, BackupPayload)>).value.$2,
      );
      if (semantic is Failure<void>) {
        await _store.recordBackupAttempt(
          id: attemptId,
          backupType: 'json',
          status: 'failed',
          createdAtUtc: now,
          destinationDisplay: savedPath,
          fileSha256: sha256Hex(fileBytes),
          errorCode: semantic.error.code,
        );
        return Failure(semantic.error);
      }

      await _store.recordBackupAttempt(
        id: attemptId,
        backupType: 'json',
        status: 'success',
        createdAtUtc: now,
        destinationDisplay: savedPath,
        verifiedAtUtc: _clock.nowUtc(),
        sessionHighWatermarkUtc: now,
        skillsCount: summary.skills,
        sessionsCount: summary.sessions,
        totalActiveSeconds: summary.completedActiveSeconds,
        fileSha256: sha256Hex(written),
      );
      return Success(savedPath);
    } catch (e) {
      await _store.recordBackupAttempt(
        id: attemptId,
        backupType: 'json',
        status: 'failed',
        createdAtUtc: now,
        errorCode: 'BACKUP-EXPORT',
      );
      return Failure(
        AppFailure(
          code: 'BACKUP-EXPORT',
          message: 'JSON export failed.',
          cause: e,
        ),
      );
    }
  }

  Future<Result<ImportPreview>> previewImport() async {
    final opened = await _files.openBackupFile();
    if (opened == null) {
      return const Failure(
        AppFailure(code: 'BACKUP-CANCEL', message: 'Import cancelled.'),
      );
    }
    final lower = opened.fileName.toLowerCase();
    if (lower.endsWith('.sqlite') || lower.endsWith('.db')) {
      return previewSqliteImportBytes(
        bytes: opened.bytes,
        fileName: opened.fileName,
      );
    }
    return previewImportBytes(bytes: opened.bytes, fileName: opened.fileName);
  }

  /// Import preview for a standalone JSON or `.skilltracker` archive.
  @visibleForTesting
  Future<Result<ImportPreview>> previewImportBytes({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final lower = fileName.toLowerCase();
    final BackupManifest manifest;
    final BackupPayload payload;
    final BackupSourceKind sourceKind;

    if (lower.endsWith('.json') || _looksLikeJson(bytes)) {
      final decoded = _decodePortableJson(bytes, fileName: fileName);
      if (decoded is Failure<(BackupManifest, BackupPayload)>) {
        return Failure(decoded.error);
      }
      final value = (decoded as Success<(BackupManifest, BackupPayload)>).value;
      manifest = value.$1;
      payload = value.$2;
      sourceKind = BackupSourceKind.json;
    } else {
      final decoded = _codec.decode(bytes, fileName: fileName);
      if (decoded is Failure<DecodedSkilltracker>) {
        return Failure(decoded.error);
      }
      final value = (decoded as Success<DecodedSkilltracker>).value;
      manifest = value.manifest;
      payload = value.payload;
      sourceKind = BackupSourceKind.skilltracker;
    }

    final semantic = validateBackupPayload(payload);
    if (semantic is Failure<void>) {
      return Failure(semantic.error);
    }
    return _buildPreview(
      fileName: fileName,
      manifest: manifest,
      payload: payload,
      sourceKind: sourceKind,
    );
  }

  /// Open a `.sqlite` snapshot via the file picker and preview it.
  Future<Result<ImportPreview>> previewSqliteImport() async {
    final opened = await _files.openBackupFile();
    if (opened == null) {
      return const Failure(
        AppFailure(code: 'BACKUP-CANCEL', message: 'Import cancelled.'),
      );
    }
    return previewSqliteImportBytes(
      bytes: opened.bytes,
      fileName: opened.fileName,
    );
  }

  @visibleForTesting
  Future<Result<ImportPreview>> previewSqliteImportBytes({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final dir = await _snapshotsDirectory();
    final tempPath = '$dir${PlatformPath.sep}import-${_newId()}.sqlite';
    try {
      await _store.writeFileBytes(tempPath, bytes);
      final payload = await _store.readPayloadFromSnapshotFile(tempPath);
      final semantic = validateBackupPayload(payload);
      if (semantic is Failure<void>) {
        return Failure(semantic.error);
      }
      final summary = payload.computeSummary();
      final device = await _deviceId();
      final appVersion = await _applicationVersion();
      final now = _clock.nowUtc();
      final manifest = BackupManifest(
        format: 'ayutam-sqlite-snapshot',
        formatVersion: 1,
        createdAtUtc: now.toUtc().toIso8601String(),
        applicationVersion: appVersion,
        databaseSchemaVersion: AppConstants.schemaVersion,
        sourcePlatform: _platform,
        sourceDeviceId: device,
        timezone: _timezones.ianaId,
        encrypted: false,
        compression: 'none',
        payloadPath: fileName,
        payloadMediaType: 'application/x-sqlite3',
        payloadSha256: sha256Hex(bytes),
        payloadUncompressedBytes: bytes.length,
        summary: summary,
      );
      return _buildPreview(
        fileName: fileName,
        manifest: manifest,
        payload: payload,
        sourceKind: BackupSourceKind.sqlite,
      );
    } catch (e) {
      return Failure(
        AppFailure(
          code: 'BACKUP-SQLITE',
          message: 'Could not read the SQLite snapshot.',
          cause: e,
        ),
      );
    } finally {
      await _store.deleteFileIfExists(tempPath);
    }
  }

  Future<Result<ImportPreview>> _buildPreview({
    required String fileName,
    required BackupManifest manifest,
    required BackupPayload payload,
    required BackupSourceKind sourceKind,
  }) async {
    final local = await _store.readPayload();
    final dryRun = _mergeEngine.merge(local: local, incoming: payload);
    return Success(
      ImportPreview(
        fileName: fileName,
        manifest: manifest,
        payload: payload,
        checksumOk: true,
        conflicts: previewConflictsFor(
          conflicts: dryRun.conflicts,
          collision: dryRun.activeSessionCollision,
        ),
        localHasActiveOrPending: await _store.hasActiveOrPendingSession(),
        activeSessionCollision: dryRun.activeSessionCollision,
        sourceKind: sourceKind,
      ),
    );
  }

  Future<Result<void>> applyImport({
    required ImportPreview preview,
    required ImportMode mode,
    ConflictResolution conflictResolution = ConflictResolution.keepCurrent,
    Map<String, ConflictResolution> perItem = const {},
    ActiveSessionDecision? activeDecision,
    DateTime? reviewedEndUtc,
    bool restoreActiveTimer = false,
  }) async {
    if (activeDecision == ActiveSessionDecision.cancel) {
      return const Failure(
        AppFailure(code: 'BACKUP-CANCEL', message: 'Import cancelled.'),
      );
    }

    if (mode == ImportMode.merge &&
        preview.requiresActiveSessionDecision &&
        activeDecision == null) {
      return const Failure(
        AppFailure(
          code: 'BACKUP-ACTIVE-DECISION',
          message:
              'Both this device and the backup have an in-progress session. '
              'Choose how to resolve it before merging.',
        ),
      );
    }

    if (activeDecision == ActiveSessionDecision.completeOtherWithEnd &&
        preview.activeSessionCollision?.sameSessionId == true) {
      return const Failure(
        AppFailure(
          code: 'BACKUP-ACTIVE-DECISION',
          message:
              'Cannot complete the imported session separately when both sides '
              'share the same live session id. Choose Keep current or Prefer '
              'imported.',
        ),
      );
    }

    if (activeDecision == ActiveSessionDecision.completeOtherWithEnd &&
        reviewedEndUtc == null) {
      return const Failure(
        AppFailure(
          code: 'BACKUP-ACTIVE-DECISION',
          message:
              'A reviewed end time is required to complete the '
              'imported session.',
        ),
      );
    }

    if (activeDecision == ActiveSessionDecision.completeOtherWithEnd &&
        reviewedEndUtc != null &&
        reviewedEndUtc.toUtc().isAfter(_clock.nowUtc())) {
      return const Failure(
        AppFailure(
          code: 'BACKUP-REVIEWED-END',
          message: 'Reviewed end time cannot be in the future.',
        ),
      );
    }

    final snap = await createSafetySnapshot(
      reason: mode == ImportMode.replace ? 'pre_replace' : 'pre_merge',
    );
    if (snap is Failure<LocalSnapshotInfo>) {
      return Failure(snap.error);
    }

    final local = await _store.readPayload();
    final nowMs = _clock.nowUtc().millisecondsSinceEpoch;
    late BackupPayload toApply;
    if (mode == ImportMode.replace) {
      toApply = preview.payload;
    } else {
      final merged = _mergeEngine.merge(
        local: local,
        incoming: preview.payload,
        defaultResolution: conflictResolution,
        perItem: perItemForMerge(
          perItem: perItem,
          collision: preview.activeSessionCollision,
        ),
        activeDecision: activeDecision,
        reviewedEndAtUtc: reviewedEndUtc?.toUtc().millisecondsSinceEpoch,
        nowUtcMs: nowMs,
      );
      if (merged.cancelled) {
        return const Failure(
          AppFailure(code: 'BACKUP-CANCEL', message: 'Import cancelled.'),
        );
      }
      toApply = merged.payload;
    }

    if (!restoreActiveTimer) {
      toApply = _withoutTimerRuntime(toApply);
    }

    final semantic = validateBackupPayload(toApply);
    if (semantic is Failure<void>) {
      return Failure(semantic.error);
    }

    try {
      if (mode == ImportMode.replace) {
        await _store.applyReplace(
          toApply,
          restoreActiveTimer: restoreActiveTimer,
        );
      } else {
        await _store.applyMerged(
          toApply,
          restoreActiveTimer: restoreActiveTimer,
        );
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

  Result<(BackupManifest, BackupPayload)> _decodePortableJson(
    Uint8List bytes, {
    required String fileName,
  }) {
    if (bytes.length > maxSkilltrackerBytes) {
      return const Failure(
        AppFailure(
          code: 'BACKUP-SIZE',
          message: 'Backup file exceeds the maximum allowed size.',
        ),
      );
    }
    try {
      final decoded = jsonDecode(utf8.decode(bytes));
      if (decoded is! Map) {
        return const Failure(
          AppFailure(
            code: 'BACKUP-JSON',
            message: 'JSON backup root must be an object.',
          ),
        );
      }
      final root = decoded.cast<String, Object?>();

      // Canonical envelope: format + data + dataSha256.
      if (root.containsKey('data')) {
        final format = root['format'] as String? ?? '';
        if (format.isNotEmpty &&
            format != portableJsonFormat &&
            format != skilltrackerFormat) {
          return Failure(
            AppFailure(
              code: 'BACKUP-FORMAT',
              message: 'Unsupported JSON backup format "$format".',
            ),
          );
        }
        final formatVersion =
            (root['formatVersion'] as num?)?.toInt() ??
            portableJsonFormatVersion;
        if (formatVersion > portableJsonFormatVersion) {
          return const Failure(
            AppFailure(
              code: 'BACKUP-FORMAT-VERSION',
              message: 'This JSON backup was made by a newer Ayutam version.',
            ),
          );
        }
        final dataRaw = root['data'];
        if (dataRaw is! Map) {
          return const Failure(
            AppFailure(
              code: 'BACKUP-JSON',
              message: 'JSON backup is missing a data object.',
            ),
          );
        }
        final dataMap = dataRaw.map((k, v) => MapEntry(k.toString(), v));
        final payload = BackupPayload.fromJson(dataMap.cast<String, Object?>());
        final expectedSha = normalizeSha256(
          root['dataSha256'] as String? ?? '',
        );
        if (expectedSha.isNotEmpty) {
          final canonical = encodePayloadBytes(payload);
          if (sha256Hex(canonical) != expectedSha) {
            return const Failure(
              AppFailure(
                code: 'BACKUP-HASH',
                message: 'JSON backup data hash does not match.',
              ),
            );
          }
        }
        final summary = payload.computeSummary();
        final manifest = BackupManifest(
          format: format.isEmpty ? portableJsonFormat : format,
          formatVersion: formatVersion,
          createdAtUtc:
              root['createdAtUtc'] as String? ??
              root['exportedAtUtc'] as String? ??
              payload.exportedAtUtc,
          applicationVersion: root['applicationVersion'] as String? ?? '',
          databaseSchemaVersion:
              (root['databaseSchemaVersion'] as num?)?.toInt() ??
              AppConstants.schemaVersion,
          sourcePlatform: root['sourcePlatform'] as String? ?? '',
          sourceDeviceId: root['sourceDeviceId'] as String? ?? '',
          timezone: root['timezone'] as String? ?? 'UTC',
          encrypted: false,
          compression: 'none',
          payloadPath: 'data',
          payloadMediaType: 'application/json',
          payloadSha256: expectedSha,
          payloadUncompressedBytes: encodePayloadBytes(payload).length,
          summary: summary,
        );
        return Success((manifest, payload));
      }

      // Legacy-looking: bare BackupPayload (or payload nested under "payload").
      final Map<String, Object?> payloadMap;
      if (root.containsKey('skills') || root.containsKey('dataVersion')) {
        payloadMap = root;
      } else if (root['payload'] is Map) {
        payloadMap = (root['payload'] as Map).map(
          (k, v) => MapEntry(k.toString(), v),
        );
      } else {
        return const Failure(
          AppFailure(
            code: 'BACKUP-JSON',
            message: 'Unrecognized JSON backup structure.',
          ),
        );
      }
      final payload = BackupPayload.fromJson(payloadMap);
      final summary = payload.computeSummary();
      final manifest = BackupManifest(
        format: portableJsonFormat,
        formatVersion: portableJsonFormatVersion,
        createdAtUtc: payload.exportedAtUtc,
        applicationVersion: root['applicationVersion'] as String? ?? '',
        databaseSchemaVersion:
            (root['databaseSchemaVersion'] as num?)?.toInt() ??
            AppConstants.schemaVersion,
        sourcePlatform: root['sourcePlatform'] as String? ?? '',
        sourceDeviceId: root['sourceDeviceId'] as String? ?? '',
        timezone: root['timezone'] as String? ?? 'UTC',
        encrypted: false,
        compression: 'none',
        payloadPath: fileName,
        payloadMediaType: 'application/json',
        payloadSha256: '',
        payloadUncompressedBytes: bytes.length,
        summary: summary,
      );
      return Success((manifest, payload));
    } catch (e) {
      return Failure(
        AppFailure(
          code: 'BACKUP-JSON',
          message: 'Could not parse JSON backup.',
          cause: e,
        ),
      );
    }
  }

  static bool _looksLikeJson(Uint8List bytes) {
    for (final b in bytes) {
      if (b == 0x20 || b == 0x0a || b == 0x0d || b == 0x09) continue;
      return b == 0x7b; // '{'
    }
    return false;
  }

  BackupPayload _withoutTimerRuntime(BackupPayload payload) {
    return BackupPayload(
      dataVersion: payload.dataVersion,
      exportedAtUtc: payload.exportedAtUtc,
      skills: payload.skills,
      sessions: payload.sessions,
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
      if (!old.filePath.startsWith('memory://')) {
        await _store.deleteFileIfExists(old.filePath);
      }
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
      await _store.applyReplace(
        _withoutTimerRuntime(payload),
        restoreActiveTimer: false,
      );
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
