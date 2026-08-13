import 'skill.dart';

abstract class SkillRepository {
  Stream<List<Skill>> watchActiveSkillsWithProgress();

  Future<List<Skill>> listActiveSkillsWithProgress();

  /// Active and archived skills that are not soft-deleted (no progress sums).
  Future<List<Skill>> listNonDeleted();

  Future<List<Skill>> listByIds(Iterable<String> ids);

  Future<Skill?> findById(String id);

  Future<void> insert(Skill skill);

  Future<void> update(Skill skill);
}
