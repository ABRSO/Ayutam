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
