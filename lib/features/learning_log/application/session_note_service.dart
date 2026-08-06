import '../../../core/id/id_generator.dart';
import '../../../core/result/result.dart';
import '../../../core/time/clock_service.dart';
import '../../skills/domain/skill_repository.dart';
import '../../timer/domain/models.dart';
import '../../timer/domain/repositories.dart';
import '../data/session_search_indexer.dart';
import '../domain/learning_log_models.dart';
import '../domain/tag.dart';
import 'tag_service.dart';

/// Draft notes/tags, manual entry, edit, and soft-delete for journal sessions.
final class SessionNoteService {
  SessionNoteService({
    required SessionRepository sessions,
    required SkillRepository skills,
    required TagService tags,
    required SessionSearchIndexer indexer,
    required UnitOfWork uow,
    required ClockService clock,
    required IdGenerator ids,
    required Future<String> Function() deviceId,
  }) : _sessions = sessions,
       _skills = skills,
       _tags = tags,
       _indexer = indexer,
       _uow = uow,
       _clock = clock,
       _ids = ids,
       _deviceId = deviceId;

  final SessionRepository _sessions;
  final SkillRepository _skills;
  final TagService _tags;
  final SessionSearchIndexer _indexer;
  final UnitOfWork _uow;
  final ClockService _clock;
  final IdGenerator _ids;
  final Future<String> Function() _deviceId;

  Future<Result<PracticeSession>> updateDraft({
    required String sessionId,
    String? title,
    bool updateTitle = false,
    String? noteMarkdown,
    bool updateNote = false,
    List<String>? tagNames,
  }) async {
    final session = await _sessions.findById(sessionId);
    if (session == null || session.deletedAtUtc != null) {
      return const Failure(
        AppFailure(code: 'SESS-MISS', message: 'Session not found.'),
      );
    }
    if (session.status != SessionStatus.completionPending &&
        session.status != SessionStatus.completed) {
      return const Failure(
        AppFailure(
          code: 'SESS-STATE',
          message: 'Notes can only be edited on pending or completed sessions.',
        ),
      );
    }

    return _uow.write(() async {
      final now = _clock.nowUtc();
      var nextTitle = session.title;
      var nextNote = session.noteMarkdown;
      if (updateTitle) {
        final trimmed = title?.trim() ?? '';
        nextTitle = trimmed.isEmpty ? null : trimmed;
      }
      if (updateNote) {
        final trimmed = noteMarkdown?.trim() ?? '';
        nextNote = trimmed.isEmpty ? null : trimmed;
      }
      final updated = session.copyWith(
        title: nextTitle,
        noteMarkdown: nextNote,
        clearTitle: nextTitle == null,
        clearNoteMarkdown: nextNote == null,
        updatedAtUtc: now,
      );
      await _sessions.updateSession(updated);
      if (tagNames != null) {
        final tagResult = await _tags.setSessionTagNames(
          sessionId: sessionId,
          names: tagNames,
        );
        if (tagResult.isFailure) {
          return Failure((tagResult as Failure<List<Tag>>).error);
        }
      }
      await _indexer.indexSession(updated);
      return Success(updated);
    });
  }

  Future<Result<ManualSessionResult>> createManualSession({
    required String skillId,
    required DateTime startAtUtc,
    required DateTime endAtUtc,
    String? title,
    String? noteMarkdown,
    List<String>? tagNames,
    bool allowOverlap = false,
    String timezoneId = 'UTC',
    int offsetMinutes = 0,
  }) async {
    if (!endAtUtc.isAfter(startAtUtc)) {
      return const Failure(
        AppFailure(
          code: 'VAL-RANGE',
          message: 'End time must be after start time.',
        ),
      );
    }
    final skill = await _skills.findById(skillId);
    if (skill == null) {
      return const Failure(
        AppFailure(code: 'SKILL-MISS', message: 'Skill not found.'),
      );
    }

    final overlaps = await _sessions.findOverlapping(
      skillId: skillId,
      startAtUtc: startAtUtc,
      endAtUtc: endAtUtc,
    );
    if (overlaps.isNotEmpty && !allowOverlap) {
      return Success(
        ManualSessionResult(
          session: null,
          overlaps: overlaps
              .map(
                (s) => SessionOverlap(
                  sessionId: s.id,
                  startAtUtc: s.startAtUtc,
                  endAtUtc: s.endAtUtc!,
                ),
              )
              .toList(),
        ),
      );
    }

    final activeSeconds = TimerMath.closedDurationSeconds(
      startAtUtc: startAtUtc,
      endAtUtc: endAtUtc,
    );

    return _uow.write(() async {
      final now = _clock.nowUtc();
      final sessionId = _ids.v4();
      final trimmedTitle = title?.trim();
      final trimmedNote = noteMarkdown?.trim();
      final session = PracticeSession(
        id: sessionId,
        skillId: skillId,
        title: (trimmedTitle == null || trimmedTitle.isEmpty)
            ? null
            : trimmedTitle,
        noteMarkdown: (trimmedNote == null || trimmedNote.isEmpty)
            ? null
            : trimmedNote,
        mode: SessionMode.manual,
        status: SessionStatus.completed,
        source: 'manual',
        startAtUtc: startAtUtc.toUtc(),
        endAtUtc: endAtUtc.toUtc(),
        activeSeconds: activeSeconds,
        pausedSeconds: 0,
        timezoneIdAtCreation: timezoneId,
        offsetMinutesAtStart: offsetMinutes,
        createdAtUtc: now,
        updatedAtUtc: now,
        sourceDeviceId: await _deviceId(),
      );
      final segment = SessionSegment(
        id: _ids.v4(),
        sessionId: sessionId,
        segmentType: SegmentType.work,
        startAtUtc: session.startAtUtc,
        endAtUtc: session.endAtUtc,
        durationSeconds: activeSeconds,
        createdAtUtc: now,
        updatedAtUtc: now,
      );
      await _sessions.insertSession(session);
      await _sessions.insertSegment(segment);
      if (tagNames != null && tagNames.isNotEmpty) {
        final tagResult = await _tags.setSessionTagNames(
          sessionId: sessionId,
          names: tagNames,
        );
        if (tagResult.isFailure) {
          return Failure((tagResult as Failure<List<Tag>>).error);
        }
      }
      await _indexer.indexSession(session);
      return Success(
        ManualSessionResult(
          session: session,
          overlaps: overlaps
              .map(
                (s) => SessionOverlap(
                  sessionId: s.id,
                  startAtUtc: s.startAtUtc,
                  endAtUtc: s.endAtUtc!,
                ),
              )
              .toList(),
        ),
      );
    });
  }

  Future<Result<PracticeSession>> updateCompletedSession({
    required String sessionId,
    String? skillId,
    String? title,
    bool updateTitle = false,
    String? noteMarkdown,
    bool updateNote = false,
    List<String>? tagNames,
    DateTime? startAtUtc,
    DateTime? endAtUtc,
    bool allowOverlap = false,
  }) async {
    final session = await _sessions.findById(sessionId);
    if (session == null || session.deletedAtUtc != null) {
      return const Failure(
        AppFailure(code: 'SESS-MISS', message: 'Session not found.'),
      );
    }
    if (session.status != SessionStatus.completed) {
      return const Failure(
        AppFailure(
          code: 'SESS-STATE',
          message: 'Only completed sessions can be edited here.',
        ),
      );
    }

    final nextSkillId = skillId ?? session.skillId;
    if (skillId != null) {
      final skill = await _skills.findById(skillId);
      if (skill == null) {
        return const Failure(
          AppFailure(code: 'SKILL-MISS', message: 'Skill not found.'),
        );
      }
    }

    final nextStart = (startAtUtc ?? session.startAtUtc).toUtc();
    final nextEnd = (endAtUtc ?? session.endAtUtc ?? session.startAtUtc)
        .toUtc();
    if (!nextEnd.isAfter(nextStart)) {
      return const Failure(
        AppFailure(
          code: 'VAL-RANGE',
          message: 'End time must be after start time.',
        ),
      );
    }

    final rewriteTimes = startAtUtc != null || endAtUtc != null;
    if (rewriteTimes) {
      final overlaps = await _sessions.findOverlapping(
        skillId: nextSkillId,
        startAtUtc: nextStart,
        endAtUtc: nextEnd,
        excludeSessionId: sessionId,
      );
      if (overlaps.isNotEmpty && !allowOverlap) {
        return Failure(
          AppFailure(
            code: 'SESS-OVERLAP',
            message:
                'This time overlaps ${overlaps.length} other session(s) for this skill.',
            cause: overlaps,
          ),
        );
      }
    }

    return _uow.write(() async {
      final now = _clock.nowUtc();
      var nextTitle = session.title;
      var nextNote = session.noteMarkdown;
      if (updateTitle) {
        final trimmed = title?.trim() ?? '';
        nextTitle = trimmed.isEmpty ? null : trimmed;
      }
      if (updateNote) {
        final trimmed = noteMarkdown?.trim() ?? '';
        nextNote = trimmed.isEmpty ? null : trimmed;
      }

      var activeSeconds = session.activeSeconds;
      if (rewriteTimes) {
        activeSeconds = TimerMath.closedDurationSeconds(
          startAtUtc: nextStart,
          endAtUtc: nextEnd,
        );
        await _sessions.deleteSegmentsForSession(sessionId);
        await _sessions.insertSegment(
          SessionSegment(
            id: _ids.v4(),
            sessionId: sessionId,
            segmentType: SegmentType.work,
            startAtUtc: nextStart,
            endAtUtc: nextEnd,
            durationSeconds: activeSeconds,
            createdAtUtc: now,
            updatedAtUtc: now,
          ),
        );
      }

      final updated = session.copyWith(
        skillId: nextSkillId,
        title: nextTitle,
        noteMarkdown: nextNote,
        clearTitle: nextTitle == null,
        clearNoteMarkdown: nextNote == null,
        startAtUtc: nextStart,
        endAtUtc: nextEnd,
        activeSeconds: activeSeconds,
        updatedAtUtc: now,
      );
      await _sessions.updateSession(updated);
      if (tagNames != null) {
        final tagResult = await _tags.setSessionTagNames(
          sessionId: sessionId,
          names: tagNames,
        );
        if (tagResult.isFailure) {
          return Failure((tagResult as Failure<List<Tag>>).error);
        }
      }
      await _indexer.indexSession(updated);
      return Success(updated);
    });
  }

  Future<Result<PracticeSession>> softDelete(String sessionId) async {
    final session = await _sessions.findById(sessionId);
    if (session == null || session.deletedAtUtc != null) {
      return const Failure(
        AppFailure(code: 'SESS-MISS', message: 'Session not found.'),
      );
    }
    if (session.status != SessionStatus.completed) {
      return const Failure(
        AppFailure(
          code: 'SESS-STATE',
          message: 'Only completed sessions can be deleted from the log.',
        ),
      );
    }
    return _uow.write(() async {
      final now = _clock.nowUtc();
      final updated = session.copyWith(deletedAtUtc: now, updatedAtUtc: now);
      await _sessions.updateSession(updated);
      await _indexer.delete(sessionId);
      return Success(updated);
    });
  }

  Future<Result<PracticeSession>> restore(String sessionId) async {
    final session = await _sessions.findById(sessionId);
    if (session == null) {
      return const Failure(
        AppFailure(code: 'SESS-MISS', message: 'Session not found.'),
      );
    }
    if (session.deletedAtUtc == null) {
      return Success(session);
    }
    return _uow.write(() async {
      final now = _clock.nowUtc();
      final updated = session.copyWith(
        clearDeletedAtUtc: true,
        updatedAtUtc: now,
      );
      await _sessions.updateSession(updated);
      await _indexer.indexSession(updated);
      return Success(updated);
    });
  }

  Future<List<Tag>> tagsForSession(String sessionId) {
    return _tags.listForSession(sessionId);
  }
}

final class ManualSessionResult {
  const ManualSessionResult({required this.session, required this.overlaps});

  final PracticeSession? session;
  final List<SessionOverlap> overlaps;

  bool get needsOverlapConfirm => session == null && overlaps.isNotEmpty;
}
