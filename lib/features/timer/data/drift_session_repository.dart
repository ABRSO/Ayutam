import 'package:drift/drift.dart';

import '../../../database/app_database.dart';
import '../domain/models.dart' as domain;
import '../domain/repositories.dart';

final class DriftSessionRepository implements SessionRepository {
  DriftSessionRepository(this._db);

  final AppDatabase _db;

  @override
  Future<domain.PracticeSession?> findById(String id) async {
    final row = await (_db.select(
      _db.sessions,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return row == null ? null : _sessionToDomain(row);
  }

  @override
  Future<domain.PracticeSession?> findInProgress() async {
    final rows = await listInProgress();
    return rows.isEmpty ? null : rows.first;
  }

  @override
  Future<List<domain.PracticeSession>> listRecentCompletedForSkill(
    String skillId, {
    int limit = 5,
  }) async {
    final rows =
        await (_db.select(_db.sessions)
              ..where((t) => t.skillId.equals(skillId))
              ..where(
                (t) => t.status.equals(
                  domain.SessionStatus.completed.storageValue,
                ),
              )
              ..where((t) => t.deletedAtUtc.isNull())
              ..orderBy([(t) => OrderingTerm.desc(t.startAtUtc)])
              ..limit(limit))
            .get();
    return rows.map(_sessionToDomain).toList();
  }

  @override
  Future<List<domain.PracticeSession>> listInProgress() async {
    final rows =
        await (_db.select(_db.sessions)..where(
              (t) =>
                  t.status.isIn([
                    domain.SessionStatus.active.storageValue,
                    domain.SessionStatus.paused.storageValue,
                    domain.SessionStatus.completionPending.storageValue,
                  ]) &
                  t.deletedAtUtc.isNull(),
            ))
            .get();
    return rows.map(_sessionToDomain).toList();
  }

  @override
  Future<void> insertSession(domain.PracticeSession session) async {
    await _db.into(_db.sessions).insert(_sessionCompanion(session));
  }

  @override
  Future<void> updateSession(domain.PracticeSession session) async {
    await _db.update(_db.sessions).replace(_sessionCompanion(session));
  }

  @override
  Future<void> deleteSessionCascade(String sessionId) async {
    await (_db.delete(
      _db.sessionSegments,
    )..where((t) => t.sessionId.equals(sessionId))).go();
    await (_db.delete(_db.sessions)..where((t) => t.id.equals(sessionId))).go();
  }

  @override
  Future<List<domain.SessionSegment>> listSegments(String sessionId) async {
    final rows =
        await (_db.select(_db.sessionSegments)
              ..where((t) => t.sessionId.equals(sessionId))
              ..orderBy([(t) => OrderingTerm.asc(t.startAtUtc)]))
            .get();
    return rows.map(_segmentToDomain).toList();
  }

  @override
  Future<domain.SessionSegment?> findSegmentById(String id) async {
    final row = await (_db.select(
      _db.sessionSegments,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return row == null ? null : _segmentToDomain(row);
  }

  @override
  Future<domain.SessionSegment?> findOpenSegment(String sessionId) async {
    final row =
        await (_db.select(_db.sessionSegments)
              ..where(
                (t) => t.sessionId.equals(sessionId) & t.endAtUtc.isNull(),
              )
              ..orderBy([(t) => OrderingTerm.desc(t.startAtUtc)])
              ..limit(1))
            .getSingleOrNull();
    return row == null ? null : _segmentToDomain(row);
  }

  @override
  Future<void> insertSegment(domain.SessionSegment segment) async {
    await _db.into(_db.sessionSegments).insert(_segmentCompanion(segment));
  }

  @override
  Future<void> updateSegment(domain.SessionSegment segment) async {
    await _db.update(_db.sessionSegments).replace(_segmentCompanion(segment));
  }

  @override
  Future<void> deleteSegmentsForSession(String sessionId) async {
    await (_db.delete(
      _db.sessionSegments,
    )..where((t) => t.sessionId.equals(sessionId))).go();
  }

  @override
  Future<int> sumCompletedActiveSeconds(String skillId) async {
    final query = _db.selectOnly(_db.sessions)
      ..addColumns([_db.sessions.activeSeconds.sum()])
      ..where(_db.sessions.skillId.equals(skillId))
      ..where(
        _db.sessions.status.equals(domain.SessionStatus.completed.storageValue),
      )
      ..where(_db.sessions.deletedAtUtc.isNull());
    final row = await query.getSingle();
    return row.read(_db.sessions.activeSeconds.sum()) ?? 0;
  }

  @override
  Future<List<domain.PracticeSession>> listJournalSessions({
    Set<String>? ids,
    Set<String>? skillIds,
    DateTime? startAfterUtc,
    DateTime? endBeforeUtc,
    int? minActiveSeconds,
    int? maxActiveSeconds,
    bool? hasNote,
    String? sourceEquals,
    bool excludeManual = false,
    bool includeDeleted = false,
  }) async {
    if (ids != null && ids.isEmpty) return const [];
    final idList = ids?.toList();
    if (idList != null && idList.length > 400) {
      final out = <domain.PracticeSession>[];
      for (var i = 0; i < idList.length; i += 400) {
        final end = i + 400 > idList.length ? idList.length : i + 400;
        out.addAll(
          await listJournalSessions(
            ids: idList.sublist(i, end).toSet(),
            skillIds: skillIds,
            startAfterUtc: startAfterUtc,
            endBeforeUtc: endBeforeUtc,
            minActiveSeconds: minActiveSeconds,
            maxActiveSeconds: maxActiveSeconds,
            hasNote: hasNote,
            sourceEquals: sourceEquals,
            excludeManual: excludeManual,
            includeDeleted: includeDeleted,
          ),
        );
      }
      return out;
    }

    final query = _db.select(_db.sessions)
      ..where(
        (t) => t.status.equals(domain.SessionStatus.completed.storageValue),
      );
    _applyJournalFilters(
      query,
      ids: idList,
      skillIds: skillIds,
      startAfterUtc: startAfterUtc,
      endBeforeUtc: endBeforeUtc,
      minActiveSeconds: minActiveSeconds,
      maxActiveSeconds: maxActiveSeconds,
      hasNote: hasNote,
      sourceEquals: sourceEquals,
      excludeManual: excludeManual,
      includeDeleted: includeDeleted,
    );
    final rows = await query.get();
    return rows.map(_sessionToDomain).toList();
  }

  @override
  Future<DateTime?> firstJournalStartUtc({
    Set<String>? ids,
    Set<String>? skillIds,
    DateTime? startAfterUtc,
    DateTime? endBeforeUtc,
    int? minActiveSeconds,
    int? maxActiveSeconds,
    bool? hasNote,
    String? sourceEquals,
    bool excludeManual = false,
    bool descending = true,
  }) async {
    if (ids != null && ids.isEmpty) return null;
    DateTime? best;
    final idList = ids?.toList();
    final chunks = idList == null
        ? [null]
        : [
            for (var i = 0; i < idList.length; i += 400)
              idList.sublist(
                i,
                i + 400 > idList.length ? idList.length : i + 400,
              ),
          ];
    for (final chunk in chunks) {
      final query = _db.select(_db.sessions)
        ..where(
          (t) => t.status.equals(domain.SessionStatus.completed.storageValue),
        )
        ..orderBy([
          (t) => OrderingTerm(
            expression: t.startAtUtc,
            mode: descending ? OrderingMode.desc : OrderingMode.asc,
          ),
        ])
        ..limit(1);
      _applyJournalFilters(
        query,
        ids: chunk,
        skillIds: skillIds,
        startAfterUtc: startAfterUtc,
        endBeforeUtc: endBeforeUtc,
        minActiveSeconds: minActiveSeconds,
        maxActiveSeconds: maxActiveSeconds,
        hasNote: hasNote,
        sourceEquals: sourceEquals,
        excludeManual: excludeManual,
        includeDeleted: false,
      );
      final row = await query.getSingleOrNull();
      if (row == null) continue;
      final start = DateTime.fromMillisecondsSinceEpoch(
        row.startAtUtc,
        isUtc: true,
      );
      if (best == null) {
        best = start;
      } else if (descending && start.isAfter(best)) {
        best = start;
      } else if (!descending && start.isBefore(best)) {
        best = start;
      }
    }
    return best;
  }

  void _applyJournalFilters(
    SimpleSelectStatement<$SessionsTable, SessionRow> query, {
    List<String>? ids,
    Set<String>? skillIds,
    DateTime? startAfterUtc,
    DateTime? endBeforeUtc,
    int? minActiveSeconds,
    int? maxActiveSeconds,
    bool? hasNote,
    String? sourceEquals,
    required bool excludeManual,
    required bool includeDeleted,
  }) {
    if (!includeDeleted) {
      query.where((t) => t.deletedAtUtc.isNull());
    }
    if (ids != null) {
      query.where((t) => t.id.isIn(ids));
    }
    if (skillIds != null && skillIds.isNotEmpty) {
      query.where((t) => t.skillId.isIn(skillIds.toList()));
    }
    if (startAfterUtc != null) {
      query.where(
        (t) => t.startAtUtc.isBiggerOrEqualValue(
          startAfterUtc.millisecondsSinceEpoch,
        ),
      );
    }
    if (endBeforeUtc != null) {
      query.where(
        (t) => t.startAtUtc.isSmallerThanValue(
          endBeforeUtc.millisecondsSinceEpoch,
        ),
      );
    }
    if (minActiveSeconds != null) {
      query.where(
        (t) => t.activeSeconds.isBiggerOrEqualValue(minActiveSeconds),
      );
    }
    if (maxActiveSeconds != null) {
      query.where(
        (t) => t.activeSeconds.isSmallerOrEqualValue(maxActiveSeconds),
      );
    }
    if (hasNote == true) {
      query.where(
        (t) => t.noteMarkdown.isNotNull() & t.noteMarkdown.equals('').not(),
      );
    } else if (hasNote == false) {
      query.where((t) => t.noteMarkdown.isNull() | t.noteMarkdown.equals(''));
    }
    if (sourceEquals != null) {
      query.where((t) => t.source.equals(sourceEquals));
    }
    if (excludeManual) {
      query.where((t) => t.source.equals('manual').not());
    }
  }

  @override
  Future<List<domain.PracticeSession>> findOverlapping({
    required String skillId,
    required DateTime startAtUtc,
    required DateTime endAtUtc,
    String? excludeSessionId,
  }) async {
    final startMs = startAtUtc.millisecondsSinceEpoch;
    final endMs = endAtUtc.millisecondsSinceEpoch;
    final rows =
        await (_db.select(_db.sessions)..where((t) {
              var expr =
                  t.skillId.equals(skillId) &
                  t.deletedAtUtc.isNull() &
                  t.status.equals(domain.SessionStatus.completed.storageValue) &
                  t.endAtUtc.isNotNull() &
                  t.startAtUtc.isSmallerThanValue(endMs) &
                  t.endAtUtc.isBiggerThanValue(startMs);
              if (excludeSessionId != null) {
                expr = expr & t.id.equals(excludeSessionId).not();
              }
              return expr;
            }))
            .get();
    return rows.map(_sessionToDomain).toList();
  }

  domain.PracticeSession _sessionToDomain(SessionRow row) {
    return domain.PracticeSession(
      id: row.id,
      skillId: row.skillId,
      title: row.title,
      noteMarkdown: row.noteMarkdown,
      mode: domain.SessionMode.parse(row.mode),
      status: domain.SessionStatus.parse(row.status),
      source: row.source,
      startAtUtc: DateTime.fromMillisecondsSinceEpoch(
        row.startAtUtc,
        isUtc: true,
      ),
      endAtUtc: row.endAtUtc == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(row.endAtUtc!, isUtc: true),
      activeSeconds: row.activeSeconds,
      pausedSeconds: row.pausedSeconds,
      timezoneIdAtCreation: row.timezoneIdAtCreation,
      offsetMinutesAtStart: row.offsetMinutesAtStart,
      createdAtUtc: DateTime.fromMillisecondsSinceEpoch(
        row.createdAtUtc,
        isUtc: true,
      ),
      updatedAtUtc: DateTime.fromMillisecondsSinceEpoch(
        row.updatedAtUtc,
        isUtc: true,
      ),
      sourceDeviceId: row.sourceDeviceId,
      deletedAtUtc: row.deletedAtUtc == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(row.deletedAtUtc!, isUtc: true),
    );
  }

  SessionsCompanion _sessionCompanion(domain.PracticeSession session) {
    return SessionsCompanion.insert(
      id: session.id,
      skillId: session.skillId,
      title: Value(session.title),
      noteMarkdown: Value(session.noteMarkdown),
      mode: Value(session.mode.storageValue),
      status: session.status.storageValue,
      source: Value(session.source),
      startAtUtc: session.startAtUtc.millisecondsSinceEpoch,
      endAtUtc: Value(session.endAtUtc?.millisecondsSinceEpoch),
      activeSeconds: Value(session.activeSeconds),
      pausedSeconds: Value(session.pausedSeconds),
      timezoneIdAtCreation: session.timezoneIdAtCreation,
      offsetMinutesAtStart: session.offsetMinutesAtStart,
      createdAtUtc: session.createdAtUtc.millisecondsSinceEpoch,
      updatedAtUtc: session.updatedAtUtc.millisecondsSinceEpoch,
      sourceDeviceId: session.sourceDeviceId,
      deletedAtUtc: Value(session.deletedAtUtc?.millisecondsSinceEpoch),
    );
  }

  domain.SessionSegment _segmentToDomain(SessionSegmentRow row) {
    return domain.SessionSegment(
      id: row.id,
      sessionId: row.sessionId,
      segmentType: domain.SegmentType.parse(row.segmentType),
      pomodoroPhase: row.pomodoroPhase,
      cycleNumber: row.cycleNumber,
      startAtUtc: DateTime.fromMillisecondsSinceEpoch(
        row.startAtUtc,
        isUtc: true,
      ),
      endAtUtc: row.endAtUtc == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(row.endAtUtc!, isUtc: true),
      durationSeconds: row.durationSeconds,
      createdAtUtc: DateTime.fromMillisecondsSinceEpoch(
        row.createdAtUtc,
        isUtc: true,
      ),
      updatedAtUtc: DateTime.fromMillisecondsSinceEpoch(
        row.updatedAtUtc,
        isUtc: true,
      ),
    );
  }

  SessionSegmentsCompanion _segmentCompanion(domain.SessionSegment segment) {
    return SessionSegmentsCompanion.insert(
      id: segment.id,
      sessionId: segment.sessionId,
      segmentType: segment.segmentType.storageValue,
      pomodoroPhase: Value(segment.pomodoroPhase),
      cycleNumber: Value(segment.cycleNumber),
      startAtUtc: segment.startAtUtc.millisecondsSinceEpoch,
      endAtUtc: Value(segment.endAtUtc?.millisecondsSinceEpoch),
      durationSeconds: Value(segment.durationSeconds),
      createdAtUtc: segment.createdAtUtc.millisecondsSinceEpoch,
      updatedAtUtc: segment.updatedAtUtc.millisecondsSinceEpoch,
    );
  }
}
