import 'package:flutter_test/flutter_test.dart';

import 'package:ayutam/features/timer/application/timer_platform_coordinator.dart';
import 'package:ayutam/features/timer/application/timer_platform_projection.dart';
import 'package:ayutam/features/timer/domain/models.dart';
import 'package:ayutam/features/timer/domain/timer_platform_ports.dart';
import 'package:ayutam/core/logging/app_logger.dart';
import 'package:ayutam/platform/no_op_timer_platform.dart';

final class _RecordingLogger implements AppLogger {
  final warnings = <String>[];

  @override
  void debug(String message, {Object? error, StackTrace? stackTrace}) {}

  @override
  void info(String message, {Object? error, StackTrace? stackTrace}) {}

  @override
  void warning(String message, {Object? error, StackTrace? stackTrace}) {
    warnings.add(message);
  }

  @override
  void error(String message, {Object? error, StackTrace? stackTrace}) {}
}

final class _FailingNotification extends NoOpForegroundTimerNotification {
  @override
  Future<void> sync(TimerPlatformProjection projection) async {
    throw StateError('notification unavailable');
  }
}

void main() {
  group('TimerPlatformProjection', () {
    test('running uses open work start for live elapsed', () {
      final start = DateTime.utc(2026, 8, 29, 10);
      final now = DateTime.utc(2026, 8, 29, 10, 0, 45);
      final snap = TimerSnapshot(
        runtime: TimerRuntimeState(
          machineState: TimerMachineState.running,
          currentCycle: 1,
          phaseAccumulatedSeconds: 0,
          updatedAtUtc: now,
          sessionId: 's1',
        ),
        session: PracticeSession(
          id: 's1',
          skillId: 'sk',
          mode: SessionMode.stopwatch,
          status: SessionStatus.active,
          source: 'timer',
          startAtUtc: start,
          activeSeconds: 0,
          pausedSeconds: 0,
          timezoneIdAtCreation: 'UTC',
          offsetMinutesAtStart: 0,
          createdAtUtc: start,
          updatedAtUtc: now,
          sourceDeviceId: 'd',
        ),
        segments: [
          SessionSegment(
            id: 'seg',
            sessionId: 's1',
            segmentType: SegmentType.work,
            startAtUtc: start,
            durationSeconds: 0,
            createdAtUtc: start,
            updatedAtUtc: now,
          ),
        ],
        displayActiveSeconds: 45,
      );
      final p = projectionFromSnapshot(
        snapshot: snap,
        skillName: 'Piano',
        nowUtc: now,
      )!;
      expect(p.displayActiveSeconds(now), 45);
      expect(p.openWorkStartUtc, start);
    });
  });

  group('TimerPlatformCoordinator', () {
    test('notification actions are idempotent via pause stream', () async {
      final notification = NoOpForegroundTimerNotification();
      final tray = NoOpDesktopTrayService();
      final coordinator = TimerPlatformCoordinator(
        notification: notification,
        tray: tray,
        logger: const ConsoleAppLogger(),
      );
      await coordinator.start();
      final received = <TimerPlatformAction>[];
      final sub = coordinator.actions.listen(received.add);

      notification.emitAction(TimerPlatformAction.pause);
      notification.emitAction(TimerPlatformAction.pause);
      tray.emitAction(TimerPlatformAction.stop);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(received.where((a) => a == TimerPlatformAction.pause).length, 2);
      expect(received, contains(TimerPlatformAction.stop));
      await sub.cancel();
      await coordinator.dispose();
    });

    test('timer sync succeeds when notification service fails', () async {
      final logger = _RecordingLogger();
      final coordinator = TimerPlatformCoordinator(
        notification: _FailingNotification(),
        tray: NoOpDesktopTrayService(),
        logger: logger,
      );
      await coordinator.start();
      final projection = TimerPlatformProjection(
        skillId: 'sk',
        skillName: 'Piano',
        machineState: TimerMachineState.running,
        closedActiveSeconds: 10,
        openWorkStartUtc: DateTime.utc(2026, 8, 29, 10),
        sessionId: 's1',
      );
      await coordinator.sync(projection);
      expect(logger.warnings, isNotEmpty);
      expect(coordinator.lastProjection, projection);
      await coordinator.dispose();
    });
  });

  group('NoOpTimerChromeService', () {
    test('enter and leave track keep-awake flag', () async {
      final chrome = NoOpTimerChromeService();
      await chrome.enterTimerVisible(
        keepScreenAwake: true,
        requestLandscape: true,
      );
      expect(chrome.keepScreenAwakeActive, isTrue);
      expect(chrome.landscapeRequested, isTrue);
      await chrome.leaveTimerVisible();
      expect(chrome.keepScreenAwakeActive, isFalse);
    });
  });
}
