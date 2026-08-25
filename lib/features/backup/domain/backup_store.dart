import 'dart:typed_data';

import 'backup_models.dart';

/// Reads/writes the live store for portable backup operations.
abstract class BackupStore {
  Future<BackupPayload> readPayload();

  /// Replace all user data with [payload] inside one transaction.
  Future<void> applyReplace(BackupPayload payload);

  /// Apply a pre-merged payload (same transactional write path as replace).
  Future<void> applyMerged(BackupPayload payload);

  Future<bool> hasActiveOrPendingSession();

  Future<DateTime?> lastSuccessfulBackupAt();

  Future<int> sessionsChangedSince(DateTime? watermark);

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
  });

  Future<List<LocalSnapshotInfo>> listSnapshots();

  Future<LocalSnapshotInfo> createSnapshot({
    required String id,
    required String reason,
    required String filePath,
    required String fileSha256,
    required int sizeBytes,
    required int schemaVersion,
    required DateTime createdAtUtc,
  });

  Future<void> markSnapshotInvalid(String id);

  Future<void> deleteSnapshotRow(String id);

  /// Absolute path of the live SQLite database file, or null for memory DBs.
  Future<String?> liveDatabasePath();

  /// Consistent on-disk snapshot via SQLite `VACUUM INTO` (dest must not exist).
  Future<void> vacuumInto(String destPath);

  Future<Uint8List> readFileBytes(String path);

  Future<void> deleteFileIfExists(String path);

  /// Open a safety-snapshot SQLite file and read it as a portable payload.
  Future<BackupPayload> readPayloadFromSnapshotFile(String path);
}

/// Platform file dialogs / document saves for backups and exports.
abstract class BackupFileIo {
  Future<String?> saveBytes({
    required Uint8List bytes,
    required String suggestedName,
    required String extension,
    required String mimeType,
    String? relativeDocumentsSubdir,
  });

  Future<OpenedBackupFile?> openBackupFile();

  Future<String?> pickSavePath({
    required String suggestedName,
    required String extension,
  });
}

final class OpenedBackupFile {
  const OpenedBackupFile({required this.fileName, required this.bytes});

  final String fileName;
  final Uint8List bytes;
}
