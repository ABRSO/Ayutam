import 'timer_enums.dart';

/// Actions originating from notification / tray (same application commands).
enum TimerPlatformAction { pause, resume, stop, showWindow, exitApp }

/// Projection of live timer state for secondary platform surfaces.
///
/// Elapsed display is derived from persisted anchors + wall clock — adapters
/// must not write the DB every second (ADR-009 / ADR-014).
final class TimerPlatformProjection {
  const TimerPlatformProjection({
    required this.skillId,
    required this.skillName,
    required this.machineState,
    required this.closedActiveSeconds,
    required this.openWorkStartUtc,
    required this.sessionId,
  });

  final String skillId;
  final String skillName;
  final TimerMachineState machineState;
  final String sessionId;

  /// Sum of closed work segments (and session.activeSeconds baseline).
  final int closedActiveSeconds;

  /// Open work segment start when [machineState] is running; else null.
  final DateTime? openWorkStartUtc;

  bool get isLive =>
      machineState == TimerMachineState.running ||
      machineState == TimerMachineState.paused;

  int displayActiveSeconds(DateTime nowUtc) {
    var total = closedActiveSeconds;
    final openStart = openWorkStartUtc;
    if (machineState == TimerMachineState.running && openStart != null) {
      final open = nowUtc.toUtc().difference(openStart.toUtc()).inSeconds;
      total += open < 0 ? 0 : open;
    }
    return total < 0 ? 0 : total;
  }
}

/// Android ongoing notification / FGS (ADR-016). Failures must not affect DB.
abstract class ForegroundTimerNotification {
  Future<void> ensureReady();

  Future<void> sync(TimerPlatformProjection projection);

  Future<void> clear();

  /// Emitted when Pause/Resume/Stop is pressed on the notification.
  Stream<TimerPlatformAction> get actions;

  /// Emitted when Android stops the FGS on timeout / exhaustion (session keeps running).
  Stream<void> get serviceTimeouts;

  Future<void> dispose();
}

/// Windows/Linux system tray while a session is live.
abstract class DesktopTrayService {
  Future<void> ensureReady();

  Future<void> sync(TimerPlatformProjection projection);

  Future<void> clear();

  Stream<TimerPlatformAction> get actions;

  Future<void> dispose();
}

/// Immersive timer chrome: landscape request + keep-awake while visible.
abstract class TimerChromeService {
  Future<void> enterTimerVisible({
    required bool keepScreenAwake,
    required bool requestLandscape,
  });

  Future<void> leaveTimerVisible();
}

/// Desktop window close / restore when a session is active.
abstract class DesktopWindowLifecycle {
  Future<void> ensureReady();

  /// When true, close should hide to tray instead of quitting.
  void setCloseToTray(bool enabled);

  Future<void> showAndFocus();

  Future<void> hideToTray();

  Future<void> destroyAndQuit();

  Stream<void> get closeRequested;

  Future<void> dispose();
}
