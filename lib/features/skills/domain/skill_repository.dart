import 'skill.dart';

/// Rewrites denormalized skill-name tokens in the session search index.
///
/// Learning Log FTS stores `skill_name` per session document, so a rename
/// must refresh those tokens or historical sessions stop matching the new
/// name. Skill code must not talk to FTS directly.
abstract class SkillSearchReindexing {
  Future<void> reindexSkillName(String skillId);
}

abstract class SkillRepository {
  Stream<List<Skill>> watchActiveSkillsWithProgress();

  Future<List<Skill>> listActiveSkillsWithProgress();

  /// Active and archived skills with progress, not soft-deleted (Home filters).
  Stream<List<Skill>> watchNonDeletedSkillsWithProgress();

  /// Active and archived skills that are not soft-deleted (no progress sums).
  Future<List<Skill>> listNonDeleted();

  Future<List<Skill>> listByIds(Iterable<String> ids);

  Future<Skill?> findById(String id);

  Future<void> insert(Skill skill);

  Future<void> update(Skill skill);

  /// Hard-deletes the skill row. Caller must cascade sessions first.
  Future<void> hardDelete(String id);
}
