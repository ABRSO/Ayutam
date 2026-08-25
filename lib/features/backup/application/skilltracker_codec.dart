import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';

import '../../../core/result/result.dart';
import '../domain/backup_models.dart';

String sha256Hex(List<int> bytes) => sha256.convert(bytes).toString();

String normalizeSha256(String value) =>
    value.replaceAll(RegExp(r'[^0-9a-fA-F]'), '').toLowerCase();

/// Builds and parses `.skilltracker` ZIP archives (manifest + payload + checksums).
final class SkilltrackerCodec {
  const SkilltrackerCodec();

  /// Encode a verified archive. [payloadJsonBytes] must be the exact UTF-8
  /// bytes that will be hashed and stored (do not re-serialize later).
  Uint8List encode({
    required BackupManifest manifestWithoutPayloadHash,
    required Uint8List payloadJsonBytes,
  }) {
    final payloadSha = sha256Hex(payloadJsonBytes);
    final manifest = BackupManifest(
      format: manifestWithoutPayloadHash.format,
      formatVersion: manifestWithoutPayloadHash.formatVersion,
      createdAtUtc: manifestWithoutPayloadHash.createdAtUtc,
      applicationVersion: manifestWithoutPayloadHash.applicationVersion,
      databaseSchemaVersion: manifestWithoutPayloadHash.databaseSchemaVersion,
      sourcePlatform: manifestWithoutPayloadHash.sourcePlatform,
      sourceDeviceId: manifestWithoutPayloadHash.sourceDeviceId,
      timezone: manifestWithoutPayloadHash.timezone,
      encrypted: false,
      compression: 'zip-deflate',
      payloadPath: 'payload/data.json',
      payloadMediaType: 'application/json',
      payloadSha256: payloadSha,
      payloadUncompressedBytes: payloadJsonBytes.length,
      summary: manifestWithoutPayloadHash.summary,
    );
    final manifestBytes = utf8.encode(
      const JsonEncoder.withIndent('  ').convert(manifest.toJson()),
    );
    final checksums = utf8.encode(
      '${sha256Hex(manifestBytes)}  manifest.json\n'
      '$payloadSha  payload/data.json\n',
    );

    final archive = Archive()
      ..add(ArchiveFile('manifest.json', manifestBytes.length, manifestBytes))
      ..add(
        ArchiveFile(
          'payload/data.json',
          payloadJsonBytes.length,
          payloadJsonBytes,
        ),
      )
      ..add(ArchiveFile('checksums.sha256', checksums.length, checksums));

    return Uint8List.fromList(ZipEncoder().encode(archive));
  }

  Result<DecodedSkilltracker> decode(
    Uint8List zipBytes, {
    required String fileName,
  }) {
    if (zipBytes.length > maxSkilltrackerBytes) {
      return const Failure(
        AppFailure(
          code: 'BACKUP-SIZE',
          message: 'Backup file exceeds the maximum allowed size.',
        ),
      );
    }
    if (zipBytes.length < 4 || zipBytes[0] != 0x50 || zipBytes[1] != 0x4b) {
      return const Failure(
        AppFailure(
          code: 'BACKUP-MAGIC',
          message: 'File is not a valid .skilltracker archive.',
        ),
      );
    }

    final Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(zipBytes, verify: true);
    } catch (e) {
      return Failure(
        AppFailure(
          code: 'BACKUP-ZIP',
          message: 'Could not read the backup archive.',
          cause: e,
        ),
      );
    }

    final names = <String>{};
    final files = <String, Uint8List>{};
    for (final file in archive) {
      final name = file.name.replaceAll('\\', '/');
      if (name.contains('..') || name.startsWith('/')) {
        return const Failure(
          AppFailure(
            code: 'BACKUP-PATH',
            message: 'Backup archive contains an unsafe path.',
          ),
        );
      }
      if (file.isSymbolicLink) {
        return const Failure(
          AppFailure(
            code: 'BACKUP-SYMLINK',
            message: 'Backup archive must not contain symbolic links.',
          ),
        );
      }
      if (!file.isFile) {
        continue;
      }
      if (!names.add(name)) {
        return Failure(
          AppFailure(
            code: 'BACKUP-DUP',
            message: 'Backup archive has a duplicate entry: $name',
          ),
        );
      }
      final Uint8List content;
      try {
        content = Uint8List.fromList(file.content as List<int>);
      } catch (e) {
        return Failure(
          AppFailure(
            code: 'BACKUP-ZIP',
            message: 'Could not decompress a backup archive entry.',
            cause: e,
          ),
        );
      }
      files[name] = content;
    }

    final required = {'manifest.json', 'payload/data.json', 'checksums.sha256'};
    for (final name in required) {
      if (!files.containsKey(name)) {
        return Failure(
          AppFailure(
            code: 'BACKUP-MISSING',
            message: 'Backup is missing required file: $name',
          ),
        );
      }
    }
    for (final name in files.keys) {
      if (!required.contains(name) && name != 'README.txt') {
        return Failure(
          AppFailure(
            code: 'BACKUP-UNEXPECTED',
            message: 'Backup contains unexpected file: $name',
          ),
        );
      }
    }

    final checksumMap = _parseChecksums(
      utf8.decode(files['checksums.sha256']!),
    );
    if (checksumMap == null) {
      return const Failure(
        AppFailure(
          code: 'BACKUP-CHECKSUM-FMT',
          message: 'checksums.sha256 is malformed.',
        ),
      );
    }
    for (final entry in {
      'manifest.json': files['manifest.json']!,
      'payload/data.json': files['payload/data.json']!,
    }.entries) {
      final expected = checksumMap[entry.key];
      final actual = sha256Hex(entry.value);
      if (expected == null ||
          normalizeSha256(expected) != normalizeSha256(actual)) {
        return Failure(
          AppFailure(
            code: 'BACKUP-CHECKSUM',
            message:
                'Checksum mismatch for ${entry.key}. The backup may be '
                'corrupted or incomplete. No data was changed.',
          ),
        );
      }
    }

    final Map<String, Object?> manifestJson;
    try {
      manifestJson = (jsonDecode(utf8.decode(files['manifest.json']!)) as Map)
          .cast<String, Object?>();
    } catch (e) {
      return Failure(
        AppFailure(
          code: 'BACKUP-MANIFEST-JSON',
          message: 'manifest.json is not valid JSON.',
          cause: e,
        ),
      );
    }
    final manifest = BackupManifest.fromJson(manifestJson);
    if (manifest.format != skilltrackerFormat) {
      return const Failure(
        AppFailure(
          code: 'BACKUP-FORMAT',
          message: 'This file is not an Ayutam portable backup.',
        ),
      );
    }
    if (manifest.formatVersion > skilltrackerFormatVersion) {
      return Failure(
        AppFailure(
          code: 'BACKUP-FORMAT-NEW',
          message:
              'This backup requires a newer Ayutam (format '
              'v${manifest.formatVersion}). Update the app and try again.',
        ),
      );
    }
    if (manifest.formatVersion < 1) {
      return const Failure(
        AppFailure(
          code: 'BACKUP-FORMAT-OLD',
          message: 'Unsupported backup format version.',
        ),
      );
    }
    if (manifest.encrypted) {
      return const Failure(
        AppFailure(
          code: 'BACKUP-ENCRYPTED',
          message: 'Encrypted backups are not supported in this build yet.',
        ),
      );
    }
    if (manifest.payloadPath != 'payload/data.json') {
      return const Failure(
        AppFailure(
          code: 'BACKUP-PAYLOAD-PATH',
          message: 'Backup payload path is invalid.',
        ),
      );
    }
    final payloadBytes = files['payload/data.json']!;
    if (payloadBytes.length > maxPayloadUncompressedBytes) {
      return const Failure(
        AppFailure(
          code: 'BACKUP-PAYLOAD-SIZE',
          message: 'Backup payload exceeds the maximum allowed size.',
        ),
      );
    }
    if (normalizeSha256(manifest.payloadSha256) !=
        normalizeSha256(sha256Hex(payloadBytes))) {
      return const Failure(
        AppFailure(
          code: 'BACKUP-MANIFEST-HASH',
          message: 'Manifest payload hash does not match the payload file.',
        ),
      );
    }

    final Map<String, Object?> payloadJson;
    try {
      payloadJson = (jsonDecode(utf8.decode(payloadBytes)) as Map)
          .cast<String, Object?>();
    } catch (e) {
      return Failure(
        AppFailure(
          code: 'BACKUP-PAYLOAD-JSON',
          message: 'payload/data.json is not valid JSON.',
          cause: e,
        ),
      );
    }
    final payload = BackupPayload.fromJson(payloadJson);
    return Success(
      DecodedSkilltracker(
        fileName: fileName,
        manifest: manifest,
        payload: payload,
        zipBytes: zipBytes,
        payloadJsonBytes: payloadBytes,
      ),
    );
  }

  Map<String, String>? _parseChecksums(String text) {
    final map = <String, String>{};
    for (final rawLine in text.split(RegExp(r'\r?\n'))) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;
      final match = RegExp(r'^([0-9a-fA-F]{64})\s+(.+)$').firstMatch(line);
      if (match == null) return null;
      map[match.group(2)!] = match.group(1)!;
    }
    if (!map.containsKey('manifest.json') ||
        !map.containsKey('payload/data.json')) {
      return null;
    }
    return map;
  }
}

final class DecodedSkilltracker {
  const DecodedSkilltracker({
    required this.fileName,
    required this.manifest,
    required this.payload,
    required this.zipBytes,
    required this.payloadJsonBytes,
  });

  final String fileName;
  final BackupManifest manifest;
  final BackupPayload payload;
  final Uint8List zipBytes;
  final Uint8List payloadJsonBytes;
}

/// Stable UTF-8 JSON for checksummed payload files.
Uint8List encodePayloadBytes(BackupPayload payload) {
  final json = payload.toJson();
  final text = const JsonEncoder.withIndent('  ').convert(json);
  return Uint8List.fromList(utf8.encode(text));
}
