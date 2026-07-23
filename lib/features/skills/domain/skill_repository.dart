import 'skill.dart';

abstract class SkillRepository {
  Stream<List<Skill>> watchActiveSkillsWithProgress();

  Future<List<Skill>> listActiveSkillsWithProgress();

  Future<Skill?> findById(String id);

  Future<void> insert(Skill skill);

  Future<void> update(Skill skill);
}
