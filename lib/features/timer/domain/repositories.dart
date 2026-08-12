import 'models.dart';

abstract class SessionRepository {
  Future<PracticeSession?> findById(String id);

  Future<PracticeSession?> findInProgress();

  Future<List<PracticeSession>> listInProgress();

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
  Future<List<PracticeSession>> listJournalSessions({
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
  });

  /// Earliest or latest `start_at_utc` among journal rows matching [filters].
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
