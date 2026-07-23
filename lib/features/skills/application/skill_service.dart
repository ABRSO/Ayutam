import '../../../core/constants/app_constants.dart';
import '../../../core/id/id_generator.dart';
import '../../../core/result/result.dart';
import '../../../core/theme/skill_accent_palette.dart';
import '../../../core/time/clock_service.dart';
import '../domain/skill.dart';
import '../domain/skill_repository.dart';

final class SkillService {
  SkillService({
    required SkillRepository skills,
    required ClockService clock,
    required IdGenerator ids,
    required Future<String> Function() deviceId,
  }) : _skills = skills,
       _clock = clock,
       _ids = ids,
       _deviceId = deviceId;

  final SkillRepository _skills;
  final ClockService _clock;
  final IdGenerator _ids;
  final Future<String> Function() _deviceId;

  Stream<List<Skill>> watchActive() => _skills.watchActiveSkillsWithProgress();

  Future<List<Skill>> listActive() => _skills.listActiveSkillsWithProgress();

  Future<Result<Skill>> create({
    required String name,
    int? targetSeconds,
    String? descriptionMarkdown,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return const Failure(
        AppFailure(code: 'VAL-NAME', message: 'Skill name is required.'),
      );
    }
    final now = _clock.nowUtc();
    final local = now.toLocal();
    final localDate =
        '${local.year.toString().padLeft(4, '0')}-'
        '${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')}';
    final existing = await _skills.listActiveSkillsWithProgress();
    final accent = SkillAccentPalette.nextAccent(
      existing.map((s) => s.accentArgb),
    );
    final skill = Skill(
      id: _ids.v4(),
      name: trimmed,
      descriptionMarkdown: descriptionMarkdown?.trim().isEmpty == true
          ? null
          : descriptionMarkdown?.trim(),
      targetSeconds: targetSeconds ?? AppConstants.defaultTargetSeconds,
      createdLocalDate: localDate,
      accentArgb: SkillAccentPalette.toArgb(accent),
      status: SkillStatus.active,
      sortOrder: 0,
      createdAtUtc: now,
      updatedAtUtc: now,
      sourceDeviceId: await _deviceId(),
    );
    await _skills.insert(skill);
    return Success(skill);
  }

  Future<Result<Skill>> update({
    required String id,
    String? name,
    int? targetSeconds,
    String? descriptionMarkdown,
  }) async {
    final existing = await _skills.findById(id);
    if (existing == null) {
      return const Failure(
        AppFailure(code: 'SKILL-404', message: 'Skill not found.'),
      );
    }
    final trimmed = name?.trim();
    if (trimmed != null && trimmed.isEmpty) {
      return const Failure(
        AppFailure(code: 'VAL-NAME', message: 'Skill name is required.'),
      );
    }
    if (targetSeconds != null && targetSeconds <= 0) {
      return const Failure(
        AppFailure(
          code: 'VAL-TARGET',
          message: 'Target seconds must be positive.',
        ),
      );
    }
    final updated = existing.copyWith(
      name: trimmed,
      targetSeconds: targetSeconds,
      descriptionMarkdown: descriptionMarkdown,
      updatedAtUtc: _clock.nowUtc(),
    );
    await _skills.update(updated);
    return Success(updated);
  }

  Future<Result<Skill>> archive(String id) async {
    final existing = await _skills.findById(id);
    if (existing == null) {
      return const Failure(
        AppFailure(code: 'SKILL-404', message: 'Skill not found.'),
      );
    }
    if (existing.status == SkillStatus.archived) {
      return Success(existing);
    }
    final updated = existing.copyWith(
      status: SkillStatus.archived,
      updatedAtUtc: _clock.nowUtc(),
    );
    await _skills.update(updated);
    return Success(updated);
  }
}
