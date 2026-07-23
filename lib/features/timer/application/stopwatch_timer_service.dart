import '../../../core/constants/app_constants.dart';
import '../../../core/id/id_generator.dart';
import '../../../core/result/result.dart';
import '../../../core/time/clock_service.dart';
import '../../skills/domain/skill.dart';
import '../../skills/domain/skill_repository.dart';
import '../domain/models.dart';
import '../domain/repositories.dart';

/// Stopwatch state machine: persist-first, idempotent commands.
final class StopwatchTimerService {
  StopwatchTimerService({
    required SessionRepository sessions,
    required TimerRuntimeRepository runtime,
    required SkillRepository skills,
    required UnitOfWork uow,
    required ClockService clock,
    required IdGenerator ids,
    required Future<String> Function() deviceId,
  }) : _sessions = sessions,
       _runtime = runtime,
       _skills = skills,
       _uow = uow,
       _clock = clock,
       _ids = ids,
       _deviceId = deviceId;

  final SessionRepository _sessions;
  final TimerRuntimeRepository _runtime;
  final SkillRepository _skills;
  final UnitOfWork _uow;
  final ClockService _clock;
  final IdGenerator _ids;
  final Future<String> Function() _deviceId;

  static const Duration clockAnomalyTolerance = Duration(minutes: 5);

  Future<TimerSnapshot> snapshot() async {
    final runtime = await _runtime.get();
    final session = runtime.sessionId == null
        ? null
        : await _sessions.findById(runtime.sessionId!);
    final segments = session == null
        ? const <SessionSegment>[]
        : await _sessions.listSegments(session.id);
    final now = _clock.nowUtc();
    final display = session == null
        ? 0
        : TimerMath.activeSecondsFromSegments(segments: segments, nowUtc: now);
    return TimerSnapshot(
      runtime: runtime,
      session: session,
      segments: segments,
      displayActiveSeconds: display,
    );
  }

  Future<Result<TimerSnapshot>> startStopwatch(String skillId) async {
    return _uow.write(() async {
      final skill = await _skills.findById(skillId);
      if (skill == null) {
        return const Failure(
          AppFailure(code: 'SKILL-404', message: 'Skill not found.'),
        );
      }
      if (skill.status != SkillStatus.active) {
        return const Failure(
          AppFailure(
            code: 'SKILL-ARCHIVED',
            message: 'Cannot start a session on an archived skill.',
          ),
        );
      }

      final runtime = await _runtime.get();
      if (!runtime.isIdle || runtime.sessionId != null) {
        final inProgress = await _sessions.listInProgress();
        if (inProgress.isNotEmpty) {
          return const Failure(
            AppFailure(
              code: 'TIMER-BUSY',
              message: 'Another session is already in progress.',
            ),
          );
        }
      }

      final now = _clock.nowUtc();
      final local = now.toLocal();
      final sessionId = _ids.v4();
      final segmentId = _ids.v4();
      final deviceId = await _deviceId();

      final session = PracticeSession(
        id: sessionId,
        skillId: skillId,
        mode: SessionMode.stopwatch,
        status: SessionStatus.active,
        source: 'timer',
        startAtUtc: now,
        activeSeconds: 0,
        pausedSeconds: 0,
        timezoneIdAtCreation: local.timeZoneName,
        offsetMinutesAtStart: local.timeZoneOffset.inMinutes,
        createdAtUtc: now,
        updatedAtUtc: now,
        sourceDeviceId: deviceId,
      );
      final work = SessionSegment(
        id: segmentId,
        sessionId: sessionId,
        segmentType: SegmentType.work,
        startAtUtc: now,
        durationSeconds: 0,
        createdAtUtc: now,
        updatedAtUtc: now,
      );
      await _sessions.insertSession(session);
      await _sessions.insertSegment(work);
      await _runtime.save(
        TimerRuntimeState(
          sessionId: sessionId,
          machineState: TimerMachineState.running,
          currentSegmentId: segmentId,
          phaseAccumulatedSeconds: 0,
          currentCycle: 1,
          monotonicAnchorMicros: _clock.monotonicMicros(),
          wallClockAnchorUtc: now,
          lastHeartbeatUtc: now,
          lastCheckpointAtUtc: now,
          updatedAtUtc: now,
        ),
      );
      return Success(await snapshot());
    });
  }

  Future<Result<TimerSnapshot>> pause() async {
    return _uow.write(() async {
      final runtime = await _runtime.get();
      if (runtime.machineState == TimerMachineState.paused) {
        return Success(await snapshot());
      }
      if (runtime.machineState != TimerMachineState.running ||
          runtime.sessionId == null) {
        return const Failure(
          AppFailure(code: 'TIMER-STATE', message: 'Timer is not running.'),
        );
      }
      final session = await _sessions.findById(runtime.sessionId!);
      if (session == null) {
        return const Failure(
          AppFailure(code: 'SESSION-404', message: 'Session not found.'),
        );
      }
      final open = await _sessions.findOpenSegment(session.id);
      if (open == null || open.segmentType != SegmentType.work) {
        return const Failure(
          AppFailure(
            code: 'TIMER-SEGMENT',
            message: 'Expected an open work segment.',
          ),
        );
      }

      final now = _clock.nowUtc();
      final closedDuration = TimerMath.closedDurationSeconds(
        startAtUtc: open.startAtUtc,
        endAtUtc: now,
      );
      await _sessions.updateSegment(
        open.copyWith(
          endAtUtc: now,
          durationSeconds: closedDuration,
          updatedAtUtc: now,
        ),
      );
      final pauseId = _ids.v4();
      await _sessions.insertSegment(
        SessionSegment(
          id: pauseId,
          sessionId: session.id,
          segmentType: SegmentType.pause,
          startAtUtc: now,
          durationSeconds: 0,
          createdAtUtc: now,
          updatedAtUtc: now,
        ),
      );
      final segments = await _sessions.listSegments(session.id);
      final active = TimerMath.activeSecondsFromSegments(
        segments: segments,
        nowUtc: now,
      );
      final paused = TimerMath.pausedSecondsFromSegments(
        segments: segments,
        nowUtc: now,
      );
      await _sessions.updateSession(
        session.copyWith(
          status: SessionStatus.paused,
          activeSeconds: active,
          pausedSeconds: paused,
          updatedAtUtc: now,
        ),
      );
      await _runtime.save(
        runtime.copyWith(
          machineState: TimerMachineState.paused,
          currentSegmentId: pauseId,
          wallClockAnchorUtc: now,
          lastHeartbeatUtc: now,
          lastCheckpointAtUtc: now,
          updatedAtUtc: now,
          clearRecoveryReason: true,
        ),
      );
      return Success(await snapshot());
    });
  }

  Future<Result<TimerSnapshot>> resume() async {
    return _uow.write(() async {
      final runtime = await _runtime.get();
      if (runtime.machineState == TimerMachineState.running) {
        return Success(await snapshot());
      }
      if (runtime.machineState != TimerMachineState.paused ||
          runtime.sessionId == null) {
        return const Failure(
          AppFailure(code: 'TIMER-STATE', message: 'Timer is not paused.'),
        );
      }
      final session = await _sessions.findById(runtime.sessionId!);
      if (session == null) {
        return const Failure(
          AppFailure(code: 'SESSION-404', message: 'Session not found.'),
        );
      }
      final open = await _sessions.findOpenSegment(session.id);
      if (open == null || open.segmentType != SegmentType.pause) {
        return const Failure(
          AppFailure(
            code: 'TIMER-SEGMENT',
            message: 'Expected an open pause segment.',
          ),
        );
      }

      final now = _clock.nowUtc();
      final closedDuration = TimerMath.closedDurationSeconds(
        startAtUtc: open.startAtUtc,
        endAtUtc: now,
      );
      await _sessions.updateSegment(
        open.copyWith(
          endAtUtc: now,
          durationSeconds: closedDuration,
          updatedAtUtc: now,
        ),
      );
      final workId = _ids.v4();
      await _sessions.insertSegment(
        SessionSegment(
          id: workId,
          sessionId: session.id,
          segmentType: SegmentType.work,
          startAtUtc: now,
          durationSeconds: 0,
          createdAtUtc: now,
          updatedAtUtc: now,
        ),
      );
      final segments = await _sessions.listSegments(session.id);
      await _sessions.updateSession(
        session.copyWith(
          status: SessionStatus.active,
          activeSeconds: TimerMath.activeSecondsFromSegments(
            segments: segments,
            nowUtc: now,
          ),
          pausedSeconds: TimerMath.pausedSecondsFromSegments(
            segments: segments,
            nowUtc: now,
          ),
          updatedAtUtc: now,
        ),
      );
      await _runtime.save(
        runtime.copyWith(
          machineState: TimerMachineState.running,
          currentSegmentId: workId,
          monotonicAnchorMicros: _clock.monotonicMicros(),
          wallClockAnchorUtc: now,
          lastHeartbeatUtc: now,
          lastCheckpointAtUtc: now,
          updatedAtUtc: now,
          clearRecoveryReason: true,
        ),
      );
      return Success(await snapshot());
    });
  }

  Future<Result<TimerSnapshot>> stop() async {
    return _uow.write(() async {
      final runtime = await _runtime.get();
      if (runtime.machineState == TimerMachineState.completionPending) {
        return Success(await snapshot());
      }
      if (runtime.sessionId == null ||
          (runtime.machineState != TimerMachineState.running &&
              runtime.machineState != TimerMachineState.paused &&
              runtime.machineState != TimerMachineState.recoveryReview)) {
        return const Failure(
          AppFailure(code: 'TIMER-STATE', message: 'No stoppable session.'),
        );
      }
      final session = await _sessions.findById(runtime.sessionId!);
      if (session == null) {
        return const Failure(
          AppFailure(code: 'SESSION-404', message: 'Session not found.'),
        );
      }

      final now = _clock.nowUtc();
      final open = await _sessions.findOpenSegment(session.id);
      if (open != null) {
        final closedDuration = TimerMath.closedDurationSeconds(
          startAtUtc: open.startAtUtc,
          endAtUtc: now,
        );
        await _sessions.updateSegment(
          open.copyWith(
            endAtUtc: now,
            durationSeconds: closedDuration,
            updatedAtUtc: now,
          ),
        );
      }
      final segments = await _sessions.listSegments(session.id);
      final active = TimerMath.activeSecondsFromSegments(
        segments: segments,
        nowUtc: now,
      );
      final paused = TimerMath.pausedSecondsFromSegments(
        segments: segments,
        nowUtc: now,
      );
      await _sessions.updateSession(
        session.copyWith(
          status: SessionStatus.completionPending,
          endAtUtc: now,
          activeSeconds: active,
          pausedSeconds: paused,
          updatedAtUtc: now,
        ),
      );
      await _runtime.save(
        runtime.copyWith(
          machineState: TimerMachineState.completionPending,
          clearSegment: true,
          lastCheckpointAtUtc: now,
          updatedAtUtc: now,
          clearRecoveryReason: true,
        ),
      );
      return Success(await snapshot());
    });
  }

  Future<Result<TimerSnapshot>> saveCompletion() async {
    return _uow.write(() async {
      final runtime = await _runtime.get();
      if (runtime.machineState == TimerMachineState.idle &&
          runtime.sessionId == null) {
        return Success(await snapshot());
      }
      if (runtime.machineState != TimerMachineState.completionPending ||
          runtime.sessionId == null) {
        return const Failure(
          AppFailure(
            code: 'TIMER-STATE',
            message: 'No completion-pending session.',
          ),
        );
      }
      final session = await _sessions.findById(runtime.sessionId!);
      if (session == null) {
        return const Failure(
          AppFailure(code: 'SESSION-404', message: 'Session not found.'),
        );
      }
      final now = _clock.nowUtc();
      await _sessions.updateSession(
        session.copyWith(status: SessionStatus.completed, updatedAtUtc: now),
      );
      await _runtime.clearToIdle(updatedAtUtc: now);
      return Success(await snapshot());
    });
  }

  Future<Result<TimerSnapshot>> discardCompletion() async {
    return _uow.write(() async {
      final runtime = await _runtime.get();
      if (runtime.machineState == TimerMachineState.idle &&
          runtime.sessionId == null) {
        return Success(await snapshot());
      }
      if (runtime.sessionId == null) {
        return const Failure(
          AppFailure(code: 'TIMER-STATE', message: 'Nothing to discard.'),
        );
      }
      if (runtime.machineState != TimerMachineState.completionPending &&
          runtime.machineState != TimerMachineState.recoveryReview) {
        return const Failure(
          AppFailure(
            code: 'TIMER-STATE',
            message: 'Session is not discardable from this state.',
          ),
        );
      }
      final sessionId = runtime.sessionId!;
      final now = _clock.nowUtc();
      // Clear FK from timer_runtime before deleting the session.
      await _runtime.clearToIdle(updatedAtUtc: now);
      await _sessions.deleteSessionCascade(sessionId);
      return Success(await snapshot());
    });
  }

  Future<Result<TimerSnapshot>> resumeFromCompletion() async {
    return _uow.write(() async {
      final runtime = await _runtime.get();
      if (runtime.machineState == TimerMachineState.running) {
        return Success(await snapshot());
      }
      if (runtime.machineState != TimerMachineState.completionPending ||
          runtime.sessionId == null) {
        return const Failure(
          AppFailure(
            code: 'TIMER-STATE',
            message: 'No completion-pending session to resume.',
          ),
        );
      }
      final session = await _sessions.findById(runtime.sessionId!);
      if (session == null) {
        return const Failure(
          AppFailure(code: 'SESSION-404', message: 'Session not found.'),
        );
      }
      final now = _clock.nowUtc();
      final workId = _ids.v4();
      await _sessions.insertSegment(
        SessionSegment(
          id: workId,
          sessionId: session.id,
          segmentType: SegmentType.work,
          startAtUtc: now,
          durationSeconds: 0,
          createdAtUtc: now,
          updatedAtUtc: now,
        ),
      );
      await _sessions.updateSession(
        session.copyWith(
          status: SessionStatus.active,
          clearEndAtUtc: true,
          updatedAtUtc: now,
        ),
      );
      await _runtime.save(
        runtime.copyWith(
          machineState: TimerMachineState.running,
          currentSegmentId: workId,
          monotonicAnchorMicros: _clock.monotonicMicros(),
          wallClockAnchorUtc: now,
          lastHeartbeatUtc: now,
          lastCheckpointAtUtc: now,
          updatedAtUtc: now,
          clearRecoveryReason: true,
        ),
      );
      return Success(await snapshot());
    });
  }

  Future<Result<TimerSnapshot>> heartbeat() async {
    return _uow.write(() async {
      final runtime = await _runtime.get();
      if (runtime.machineState != TimerMachineState.running) {
        return Success(await snapshot());
      }
      final now = _clock.nowUtc();
      await _runtime.save(
        runtime.copyWith(lastHeartbeatUtc: now, updatedAtUtc: now),
      );
      return Success(await snapshot());
    });
  }

  /// Classifies persisted state after process death / relaunch.
  Future<Result<StartupRoute>> recoverOnStartup() async {
    return _uow.write(() async {
      final runtime = await _runtime.get();
      final now = _clock.nowUtc();

      if (runtime.machineState == TimerMachineState.completionPending &&
          runtime.sessionId != null) {
        final session = await _sessions.findById(runtime.sessionId!);
        return Success(
          StartupRoute(
            destination: StartupDestination.completion,
            sessionId: runtime.sessionId,
            skillId: session?.skillId,
          ),
        );
      }

      if (runtime.machineState == TimerMachineState.recoveryReview &&
          runtime.sessionId != null) {
        final session = await _sessions.findById(runtime.sessionId!);
        final segments = session == null
            ? const <SessionSegment>[]
            : await _sessions.listSegments(session.id);
        return Success(
          StartupRoute(
            destination: StartupDestination.recoveryReview,
            sessionId: runtime.sessionId,
            skillId: session?.skillId,
            recoveryReason: runtime.recoveryReason,
            proposedActiveSeconds: TimerMath.activeSecondsFromSegments(
              segments: segments,
              nowUtc: now,
            ),
            lastHeartbeatUtc: runtime.lastHeartbeatUtc,
          ),
        );
      }

      if (runtime.sessionId == null || runtime.isIdle) {
        // Heal stray in-progress rows if runtime is idle.
        final stray = await _sessions.listInProgress();
        if (stray.isEmpty) {
          return const Success(
            StartupRoute(destination: StartupDestination.skillsHome),
          );
        }
      }

      final sessionId = runtime.sessionId;
      if (sessionId == null) {
        return const Success(
          StartupRoute(destination: StartupDestination.skillsHome),
        );
      }
      final session = await _sessions.findById(sessionId);
      if (session == null) {
        await _runtime.clearToIdle(updatedAtUtc: now);
        return const Success(
          StartupRoute(destination: StartupDestination.skillsHome),
        );
      }

      final open = await _sessions.findOpenSegment(session.id);
      final segments = await _sessions.listSegments(session.id);

      // Clock anomaly: wall time behind last heartbeat / anchors.
      final heartbeat = runtime.lastHeartbeatUtc;
      final anomaly =
          (heartbeat != null &&
              now.isBefore(heartbeat.subtract(clockAnomalyTolerance))) ||
          (runtime.wallClockAnchorUtc != null &&
              now.isBefore(
                runtime.wallClockAnchorUtc!.subtract(clockAnomalyTolerance),
              ));

      if (open != null && open.segmentType == SegmentType.work) {
        final gap = heartbeat == null
            ? const Duration(days: 365)
            : now.difference(heartbeat);
        final threshold = const Duration(
          minutes: AppConstants.recoveryGapThresholdMinutes,
        );
        if (anomaly || gap > threshold) {
          final reason = anomaly
              ? RecoveryReason.clockChange
              : RecoveryReason.longGap;
          await _runtime.save(
            runtime.copyWith(
              machineState: TimerMachineState.recoveryReview,
              recoveryReason: reason,
              updatedAtUtc: now,
            ),
          );
          return Success(
            StartupRoute(
              destination: StartupDestination.recoveryReview,
              sessionId: session.id,
              skillId: session.skillId,
              recoveryReason: reason,
              proposedActiveSeconds: TimerMath.activeSecondsFromSegments(
                segments: segments,
                nowUtc: now,
              ),
              lastHeartbeatUtc: heartbeat,
            ),
          );
        }

        // Silent resume: refresh anchors; leave open work intact.
        await _runtime.save(
          runtime.copyWith(
            machineState: TimerMachineState.running,
            monotonicAnchorMicros: _clock.monotonicMicros(),
            wallClockAnchorUtc: now,
            lastHeartbeatUtc: now,
            lastCheckpointAtUtc: now,
            updatedAtUtc: now,
            clearRecoveryReason: true,
          ),
        );
        await _sessions.updateSession(
          session.copyWith(
            status: SessionStatus.active,
            activeSeconds: TimerMath.activeSecondsFromSegments(
              segments: segments,
              nowUtc: now,
            ),
            updatedAtUtc: now,
          ),
        );
        return Success(
          StartupRoute(
            destination: StartupDestination.timer,
            sessionId: session.id,
            skillId: session.skillId,
          ),
        );
      }

      // Paused / open pause: gap does not force review.
      if (open != null &&
          (open.segmentType == SegmentType.pause ||
              open.segmentType == SegmentType.pomodoroBreak)) {
        if (anomaly) {
          await _runtime.save(
            runtime.copyWith(
              machineState: TimerMachineState.recoveryReview,
              recoveryReason: RecoveryReason.clockChange,
              updatedAtUtc: now,
            ),
          );
          return Success(
            StartupRoute(
              destination: StartupDestination.recoveryReview,
              sessionId: session.id,
              skillId: session.skillId,
              recoveryReason: RecoveryReason.clockChange,
              proposedActiveSeconds: TimerMath.activeSecondsFromSegments(
                segments: segments,
                nowUtc: now,
              ),
              lastHeartbeatUtc: heartbeat,
            ),
          );
        }
        await _runtime.save(
          runtime.copyWith(
            machineState: TimerMachineState.paused,
            updatedAtUtc: now,
            clearRecoveryReason: true,
          ),
        );
        await _sessions.updateSession(
          session.copyWith(status: SessionStatus.paused, updatedAtUtc: now),
        );
        return Success(
          StartupRoute(
            destination: StartupDestination.timer,
            sessionId: session.id,
            skillId: session.skillId,
          ),
        );
      }

      if (session.status == SessionStatus.completionPending) {
        await _runtime.save(
          runtime.copyWith(
            machineState: TimerMachineState.completionPending,
            updatedAtUtc: now,
          ),
        );
        return Success(
          StartupRoute(
            destination: StartupDestination.completion,
            sessionId: session.id,
            skillId: session.skillId,
          ),
        );
      }

      return const Success(
        StartupRoute(destination: StartupDestination.skillsHome),
      );
    });
  }

  Future<Result<TimerSnapshot>> applyRecoveryDecision({
    required RecoveryDecision decision,
    DateTime? editedEndUtc,
  }) async {
    return _uow.write(() async {
      final runtime = await _runtime.get();
      if (runtime.machineState != TimerMachineState.recoveryReview ||
          runtime.sessionId == null) {
        return const Failure(
          AppFailure(code: 'TIMER-STATE', message: 'Not in recovery review.'),
        );
      }
      final session = await _sessions.findById(runtime.sessionId!);
      if (session == null) {
        return const Failure(
          AppFailure(code: 'SESSION-404', message: 'Session not found.'),
        );
      }
      final open = await _sessions.findOpenSegment(session.id);
      final now = _clock.nowUtc();

      switch (decision) {
        case RecoveryDecision.discard:
          final nowDiscard = _clock.nowUtc();
          await _runtime.clearToIdle(updatedAtUtc: nowDiscard);
          await _sessions.deleteSessionCascade(session.id);
          return Success(await snapshot());

        case RecoveryDecision.includeFullGap:
          // Keep open work as-is; resume running.
          if (open == null || open.segmentType != SegmentType.work) {
            return const Failure(
              AppFailure(
                code: 'TIMER-SEGMENT',
                message: 'No open work segment to include.',
              ),
            );
          }
          await _runtime.save(
            runtime.copyWith(
              machineState: TimerMachineState.running,
              monotonicAnchorMicros: _clock.monotonicMicros(),
              wallClockAnchorUtc: now,
              lastHeartbeatUtc: now,
              lastCheckpointAtUtc: now,
              updatedAtUtc: now,
              clearRecoveryReason: true,
            ),
          );
          await _sessions.updateSession(
            session.copyWith(status: SessionStatus.active, updatedAtUtc: now),
          );
          return Success(await snapshot());

        case RecoveryDecision.trimToHeartbeat:
          final cut = runtime.lastHeartbeatUtc ?? open?.startAtUtc ?? now;
          if (open != null && open.segmentType == SegmentType.work) {
            final end = cut.isBefore(open.startAtUtc) ? open.startAtUtc : cut;
            final duration = TimerMath.closedDurationSeconds(
              startAtUtc: open.startAtUtc,
              endAtUtc: end,
            );
            await _sessions.updateSegment(
              open.copyWith(
                endAtUtc: end,
                durationSeconds: duration,
                updatedAtUtc: now,
              ),
            );
            final pauseId = _ids.v4();
            await _sessions.insertSegment(
              SessionSegment(
                id: pauseId,
                sessionId: session.id,
                segmentType: SegmentType.pause,
                startAtUtc: end,
                durationSeconds: 0,
                createdAtUtc: now,
                updatedAtUtc: now,
              ),
            );
            final segments = await _sessions.listSegments(session.id);
            await _sessions.updateSession(
              session.copyWith(
                status: SessionStatus.paused,
                activeSeconds: TimerMath.activeSecondsFromSegments(
                  segments: segments,
                  nowUtc: now,
                ),
                pausedSeconds: TimerMath.pausedSecondsFromSegments(
                  segments: segments,
                  nowUtc: now,
                ),
                updatedAtUtc: now,
              ),
            );
            await _runtime.save(
              runtime.copyWith(
                machineState: TimerMachineState.paused,
                currentSegmentId: pauseId,
                wallClockAnchorUtc: now,
                lastHeartbeatUtc: now,
                lastCheckpointAtUtc: now,
                updatedAtUtc: now,
                clearRecoveryReason: true,
              ),
            );
          }
          return Success(await snapshot());

        case RecoveryDecision.editEnd:
          final end = editedEndUtc?.toUtc();
          if (end == null) {
            return const Failure(
              AppFailure(
                code: 'VAL-END',
                message: 'Edited end time is required.',
              ),
            );
          }
          if (open == null) {
            return const Failure(
              AppFailure(
                code: 'TIMER-SEGMENT',
                message: 'No open segment to edit.',
              ),
            );
          }
          final clamped = end.isBefore(open.startAtUtc) ? open.startAtUtc : end;
          final duration = TimerMath.closedDurationSeconds(
            startAtUtc: open.startAtUtc,
            endAtUtc: clamped,
          );
          await _sessions.updateSegment(
            open.copyWith(
              endAtUtc: clamped,
              durationSeconds: duration,
              updatedAtUtc: now,
            ),
          );
          final segments = await _sessions.listSegments(session.id);
          final active = TimerMath.activeSecondsFromSegments(
            segments: segments,
            nowUtc: now,
          );
          final paused = TimerMath.pausedSecondsFromSegments(
            segments: segments,
            nowUtc: now,
          );
          await _sessions.updateSession(
            session.copyWith(
              status: SessionStatus.completionPending,
              endAtUtc: clamped,
              activeSeconds: active,
              pausedSeconds: paused,
              updatedAtUtc: now,
            ),
          );
          await _runtime.save(
            runtime.copyWith(
              machineState: TimerMachineState.completionPending,
              clearSegment: true,
              lastCheckpointAtUtc: now,
              updatedAtUtc: now,
              clearRecoveryReason: true,
            ),
          );
          return Success(await snapshot());
      }
    });
  }
}
