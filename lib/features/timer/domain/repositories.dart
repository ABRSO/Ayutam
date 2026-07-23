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

  Future<int> sumCompletedActiveSeconds(String skillId);
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
