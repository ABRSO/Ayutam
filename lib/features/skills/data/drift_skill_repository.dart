import 'package:drift/drift.dart';

import '../../../database/app_database.dart';
import '../domain/skill.dart' as domain;
import '../domain/skill_repository.dart';

final class DriftSkillRepository implements SkillRepository {
  DriftSkillRepository(this._db);

  final AppDatabase _db;

  @override
  Stream<List<domain.Skill>> watchActiveSkillsWithProgress() {
    final query = _db.select(_db.skills)
      ..where((t) => t.status.equals(domain.SkillStatus.active.storageValue))
      ..where((t) => t.deletedAtUtc.isNull())
      ..orderBy([
        (t) => OrderingTerm.asc(t.sortOrder),
        (t) => OrderingTerm.asc(t.name),
      ]);

    return query.watch().asyncMap((rows) async {
      final skills = <domain.Skill>[];
      for (final row in rows) {
        skills.add(_toDomain(row, await _sumCompleted(row.id)));
      }
      return skills;
    });
  }

  @override
  Future<List<domain.Skill>> listActiveSkillsWithProgress() async {
    final rows =
        await (_db.select(_db.skills)
              ..where(
                (t) => t.status.equals(domain.SkillStatus.active.storageValue),
              )
              ..where((t) => t.deletedAtUtc.isNull())
              ..orderBy([
                (t) => OrderingTerm.asc(t.sortOrder),
                (t) => OrderingTerm.asc(t.name),
              ]))
            .get();
    final skills = <domain.Skill>[];
    for (final row in rows) {
      skills.add(_toDomain(row, await _sumCompleted(row.id)));
    }
    return skills;
  }

  @override
  Future<domain.Skill?> findById(String id) async {
    final row = await (_db.select(
      _db.skills,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    if (row == null) {
      return null;
    }
    return _toDomain(row, await _sumCompleted(row.id));
  }

  @override
  Future<void> insert(domain.Skill skill) async {
    await _db.into(_db.skills).insert(_toCompanion(skill));
  }

  @override
  Future<void> update(domain.Skill skill) async {
    await _db.update(_db.skills).replace(_toCompanion(skill));
  }

  Future<int> _sumCompleted(String skillId) async {
    final query = _db.selectOnly(_db.sessions)
      ..addColumns([_db.sessions.activeSeconds.sum()])
      ..where(_db.sessions.skillId.equals(skillId))
      ..where(_db.sessions.status.equals('completed'))
      ..where(_db.sessions.deletedAtUtc.isNull());
    final row = await query.getSingle();
    return row.read(_db.sessions.activeSeconds.sum()) ?? 0;
  }

  domain.Skill _toDomain(SkillRow row, int progress) {
    return domain.Skill(
      id: row.id,
      name: row.name,
      descriptionMarkdown: row.descriptionMarkdown,
      targetSeconds: row.targetSeconds,
      createdLocalDate: row.createdLocalDate,
      accentArgb: row.accentArgb,
      status: domain.SkillStatus.parse(row.status),
      sortOrder: row.sortOrder,
      createdAtUtc: DateTime.fromMillisecondsSinceEpoch(
        row.createdAtUtc,
        isUtc: true,
      ),
      updatedAtUtc: DateTime.fromMillisecondsSinceEpoch(
        row.updatedAtUtc,
        isUtc: true,
      ),
      sourceDeviceId: row.sourceDeviceId,
      deletedAtUtc: row.deletedAtUtc == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(row.deletedAtUtc!, isUtc: true),
      completedActiveSeconds: progress,
    );
  }

  SkillsCompanion _toCompanion(domain.Skill skill) {
    return SkillsCompanion.insert(
      id: skill.id,
      name: skill.name,
      descriptionMarkdown: Value(skill.descriptionMarkdown),
      targetSeconds: Value(skill.targetSeconds),
      createdLocalDate: skill.createdLocalDate,
      accentArgb: Value(skill.accentArgb),
      status: Value(skill.status.storageValue),
      sortOrder: Value(skill.sortOrder),
      createdAtUtc: skill.createdAtUtc.millisecondsSinceEpoch,
      updatedAtUtc: skill.updatedAtUtc.millisecondsSinceEpoch,
      sourceDeviceId: skill.sourceDeviceId,
      deletedAtUtc: Value(skill.deletedAtUtc?.millisecondsSinceEpoch),
    );
  }
}
