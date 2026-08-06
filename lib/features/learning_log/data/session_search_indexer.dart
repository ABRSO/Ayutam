import 'package:drift/drift.dart';

import '../../../database/app_database.dart';
import '../../timer/domain/models.dart' as domain;

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
  }) async {
    await delete(sessionId);
    await _db.customStatement(
      'INSERT INTO session_search '
      '(session_id, title, note_markdown, skill_name, tags_text) '
      'VALUES (?, ?, ?, ?, ?)',
      [sessionId, title ?? '', noteMarkdown ?? '', skillName, tagsText],
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
  ), '') AS tags_text
FROM sessions s
INNER JOIN skills sk ON sk.id = s.skill_id
WHERE s.deleted_at_utc IS NULL
  AND s.status IN ('completed', 'completion_pending')
''',
          readsFrom: {_db.sessions, _db.skills, _db.sessionTags, _db.tags},
        )
        .get();

    for (final row in rows) {
      await _db.customStatement(
        'INSERT INTO session_search '
        '(session_id, title, note_markdown, skill_name, tags_text) '
        'VALUES (?, ?, ?, ?, ?)',
        [
          row.read<String>('session_id'),
          row.read<String>('title'),
          row.read<String>('note_markdown'),
          row.read<String>('skill_name'),
          row.read<String>('tags_text'),
        ],
      );
    }
  }

  /// Returns session IDs matching an FTS MATCH query (empty query → no filter).
  Future<List<String>> searchSessionIds(String rawQuery) async {
    final q = _ftsQuery(rawQuery);
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
    );
  }

  /// Turns user text into a safe FTS5 MATCH expression (AND of prefix terms).
  static String? _ftsQuery(String raw) {
    final tokens = raw
        .trim()
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .map((t) => t.replaceAll(RegExp(r'[^a-z0-9_\-]'), ''))
        .where((t) => t.isNotEmpty)
        .toList();
    if (tokens.isEmpty) return null;
    return tokens.map((t) => '$t*').join(' ');
  }
}
