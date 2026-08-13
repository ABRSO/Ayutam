import 'package:ayutam/core/id/id_generator.dart';
import 'package:ayutam/core/theme/skill_accent_palette.dart';
import 'package:ayutam/core/time/clock_service.dart';
import 'package:ayutam/database/app_database.dart';
import 'package:ayutam/features/skills/application/skill_service.dart';
import 'package:ayutam/features/skills/data/drift_skill_repository.dart';
import 'package:ayutam/features/skills/domain/skill.dart';
import 'package:ayutam/features/timer/data/drift_session_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeClockService clock;
  late AppDatabase db;
  late SkillService skills;

  setUp(() async {
    clock = FakeClockService(initialUtc: DateTime.utc(2026, 8, 13, 12));
    const ids = UuidIdGenerator();
    db = AppDatabase.memory(clock: clock, ids: ids);
    await db.ensureSeeded(clock: clock, ids: ids);
    skills = SkillService(
      skills: DriftSkillRepository(db),
      sessions: DriftSessionRepository(db),
      clock: clock,
      ids: ids,
      deviceId: () async => 'device',
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('duplicate names warn unless explicitly allowed', () async {
    expect((await skills.create(name: 'Guitar')).isSuccess, isTrue);
    final dup = await skills.create(name: 'guitar');
    expect(dup.isFailure, isTrue);
    expect(
      dup.when(success: (_) => '', failure: (f) => f.code),
      'SKILL-DUP-NAME',
    );

    final allowed = await skills.create(
      name: 'Guitar',
      allowDuplicateName: true,
    );
    expect(allowed.isSuccess, isTrue);
  });

  test('update can change accent colour', () async {
    final created = (await skills.create(name: 'Piano')).valueOrNull!;
    final next = SkillAccentPalette.colors[1];
    final updated = await skills.update(
      id: created.id,
      accentArgb: SkillAccentPalette.toArgb(next),
    );
    expect(updated.isSuccess, isTrue);
    expect(updated.valueOrNull!.accentArgb, SkillAccentPalette.toArgb(next));
  });

  test('archive then restore returns the skill to active', () async {
    final created = (await skills.create(name: 'Violin')).valueOrNull!;
    expect((await skills.archive(created.id)).isSuccess, isTrue);
    final archived = await DriftSkillRepository(db).findById(created.id);
    expect(archived!.status, SkillStatus.archived);

    expect((await skills.restore(created.id)).isSuccess, isTrue);
    final restored = await DriftSkillRepository(db).findById(created.id);
    expect(restored!.status, SkillStatus.active);
  });
}
