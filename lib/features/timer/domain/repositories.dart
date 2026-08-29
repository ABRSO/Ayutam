import 'models.dart';

abstract class SessionRepository {
  Future<PracticeSession?> findById(String id);

  Future<PracticeSession?> findInProgress();

  Future<List<PracticeSession>> listInProgress();

  /// All session ids for [skillId] (any status, including soft-deleted).
  Future<List<String>> listIdsForSkill(String skillId);

  /// Newest completed sessions for a skill (Home card expand).
  Future<List<PracticeSession>> listRecentCompletedForSkill(
    String skillId, {
    int limit = 5,
  });

  Future<void> insertSession(PracticeSession session);

  Future<void> updateSession(PracticeSession session);

  Future<void> deleteSessionCascade(String sessionId);

  Future<List<SessionSegment>> listSegments(String sessionId);

  Future<SessionSegment?> findSegmentById(String id);

  Future<SessionSegment?> findOpenSegment(String sessionId);

  Future<void> insertSegment(SessionSegment segment);

  Future<void> updateSegment(SessionSegment segment);

  Future<void> deleteSegmentsForSession(String sessionId);

  Future<int> sumCompletedActiveSeconds(String skillId);

  /// Completed (and optionally soft-deleted) sessions for Learning Log.
  ///
  /// [startAfterUtc]/[endBeforeUtc] match session start times (month paging /
  /// From–To). [overlapStartUtc]/[overlapEndUtc] match sessions *active*
  /// during the window (heatmap day link, cross-midnight aware). When overlap
  /// bounds are set, start-based bounds are ignored so the two modes never
  /// AND together.
  Future<List<PracticeSession>> listJournalSessions({
    Set<String>? ids,
    Set<String>? skillIds,
    DateTime? startAfterUtc,
    DateTime? endBeforeUtc,
    DateTime? overlapStartUtc,
    DateTime? overlapEndUtc,
    int? minActiveSeconds,
    int? maxActiveSeconds,
    bool? hasNote,
    String? sourceEquals,
    bool excludeManual = false,
    bool includeDeleted = false,
  });

  /// Earliest or latest `start_at_utc` among journal rows matching [filters].
  Future<DateTime?> firstJournalStartUtc({
    Set<String>? ids,
    Set<String>? skillIds,
    DateTime? startAfterUtc,
    DateTime? endBeforeUtc,
    DateTime? overlapStartUtc,
    DateTime? overlapEndUtc,
    int? minActiveSeconds,
    int? maxActiveSeconds,
    bool? hasNote,
    String? sourceEquals,
    bool excludeManual = false,
    bool descending = true,
  });

  /// Sessions for [skillId] whose [start,end] overlaps [startAt,endAt].
  Future<List<PracticeSession>> findOverlapping({
    required String skillId,
    required DateTime startAtUtc,
    required DateTime endAtUtc,
    String? excludeSessionId,
  });
}

abstract class TimerRuntimeRepository {
  Future<TimerRuntimeState> get();

  Future<void> save(TimerRuntimeState state);

  Future<void> clearToIdle({required DateTime updatedAtUtc});
}

/// Runs [action] inside a single write transaction.
abstract class UnitOfWork {
  Future<T> write<T>(Future<T> Function() action);
}

/// Hard-deletes a session and dependent rows (segments, FTS).
///
/// Call only from inside an existing [UnitOfWork] write so FTS and SQL
/// stay in one transaction. Timer code must not talk to FTS directly.
abstract class PermanentSessionDeletion {
  Future<void> delete(String sessionId);
}

/// Upserts the FTS document for a session that just became `completed`.
///
/// Covers completions that bypass the completion panel (stop-and-start save,
/// startup force-complete of extra orphans). Call only from inside an
/// existing [UnitOfWork] write; timer code must not talk to FTS directly.
abstract class CompletedSessionIndexing {
  Future<void> indexSession(String sessionId);
}
