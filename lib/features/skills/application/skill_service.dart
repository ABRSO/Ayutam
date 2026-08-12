import '../../../core/constants/app_constants.dart';
import '../../../core/id/id_generator.dart';
import '../../../core/result/result.dart';
import '../../../core/theme/skill_accent_palette.dart';
import '../../../core/time/clock_service.dart';
import '../../timer/domain/repositories.dart';
import '../domain/skill.dart';
import '../domain/skill_repository.dart';

final class SkillService {
  SkillService({
    required SkillRepository skills,
    required SessionRepository sessions,
    required ClockService clock,
    required IdGenerator ids,
    required Future<String> Function() deviceId,
  }) : _skills = skills,
       _sessions = sessions,
       _clock = clock,
       _ids = ids,
       _deviceId = deviceId;

  final SkillRepository _skills;
  final SessionRepository _sessions;
  final ClockService _clock;
  final IdGenerator _ids;
  final Future<String> Function() _deviceId;

  Stream<List<Skill>> watchActive() => _skills.watchActiveSkillsWithProgress();

  Future<List<Skill>> listActive() => _skills.listActiveSkillsWithProgress();

  /// Active + archived, not soft-deleted. For Learning Log filters and session edit.
  Future<List<Skill>> listForJournal() => _skills.listNonDeleted();

  Future<Result<Skill>> create({
    required String name,
    int? targetSeconds,
    String? descriptionMarkdown,
    String? createdLocalDate,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return const Failure(
        AppFailure(code: 'VAL-NAME', message: 'Skill name is required.'),
      );
    }
    final target = targetSeconds ?? AppConstants.defaultTargetSeconds;
    if (target <= 0) {
      return const Failure(
        AppFailure(
          code: 'VAL-TARGET',
          message: 'Target hours must be greater than zero.',
        ),
      );
    }
    final now = _clock.nowUtc();
    final local = now.toLocal();
    final defaultLocalDate =
        '${local.year.toString().padLeft(4, '0')}-'
        '${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')}';
    final localDate = (createdLocalDate?.trim().isNotEmpty == true)
        ? createdLocalDate!.trim()
        : defaultLocalDate;
    if (!_isValidLocalDate(localDate)) {
      return const Failure(
        AppFailure(
          code: 'VAL-DATE',
          message: 'Creation date must be a valid YYYY-MM-DD date.',
        ),
      );
    }
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
      targetSeconds: target,
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
    String? createdLocalDate,
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
          message: 'Target hours must be greater than zero.',
        ),
      );
    }
    final localDate = createdLocalDate?.trim();
    if (localDate != null &&
        localDate.isNotEmpty &&
        !_isValidLocalDate(localDate)) {
      return const Failure(
        AppFailure(
          code: 'VAL-DATE',
          message: 'Creation date must be a valid YYYY-MM-DD date.',
        ),
      );
    }
    final desc = descriptionMarkdown?.trim();
    final updated = existing.copyWith(
      name: trimmed,
      targetSeconds: targetSeconds,
      descriptionMarkdown: (desc == null || desc.isEmpty) ? null : desc,
      clearDescription: desc != null && desc.isEmpty,
      createdLocalDate: (localDate == null || localDate.isEmpty)
          ? null
          : localDate,
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
    final inProgress = await _sessions.listInProgress();
    if (inProgress.any((session) => session.skillId == id)) {
      return const Failure(
        AppFailure(
          code: 'SKILL-BUSY',
          message:
              'Stop the active session for this skill before archiving it.',
        ),
      );
    }
    final updated = existing.copyWith(
      status: SkillStatus.archived,
      updatedAtUtc: _clock.nowUtc(),
    );
    await _skills.update(updated);
    return Success(updated);
  }

  Future<Result<Skill>> restore(String id) async {
    final existing = await _skills.findById(id);
    if (existing == null) {
      return const Failure(
        AppFailure(code: 'SKILL-404', message: 'Skill not found.'),
      );
    }
    if (existing.status == SkillStatus.active) {
      return Success(existing);
    }
    final updated = existing.copyWith(
      status: SkillStatus.active,
      updatedAtUtc: _clock.nowUtc(),
    );
    await _skills.update(updated);
    return Success(updated);
  }

  static bool _isValidLocalDate(String value) {
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(value);
    if (match == null) {
      return false;
    }
    final year = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    final day = int.parse(match.group(3)!);
    final parsed = DateTime(year, month, day);
    return parsed.year == year && parsed.month == month && parsed.day == day;
  }
}
