import '../../timer/domain/repositories.dart';
import '../data/session_search_indexer.dart';

/// Application-level FTS upsert for sessions completed outside the
/// completion panel (stop-and-start save, orphan force-complete).
final class IndexedSessionCompletion implements CompletedSessionIndexing {
  IndexedSessionCompletion({
    required SessionRepository sessions,
    required SessionSearchIndexer indexer,
  }) : _sessions = sessions,
       _indexer = indexer;

  final SessionRepository _sessions;
  final SessionSearchIndexer _indexer;

  @override
  Future<void> indexSession(String sessionId) async {
    final session = await _sessions.findById(sessionId);
    if (session == null) {
      return;
    }
    await _indexer.indexSession(session);
  }
}
