import 'skill.dart';

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
}
