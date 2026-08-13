import '../domain/skill.dart';

/// Home list chips: In Progress / Completed / Archived ([product-spec] §2.2).
///
/// "In Progress" is a derived target-progress view. The persisted lifecycle
/// remains [SkillStatus.active] until the user archives the skill.
enum SkillHomeFilter { inProgress, completed, archived }

List<Skill> skillsForHomeFilter(List<Skill> skills, SkillHomeFilter filter) {
  return switch (filter) {
    SkillHomeFilter.inProgress =>
      skills
          .where(
            (skill) =>
                skill.status == SkillStatus.active && !skill.hasReachedTarget,
          )
          .toList(),
    SkillHomeFilter.completed =>
      skills
          .where(
            (skill) =>
                skill.status == SkillStatus.active && skill.hasReachedTarget,
          )
          .toList(),
    SkillHomeFilter.archived =>
      skills.where((skill) => skill.status == SkillStatus.archived).toList(),
  };
}

List<Skill> skillsMatchingQuery(List<Skill> skills, String query) {
  final needle = query.trim().toLowerCase();
  if (needle.isEmpty) {
    return skills;
  }
  return skills
      .where((skill) => skill.name.toLowerCase().contains(needle))
      .toList();
}
