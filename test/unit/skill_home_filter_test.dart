import 'package:ayutam/features/skills/domain/skill.dart';
import 'package:ayutam/features/skills/presentation/skill_home_filter.dart';
import 'package:flutter_test/flutter_test.dart';

Skill _skill({
  required String id,
  required String name,
  required SkillStatus status,
  int completed = 0,
  int target = 3600,
}) {
  final now = DateTime.utc(2026, 8, 13);
  return Skill(
    id: id,
    name: name,
    targetSeconds: target,
    createdLocalDate: '2026-08-13',
    status: status,
    sortOrder: 0,
    createdAtUtc: now,
    updatedAtUtc: now,
    sourceDeviceId: 'dev',
    completedActiveSeconds: completed,
  );
}

void main() {
  final inProgress = _skill(
    id: 'a',
    name: 'In-progress Piano',
    status: SkillStatus.active,
  );
  final done = _skill(
    id: 'b',
    name: 'Done Guitar',
    status: SkillStatus.active,
    completed: 3600,
  );
  final archived = _skill(
    id: 'c',
    name: 'Old Flute',
    status: SkillStatus.archived,
    completed: 4000,
  );
  final all = [inProgress, done, archived];

  test('Home filters split in-progress, completed, and archived', () {
    expect(skillsForHomeFilter(all, SkillHomeFilter.inProgress), [inProgress]);
    expect(skillsForHomeFilter(all, SkillHomeFilter.completed), [done]);
    expect(skillsForHomeFilter(all, SkillHomeFilter.archived), [archived]);
  });

  test('name search is case-insensitive', () {
    expect(skillsMatchingQuery(all, 'piano').single.id, 'a');
    expect(skillsMatchingQuery(all, '  GUITAR ').single.id, 'b');
  });
}
