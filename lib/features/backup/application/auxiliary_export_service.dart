import 'dart:convert';
import 'dart:typed_data';

import 'package:intl/intl.dart';

import '../../../core/result/result.dart';
import '../domain/backup_models.dart';
import '../domain/backup_store.dart';

/// Human-readable / spreadsheet exports (non-restorable except SQLite).
final class AuxiliaryExportService {
  AuxiliaryExportService({
    required BackupStore store,
    required BackupFileIo files,
    required Future<String> Function() tempDirectory,
  }) : _store = store,
       _files = files,
       _tempDirectory = tempDirectory;

  final BackupStore _store;
  final BackupFileIo _files;
  final Future<String> Function() _tempDirectory;

  static final _stamp = DateFormat('yyyy-MM-dd-HHmmss');

  Future<Result<String>> exportCsv() async {
    final payload = await _store.readPayload();
    final tagsById = {for (final t in payload.tags) t.id: t.name};
    final tagsBySession = <String, List<String>>{};
    for (final link in payload.sessionTags) {
      tagsBySession
          .putIfAbsent(link.sessionId, () => <String>[])
          .add(tagsById[link.tagId] ?? link.tagId);
    }
    final skillsById = {for (final s in payload.skills) s.id: s.name};
    final buf = StringBuffer();
    buf.writeln(
      'session_id,skill_name,title,start_at_utc,end_at_utc,timezone,'
      'active_seconds,paused_seconds,mode,source,tags,note_markdown',
    );
    for (final s in payload.sessions) {
      if (s.deletedAtUtc != null) continue;
      final tags = (tagsBySession[s.id] ?? const []).join(';');
      buf.writeln(
        [
          s.id,
          _csv(skillsById[s.skillId] ?? s.skillId),
          _csv(s.title ?? ''),
          DateTime.fromMillisecondsSinceEpoch(
            s.startAtUtc,
            isUtc: true,
          ).toIso8601String(),
          s.endAtUtc == null
              ? ''
              : DateTime.fromMillisecondsSinceEpoch(
                  s.endAtUtc!,
                  isUtc: true,
                ).toIso8601String(),
          _csv(s.timezoneIdAtCreation),
          s.activeSeconds,
          s.pausedSeconds,
          s.mode,
          s.source,
          _csv(tags),
          _csv(s.noteMarkdown ?? ''),
        ].join(','),
      );
    }
    final bytes = Uint8List.fromList(utf8.encode(buf.toString()));
    final name = 'ayutam-sessions-${_stamp.format(DateTime.now())}.csv';
    final path = await _files.saveBytes(
      bytes: bytes,
      suggestedName: name,
      extension: 'csv',
      mimeType: 'text/csv',
      relativeDocumentsSubdir: 'Ayutam/exports',
    );
    if (path == null) {
      return const Failure(
        AppFailure(code: 'BACKUP-CANCEL', message: 'Export cancelled.'),
      );
    }
    return Success(path);
  }

  Future<Result<String>> exportSkillMarkdown(String skillId) async {
    final payload = await _store.readPayload();
    BackupSkillRecord? skill;
    for (final s in payload.skills) {
      if (s.id == skillId) {
        skill = s;
        break;
      }
    }
    if (skill == null) {
      return const Failure(
        AppFailure(code: 'BACKUP-SKILL', message: 'Skill not found.'),
      );
    }
    final sessions =
        payload.sessions
            .where((s) => s.skillId == skillId && s.deletedAtUtc == null)
            .toList()
          ..sort((a, b) => b.startAtUtc.compareTo(a.startAtUtc));
    final tagsById = {for (final t in payload.tags) t.id: t.name};
    final tagsBySession = <String, List<String>>{};
    for (final link in payload.sessionTags) {
      tagsBySession
          .putIfAbsent(link.sessionId, () => <String>[])
          .add(tagsById[link.tagId] ?? link.tagId);
    }

    final totalActive = sessions.fold<int>(0, (n, s) => n + s.activeSeconds);
    final buf = StringBuffer();
    buf.writeln('# ${skill.name}');
    buf.writeln();
    buf.writeln(
      'Target: ${_formatDuration(skill.targetSeconds)} · '
      'Tracked: ${_formatDuration(totalActive)}',
    );
    if (skill.descriptionMarkdown != null &&
        skill.descriptionMarkdown!.trim().isNotEmpty) {
      buf.writeln();
      buf.writeln(skill.descriptionMarkdown);
    }
    buf.writeln();

    String? currentDay;
    for (final s in sessions) {
      final day = DateTime.fromMillisecondsSinceEpoch(
        s.startAtUtc,
        isUtc: true,
      ).toUtc().toIso8601String().substring(0, 10);
      if (day != currentDay) {
        currentDay = day;
        buf.writeln('## $day');
        buf.writeln();
      }
      final title = (s.title?.trim().isNotEmpty == true) ? s.title! : 'Session';
      buf.writeln('### $title · ${_formatDuration(s.activeSeconds)}');
      final tags = tagsBySession[s.id];
      if (tags != null && tags.isNotEmpty) {
        buf.writeln('Tags: ${tags.join(', ')}');
      }
      if (s.noteMarkdown != null && s.noteMarkdown!.trim().isNotEmpty) {
        buf.writeln();
        buf.writeln(s.noteMarkdown);
      }
      buf.writeln();
    }

    final safeName = skill.name.replaceAll(RegExp(r'[^\w\-]+'), '_');
    final name = 'ayutam-$safeName-${_stamp.format(DateTime.now())}.md';
    final bytes = Uint8List.fromList(utf8.encode(buf.toString()));
    final path = await _files.saveBytes(
      bytes: bytes,
      suggestedName: name,
      extension: 'md',
      mimeType: 'text/markdown',
      relativeDocumentsSubdir: 'Ayutam/exports',
    );
    if (path == null) {
      return const Failure(
        AppFailure(code: 'BACKUP-CANCEL', message: 'Export cancelled.'),
      );
    }
    return Success(path);
  }

  /// SQLite snapshot export via VACUUM INTO (never copy live WAL).
  Future<Result<String>> exportSqliteSnapshot() async {
    final live = await _store.liveDatabasePath();
    if (live == null) {
      return const Failure(
        AppFailure(
          code: 'BACKUP-SQLITE',
          message: 'SQLite snapshot requires an on-disk database.',
        ),
      );
    }
    final tmpName = 'ayutam-snapshot-${_stamp.format(DateTime.now())}.sqlite';
    final dir = await _tempDirectory();
    final tmpPath = '$dir/$tmpName';
    try {
      await _store.vacuumInto(tmpPath);
      final bytes = await _store.readFileBytes(tmpPath);
      final path = await _files.saveBytes(
        bytes: bytes,
        suggestedName: tmpName,
        extension: 'sqlite',
        mimeType: 'application/x-sqlite3',
        relativeDocumentsSubdir: 'Ayutam/exports',
      );
      await _store.deleteFileIfExists(tmpPath);
      if (path == null) {
        return const Failure(
          AppFailure(code: 'BACKUP-CANCEL', message: 'Export cancelled.'),
        );
      }
      return Success(path);
    } catch (e) {
      await _store.deleteFileIfExists(tmpPath);
      return Failure(
        AppFailure(
          code: 'BACKUP-SQLITE',
          message: 'Could not create SQLite snapshot.',
          cause: e,
        ),
      );
    }
  }

  static String _csv(String value) {
    var v = value;
    if (v.startsWith('=') ||
        v.startsWith('+') ||
        v.startsWith('-') ||
        v.startsWith('@')) {
      v = "'$v";
    }
    if (v.contains(',') || v.contains('"') || v.contains('\n')) {
      return '"${v.replaceAll('"', '""')}"';
    }
    return v;
  }

  static String _formatDuration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) return '${h}h ${m}m';
    if (m > 0) return '${m}m ${s}s';
    return '${s}s';
  }
}
