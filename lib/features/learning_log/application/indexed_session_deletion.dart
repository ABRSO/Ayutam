import '../../timer/domain/repositories.dart';
import '../data/session_search_indexer.dart';

/// Application-level hard delete: drop the FTS document, then the session.
final class IndexedSessionDeletion implements PermanentSessionDeletion {
  IndexedSessionDeletion({
    required SessionRepository sessions,
    required SessionSearchIndexer indexer,
  }) : _sessions = sessions,
       _indexer = indexer;

  final SessionRepository _sessions;
  final SessionSearchIndexer _indexer;

  @override
  Future<void> delete(String sessionId) async {
    await _indexer.delete(sessionId);
    await _sessions.deleteSessionCascade(sessionId);
  }
}
