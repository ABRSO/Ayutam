import 'statistics_models.dart';

/// Read-only statistics feed over completed, non-deleted sessions.
///
/// Implemented by the data layer; the application layer must stay free of
/// Drift so aggregation is testable with plain fixtures.
abstract class StatisticsSource {
  /// Closed `work` segments of completed sessions, oldest first.
  Future<List<WorkSlice>> completedWorkSlices({Set<String>? skillIds});

  /// Completed sessions (id-free stats projection), oldest first.
  Future<List<CompletedSessionStat>> completedSessions({Set<String>? skillIds});

  /// Emits when sessions change so cached aggregates can reload.
  Stream<void> watchChanges();
}
