import '../../../core/result/result.dart';
import '../domain/backup_models.dart';

final _uuidRe = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
);

const _sessionStatuses = {
  'active',
  'paused',
  'completion_pending',
  'completed',
};
const _segmentTypes = {'work', 'pause', 'pomodoro_break'};
const _skillStatuses = {'active', 'archived'};
const _modes = {'stopwatch', 'pomodoro', 'manual'};

/// Semantic validation of a decoded portable backup payload.
Result<void> validateBackupPayload(BackupPayload payload) {
  if (payload.dataVersion < 1) {
    return const Failure(
      AppFailure(
        code: 'BACKUP-DATA-VER',
        message: 'Unsupported payload data version.',
      ),
    );
  }
  if (payload.dataVersion > skilltrackerDataVersion) {
    return Failure(
      AppFailure(
        code: 'BACKUP-DATA-NEW',
        message:
            'This backup payload requires a newer Ayutam '
            '(data v${payload.dataVersion}).',
      ),
    );
  }

  final skillIds = <String>{};
  for (final skill in payload.skills) {
    final err = _requireUuid(skill.id, 'skill');
    if (err != null) return Failure(err);
    if (!skillIds.add(skill.id)) {
      return Failure(
        AppFailure(
          code: 'BACKUP-DUP-ID',
          message: 'Duplicate skill id ${skill.id}.',
        ),
      );
    }
    if (skill.name.trim().isEmpty) {
      return const Failure(
        AppFailure(code: 'BACKUP-SKILL-NAME', message: 'Skill name is empty.'),
      );
    }
    if (skill.targetSeconds <= 0) {
      return const Failure(
        AppFailure(
          code: 'BACKUP-SKILL-TARGET',
          message: 'Skill target must be positive.',
        ),
      );
    }
    if (!_skillStatuses.contains(skill.status)) {
      return Failure(
        AppFailure(
          code: 'BACKUP-SKILL-STATUS',
          message: 'Unknown skill status: ${skill.status}',
        ),
      );
    }
  }

  final sessionIds = <String>{};
  var activeCount = 0;
  for (final session in payload.sessions) {
    final err = _requireUuid(session.id, 'session');
    if (err != null) return Failure(err);
    if (!sessionIds.add(session.id)) {
      return Failure(
        AppFailure(
          code: 'BACKUP-DUP-ID',
          message: 'Duplicate session id ${session.id}.',
        ),
      );
    }
    if (!skillIds.contains(session.skillId)) {
      return Failure(
        AppFailure(
          code: 'BACKUP-FK',
          message: 'Session ${session.id} references missing skill.',
        ),
      );
    }
    if (!_sessionStatuses.contains(session.status)) {
      return Failure(
        AppFailure(
          code: 'BACKUP-SESSION-STATUS',
          message: 'Unknown session status: ${session.status}',
        ),
      );
    }
    if (!_modes.contains(session.mode)) {
      return Failure(
        AppFailure(
          code: 'BACKUP-SESSION-MODE',
          message: 'Unknown session mode: ${session.mode}',
        ),
      );
    }
    if (session.activeSeconds < 0 || session.pausedSeconds < 0) {
      return const Failure(
        AppFailure(
          code: 'BACKUP-DURATION',
          message: 'Session durations must be non-negative.',
        ),
      );
    }
    if (session.endAtUtc != null && session.endAtUtc! < session.startAtUtc) {
      return const Failure(
        AppFailure(
          code: 'BACKUP-RANGE',
          message: 'Session end is before start.',
        ),
      );
    }
    if (session.deletedAtUtc == null &&
        (session.status == 'active' ||
            session.status == 'paused' ||
            session.status == 'completion_pending')) {
      activeCount++;
    }
  }
  if (activeCount > 1) {
    return const Failure(
      AppFailure(
        code: 'BACKUP-ACTIVE',
        message: 'Backup has more than one active/paused/pending session.',
      ),
    );
  }

  final segmentIds = <String>{};
  final workBySession = <String, int>{};
  final pauseBySession = <String, int>{};
  for (final segment in payload.sessionSegments) {
    final err = _requireUuid(segment.id, 'segment');
    if (err != null) return Failure(err);
    if (!segmentIds.add(segment.id)) {
      return Failure(
        AppFailure(
          code: 'BACKUP-DUP-ID',
          message: 'Duplicate segment id ${segment.id}.',
        ),
      );
    }
    if (!sessionIds.contains(segment.sessionId)) {
      return Failure(
        AppFailure(
          code: 'BACKUP-FK',
          message: 'Segment ${segment.id} references missing session.',
        ),
      );
    }
    if (!_segmentTypes.contains(segment.segmentType)) {
      return Failure(
        AppFailure(
          code: 'BACKUP-SEGMENT-TYPE',
          message: 'Unknown segment type: ${segment.segmentType}',
        ),
      );
    }
    if (segment.durationSeconds < 0) {
      return const Failure(
        AppFailure(
          code: 'BACKUP-DURATION',
          message: 'Segment duration must be non-negative.',
        ),
      );
    }
    if (segment.endAtUtc != null && segment.endAtUtc! < segment.startAtUtc) {
      return const Failure(
        AppFailure(
          code: 'BACKUP-RANGE',
          message: 'Segment end is before start.',
        ),
      );
    }
    if (segment.segmentType == 'work') {
      workBySession[segment.sessionId] =
          (workBySession[segment.sessionId] ?? 0) + segment.durationSeconds;
    } else {
      pauseBySession[segment.sessionId] =
          (pauseBySession[segment.sessionId] ?? 0) + segment.durationSeconds;
    }
  }

  // Totals must reconcile with closed segments within a small tolerance
  // (open segments may still be open for active sessions).
  for (final session in payload.sessions) {
    if (session.deletedAtUtc != null) continue;
    if (session.status != 'completed') continue;
    final work = workBySession[session.id] ?? 0;
    final paused = pauseBySession[session.id] ?? 0;
    if ((work - session.activeSeconds).abs() > 1) {
      return Failure(
        AppFailure(
          code: 'BACKUP-TOTALS',
          message:
              'Session ${session.id} active seconds do not match work segments.',
        ),
      );
    }
    if ((paused - session.pausedSeconds).abs() > 1) {
      return Failure(
        AppFailure(
          code: 'BACKUP-TOTALS',
          message:
              'Session ${session.id} paused seconds do not match pause segments.',
        ),
      );
    }
  }

  final tagIds = <String>{};
  for (final tag in payload.tags) {
    final err = _requireUuid(tag.id, 'tag');
    if (err != null) return Failure(err);
    if (!tagIds.add(tag.id)) {
      return Failure(
        AppFailure(
          code: 'BACKUP-DUP-ID',
          message: 'Duplicate tag id ${tag.id}.',
        ),
      );
    }
    if (tag.name.trim().isEmpty || tag.normalizedName.trim().isEmpty) {
      return const Failure(
        AppFailure(code: 'BACKUP-TAG', message: 'Tag name is empty.'),
      );
    }
  }

  final sessionTagKeys = <String>{};
  for (final link in payload.sessionTags) {
    if (!sessionIds.contains(link.sessionId) || !tagIds.contains(link.tagId)) {
      return const Failure(
        AppFailure(
          code: 'BACKUP-FK',
          message: 'sessionTags references missing session or tag.',
        ),
      );
    }
    final key = '${link.sessionId}|${link.tagId}';
    if (!sessionTagKeys.add(key)) {
      return const Failure(
        AppFailure(
          code: 'BACKUP-DUP-ID',
          message: 'Duplicate sessionTags row.',
        ),
      );
    }
  }

  for (final setting in payload.settings) {
    if (setting.key.isEmpty) {
      return const Failure(
        AppFailure(code: 'BACKUP-SETTING', message: 'Setting key is empty.'),
      );
    }
  }

  return const Success(null);
}

AppFailure? _requireUuid(String value, String label) {
  if (!_uuidRe.hasMatch(value)) {
    return AppFailure(
      code: 'BACKUP-UUID',
      message: 'Invalid $label id: $value',
    );
  }
  return null;
}
