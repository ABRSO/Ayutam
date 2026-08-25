import '../../../core/result/result.dart';
import '../../backup/domain/backup_models.dart';
import '../../timer/domain/repositories.dart';
import '../domain/skill_repository.dart';

/// Session count / duration shown before irreversible skill delete.
final class SkillDeletionImpact {
  const SkillDeletionImpact({
    required this.sessionCount,
    required this.totalActiveSeconds,
  });

  final int sessionCount;
  final int totalActiveSeconds;
}

/// Permanent skill delete with safety snapshot + session cascade (Phase 5).
final class PermanentSkillDeletion {
  PermanentSkillDeletion({
    required SkillRepository skills,
    required SessionRepository sessions,
    required PermanentSessionDeletion sessionDeletion,
    required UnitOfWork uow,
    required Future<Result<LocalSnapshotInfo>> Function({
      required String reason,
    })
    createSafetySnapshot,
  }) : _skills = skills,
       _sessions = sessions,
       _sessionDeletion = sessionDeletion,
       _uow = uow,
       _createSafetySnapshot = createSafetySnapshot;

  final SkillRepository _skills;
  final SessionRepository _sessions;
  final PermanentSessionDeletion _sessionDeletion;
  final UnitOfWork _uow;
  final Future<Result<LocalSnapshotInfo>> Function({required String reason})
  _createSafetySnapshot;

  Future<SkillDeletionImpact> impact(String skillId) async {
    final sessions = await _sessions.listJournalSessions(
      skillIds: {skillId},
      includeDeleted: false,
    );
    final total = sessions.fold<int>(0, (sum, s) => sum + s.activeSeconds);
    return SkillDeletionImpact(
      sessionCount: sessions.length,
      totalActiveSeconds: total,
    );
  }

  Future<Result<void>> deletePermanently({
    required String skillId,
    required String typedName,
  }) async {
    final skill = await _skills.findById(skillId);
    if (skill == null) {
      return const Failure(
        AppFailure(code: 'SKILL-404', message: 'Skill not found.'),
      );
    }
    if (typedName != skill.name) {
      return const Failure(
        AppFailure(
          code: 'SKILL-CONFIRM',
          message: 'Typed name does not match the skill name.',
        ),
      );
    }

    final inProgress = await _sessions.listInProgress();
    if (inProgress.any((s) => s.skillId == skillId)) {
      return const Failure(
        AppFailure(
          code: 'SKILL-BUSY',
          message: 'Stop the active session for this skill before deleting it.',
        ),
      );
    }

    final snap = await _createSafetySnapshot(reason: 'pre_skill_delete');
    if (snap is Failure<LocalSnapshotInfo>) {
      return Failure(snap.error);
    }

    final sessionIds = await _sessions.listIdsForSkill(skillId);

    try {
      await _uow.write(() async {
        for (final sessionId in sessionIds) {
          await _sessionDeletion.delete(sessionId);
        }
        await _skills.hardDelete(skillId);
      });
      return const Success(null);
    } catch (e) {
      return Failure(
        AppFailure(
          code: 'SKILL-DELETE',
          message: 'Could not delete the skill. A safety snapshot was created.',
          cause: e,
        ),
      );
    }
  }
}
