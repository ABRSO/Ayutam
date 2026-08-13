import '../../skills/domain/skill_repository.dart';
import '../data/session_search_indexer.dart';

/// Keeps FTS `skill_name` tokens in sync when a skill is renamed.
final class IndexedSkillRename implements SkillSearchReindexing {
  IndexedSkillRename(this._indexer);

  final SessionSearchIndexer _indexer;

  @override
  Future<void> reindexSkillName(String skillId) =>
      _indexer.updateSkillName(skillId);
}
