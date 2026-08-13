import 'package:drift/drift.dart';

import '../../../database/app_database.dart';
import '../domain/statistics_models.dart';
import '../domain/statistics_source.dart';

/// Drift feed over completed, non-deleted sessions and their work segments.
final class DriftStatisticsSource implements StatisticsSource {
  DriftStatisticsSource(this._db);

  final AppDatabase _db;

  @override
  Future<List<WorkSlice>> completedWorkSlices({Set<String>? skillIds}) async {
    final rows = await _db
        .customSelect(
          '''
SELECT s.skill_id AS skill_id,
       g.start_at_utc AS start_at_utc,
       g.end_at_utc AS end_at_utc
FROM session_segments g
INNER JOIN sessions s ON s.id = g.session_id
WHERE g.segment_type = 'work'
  AND g.end_at_utc IS NOT NULL
  AND s.status = 'completed'
  AND s.deleted_at_utc IS NULL
  ${_skillFilter(skillIds, 's')}
ORDER BY g.start_at_utc
''',
          variables: [
            for (final id in skillIds ?? const <String>{})
              Variable.withString(id),
          ],
          readsFrom: {_db.sessionSegments, _db.sessions},
        )
        .get();
    return [
      for (final row in rows)
        WorkSlice(
          skillId: row.read<String>('skill_id'),
          startAtUtc: DateTime.fromMillisecondsSinceEpoch(
            row.read<int>('start_at_utc'),
            isUtc: true,
          ),
          endAtUtc: DateTime.fromMillisecondsSinceEpoch(
            row.read<int>('end_at_utc'),
            isUtc: true,
          ),
        ),
    ];
  }

  @override
  Future<List<CompletedSessionStat>> completedSessions({
    Set<String>? skillIds,
  }) async {
    final rows = await _db
        .customSelect(
          '''
SELECT skill_id, start_at_utc, end_at_utc, active_seconds
FROM sessions s
WHERE s.status = 'completed'
  AND s.deleted_at_utc IS NULL
  ${_skillFilter(skillIds, 's')}
ORDER BY start_at_utc
''',
          variables: [
            for (final id in skillIds ?? const <String>{})
              Variable.withString(id),
          ],
          readsFrom: {_db.sessions},
        )
        .get();
    return [
      for (final row in rows)
        CompletedSessionStat(
          skillId: row.read<String>('skill_id'),
          startAtUtc: DateTime.fromMillisecondsSinceEpoch(
            row.read<int>('start_at_utc'),
            isUtc: true,
          ),
          endAtUtc: row.readNullable<int>('end_at_utc') == null
              ? null
              : DateTime.fromMillisecondsSinceEpoch(
                  row.read<int>('end_at_utc'),
                  isUtc: true,
                ),
          activeSeconds: row.read<int>('active_seconds'),
        ),
    ];
  }

  @override
  Stream<void> watchChanges() {
    // Cheap trigger: session writes and skill edits (target/name feed the
    // summary card, goal line, and projection) both bump this.
    return _db
        .customSelect(
          'SELECT (SELECT COUNT(*) FROM sessions) AS c, '
          '(SELECT IFNULL(MAX(updated_at_utc), 0) FROM sessions) AS m, '
          '(SELECT IFNULL(MAX(updated_at_utc), 0) FROM skills) AS sm',
          readsFrom: {_db.sessions, _db.skills},
        )
        .watch()
        .map((_) {});
  }

  static String _skillFilter(Set<String>? skillIds, String alias) {
    if (skillIds == null || skillIds.isEmpty) return '';
    final placeholders = List.filled(skillIds.length, '?').join(', ');
    return 'AND $alias.skill_id IN ($placeholders)';
  }
}
