import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:file_selector/file_selector.dart';

import '../domain/backup_store.dart';

/// Platform file dialogs for backup export / import.
///
/// Desktop uses `file_selector`; Android uses `file_picker` with bytes.
/// The PNG MediaStore channel is not used for backups.
final class PlatformBackupFileIo implements BackupFileIo {
  const PlatformBackupFileIo();

  static const _backupTypeGroup = XTypeGroup(
    label: 'Ayutam backup',
    extensions: ['skilltracker', 'json', 'sqlite'],
  );

  @override
  Future<String?> saveBytes({
    required Uint8List bytes,
    required String suggestedName,
    required String extension,
    required String mimeType,
    String? relativeDocumentsSubdir,
  }) async {
    // relativeDocumentsSubdir is documentary only (e.g. "Ayutam/backups").
    // Never create that path or use the PNG MediaStore channel for backups.
    final fileName = _ensureExtension(suggestedName, extension);

    if (Platform.isAndroid) {
      final uri = await FilePicker.saveFile(
        dialogTitle: 'Save backup',
        fileName: fileName,
        bytes: bytes,
        mimeType: mimeType,
        type: FileType.custom,
        allowedExtensions: [extension],
      );
      return uri?.toString();
    }

    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      final location = await getSaveLocation(
        suggestedName: fileName,
        acceptedTypeGroups: [
          XTypeGroup(label: extension, extensions: [extension]),
        ],
      );
      if (location == null) return null;
      await File(location.path).writeAsBytes(bytes, flush: true);
      return location.path;
    }

    return null;
  }

  @override
  Future<OpenedBackupFile?> openBackupFile() async {
    if (Platform.isAndroid) {
      // file_picker 12 `pickFile` has no `withData`; bytes come from
      // `readAsBytes()` (content URI safe on Android).
      final picked = await FilePicker.pickFile(
        dialogTitle: 'Open backup',
        type: FileType.custom,
        allowedExtensions: const ['skilltracker', 'json', 'sqlite'],
      );
      if (picked == null) return null;
      final bytes = await picked.readAsBytes();
      return OpenedBackupFile(fileName: picked.name, bytes: bytes);
    }

    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      final file = await openFile(acceptedTypeGroups: const [_backupTypeGroup]);
      if (file == null) return null;
      final bytes = await file.readAsBytes();
      return OpenedBackupFile(
        fileName: file.name,
        bytes: Uint8List.fromList(bytes),
      );
    }

    return null;
  }

  @override
  Future<String?> pickSavePath({
    required String suggestedName,
    required String extension,
  }) async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      final location = await getSaveLocation(
        suggestedName: _ensureExtension(suggestedName, extension),
        acceptedTypeGroups: [
          XTypeGroup(label: extension, extensions: [extension]),
        ],
      );
      return location?.path;
    }

    // Android scoped storage has no writable path without writing bytes.
    return null;
  }

  static String _ensureExtension(String suggestedName, String extension) {
    if (suggestedName.toLowerCase().endsWith('.${extension.toLowerCase()}')) {
      return suggestedName;
    }
    return '$suggestedName.$extension';
  }
}
