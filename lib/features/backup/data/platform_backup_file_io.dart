import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:file_selector/file_selector.dart';
import 'package:path_provider/path_provider.dart';

import '../domain/backup_store.dart';

/// Platform file dialogs for backup export / import.
///
/// Desktop uses `file_selector`; Android always persists under application
/// documents first so verify-before-success can re-read the file. The PNG
/// MediaStore channel is not used for backups.
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
    final fileName = _ensureExtension(suggestedName, extension);

    if (Platform.isAndroid) {
      final docs = await getApplicationDocumentsDirectory();
      final sub =
          (relativeDocumentsSubdir == null ||
              relativeDocumentsSubdir.trim().isEmpty)
          ? 'Ayutam/backups'
          : relativeDocumentsSubdir.replaceAll('\\', '/');
      final dir = Directory('${docs.path}/$sub');
      await dir.create(recursive: true);
      final verifiedPath = '${dir.path}/$fileName';
      await File(verifiedPath).writeAsBytes(bytes, flush: true);

      // Optional user-facing copy via the system save sheet.
      try {
        await FilePicker.saveFile(
          dialogTitle: 'Save backup',
          fileName: fileName,
          bytes: bytes,
          mimeType: mimeType,
          type: FileType.custom,
          allowedExtensions: [extension],
        );
      } catch (_) {
        // Verified documents path is authoritative; picker failure is non-fatal.
      }
      return verifiedPath;
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
  Future<Uint8List> readBytes(String path) async {
    return Uint8List.fromList(await File(path).readAsBytes());
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
