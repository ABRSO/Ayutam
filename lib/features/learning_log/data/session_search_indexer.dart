import 'package:drift/drift.dart';

import '../../../database/app_database.dart';
import '../../timer/domain/models.dart' as domain;
import 'session_date_search_text.dart';

/// Maintains the FTS5 `session_search` virtual table (ADR-017).
final class SessionSearchIndexer {
  SessionSearchIndexer(this._db);

  final AppDatabase _db;

  static const createSql = '''
CREATE VIRTUAL TABLE IF NOT EXISTS session_search USING fts5(
  session_id UNINDEXED,
  title,
  note_markdown,
  skill_name,
  tags_text,
  tokenize = 'unicode61 remove_diacritics 2'
)
''';

  Future<void> ensureCreated() => _db.customStatement(createSql);

  Future<void> upsert({
    required String sessionId,
    required String? title,
    required String? noteMarkdown,
    required String skillName,
    required String tagsText,
    String datesText = '',
  }) async {
    await delete(sessionId);
    final tagsAndDates = [
      tagsText,
      datesText,
    ].where((s) => s.trim().isNotEmpty).join(' ');
    await _db.customStatement(
      'INSERT INTO session_search '
      '(session_id, title, note_markdown, skill_name, tags_text) '
      'VALUES (?, ?, ?, ?, ?)',
      [sessionId, title ?? '', noteMarkdown ?? '', skillName, tagsAndDates],
    );
  }

  Future<void> delete(String sessionId) async {
    await _db.customStatement(
      'DELETE FROM session_search WHERE session_id = ?',
      [sessionId],
    );
  }

  /// Rebuilds the entire FTS index from completed / completion_pending sessions.
  Future<void> rebuildAll() async {
    await _db.customStatement('DELETE FROM session_search');
    final rows = await _db
        .customSelect(
          '''
SELECT
  s.id AS session_id,
  IFNULL(s.title, '') AS title,
  IFNULL(s.note_markdown, '') AS note_markdown,
  sk.name AS skill_name,
  IFNULL((
    SELECT GROUP_CONCAT(t.name, ' ')
    FROM session_tags st
    INNER JOIN tags t ON t.id = st.tag_id
    WHERE st.session_id = s.id
  ), '') AS tags_text,
  s.start_at_utc AS start_at_utc,
  s.end_at_utc AS end_at_utc,
  s.offset_minutes_at_start AS offset_minutes
FROM sessions s
INNER JOIN skills sk ON sk.id = s.skill_id
WHERE s.deleted_at_utc IS NULL
  AND s.status IN ('completed', 'completion_pending')
''',
          readsFrom: {_db.sessions, _db.skills, _db.sessionTags, _db.tags},
        )
        .get();

    for (final row in rows) {
      final startMs = row.read<int>('start_at_utc');
      final endMs = row.readNullable<int>('end_at_utc');
      final datesText = sessionDateSearchText(
        startAtUtc: DateTime.fromMillisecondsSinceEpoch(startMs, isUtc: true),
        offsetMinutesAtStart: row.read<int>('offset_minutes'),
        endAtUtc: endMs == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(endMs, isUtc: true),
      );
      await upsert(
        sessionId: row.read<String>('session_id'),
        title: row.read<String>('title'),
        noteMarkdown: row.read<String>('note_markdown'),
        skillName: row.read<String>('skill_name'),
        tagsText: row.read<String>('tags_text'),
        datesText: datesText,
      );
    }
  }

  /// Returns session IDs matching an FTS MATCH query (empty query → no filter).
  Future<List<String>> searchSessionIds(String rawQuery) async {
    final q = ftsQuery(rawQuery);
    if (q == null) return const [];
    final rows = await _db
        .customSelect(
          'SELECT session_id FROM session_search WHERE session_search MATCH ?',
          variables: [Variable.withString(q)],
          readsFrom: {},
        )
        .get();
    return rows.map((r) => r.read<String>('session_id')).toList();
  }

  /// Indexes one session by loading skill name + tags from the live DB.
  Future<void> indexSession(domain.PracticeSession session) async {
    final skill = await (_db.select(
      _db.skills,
    )..where((t) => t.id.equals(session.skillId))).getSingleOrNull();
    final tagRows = await _db
        .customSelect(
          '''
SELECT t.name AS name
FROM session_tags st
INNER JOIN tags t ON t.id = st.tag_id
WHERE st.session_id = ?
ORDER BY t.normalized_name
''',
          variables: [Variable.withString(session.id)],
          readsFrom: {_db.sessionTags, _db.tags},
        )
        .get();
    final tagsText = tagRows.map((r) => r.read<String>('name')).join(' ');
    await upsert(
      sessionId: session.id,
      title: session.title,
      noteMarkdown: session.noteMarkdown,
      skillName: skill?.name ?? '',
      tagsText: tagsText,
      datesText: sessionDateSearchText(
        startAtUtc: session.startAtUtc,
        offsetMinutesAtStart: session.offsetMinutesAtStart,
        endAtUtc: session.endAtUtc,
      ),
    );
  }

  /// Turns user text into a safe FTS5 MATCH expression (AND of prefix terms).
  ///
  /// Preserves Unicode letters. ISO dates become compact `yyyyMMdd` tokens.
  static String? ftsQuery(String raw) {
    final tokens = raw
        .trim()
        .split(RegExp(r'\s+'))
        .map(_normalizeFtsToken)
        .where((t) => t.isNotEmpty)
        .toList();
    if (tokens.isEmpty) return null;
    return tokens
        .map((t) {
          final escaped = t.replaceAll('"', '""');
          return '"$escaped"*';
        })
        .join(' ');
  }

  static String _normalizeFtsToken(String raw) {
    var token = raw.trim().toLowerCase();
    final iso = RegExp(r'^(\d{4})[-/](\d{1,2})[-/](\d{1,2})$');
    final isoMatch = iso.firstMatch(token);
    if (isoMatch != null) {
      final y = isoMatch[1]!;
      final m = isoMatch[2]!.padLeft(2, '0');
      final d = isoMatch[3]!.padLeft(2, '0');
      return '$y$m$d';
    }
    token = token.replaceAll('"', '').replaceAll('*', '');
    token = token.replaceAll(RegExp(r'^[-^+:]+'), '');
    token = token.replaceAll(RegExp(r'^[^\p{L}\p{N}_]+', unicode: true), '');
    token = token.replaceAll(RegExp(r'[^\p{L}\p{N}_]+$', unicode: true), '');
    return token;
  }
}
