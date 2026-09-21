import 'dart:async';

import '../features/timer/domain/timer_platform_ports.dart';

/// No-op notification used on non-Android and in tests (ADR-014).
class NoOpForegroundTimerNotification implements ForegroundTimerNotification {
  final _actions = StreamController<TimerPlatformAction>.broadcast();
  final _timeouts = StreamController<void>.broadcast();

  @override
  Stream<TimerPlatformAction> get actions => _actions.stream;

  @override
  Stream<void> get serviceTimeouts => _timeouts.stream;

  @override
  Future<void> ensureReady() async {}

  @override
  Future<void> sync(TimerPlatformProjection projection) async {}

  @override
  Future<void> clear() async {}

  @override
  Future<void> dispose() async {
    await _actions.close();
    await _timeouts.close();
  }

  /// Test helper: simulate a notification action.
  void emitAction(TimerPlatformAction action) => _actions.add(action);

  /// Test helper: simulate FGS timeout.
  void emitTimeout() => _timeouts.add(null);
}

class NoOpDesktopTrayService implements DesktopTrayService {
  final _actions = StreamController<TimerPlatformAction>.broadcast();
  var _available = false;

  @override
  Stream<TimerPlatformAction> get actions => _actions.stream;

  @override
  bool get isAvailable => _available;

  @override
  Future<void> ensureReady() async {}

  @override
  Future<void> sync(TimerPlatformProjection projection) async {
    _available = true;
  }

  @override
  Future<void> clear() async {
    _available = false;
  }

  @override
  Future<void> dispose() async {
    await _actions.close();
  }

  void emitAction(TimerPlatformAction action) => _actions.add(action);
}

final class NoOpTimerChromeService implements TimerChromeService {
  bool keepScreenAwakeActive = false;
  bool landscapeRequested = false;
  int enterCount = 0;

  @override
  Future<void> enterTimerVisible({
    required bool keepScreenAwake,
    required bool requestLandscape,
  }) async {
    enterCount++;
    keepScreenAwakeActive = keepScreenAwake;
    landscapeRequested = requestLandscape;
  }

  @override
  Future<void> leaveTimerVisible() async {
    keepScreenAwakeActive = false;
    landscapeRequested = false;
  }
}

final class NoOpDesktopWindowLifecycle implements DesktopWindowLifecycle {
  final _close = StreamController<void>.broadcast();
  bool closeToTray = false;

  @override
  Stream<void> get closeRequested => _close.stream;

  @override
  Future<void> ensureReady() async {}

  @override
  void setCloseToTray(bool enabled) {
    closeToTray = enabled;
  }

  @override
  Future<void> showAndFocus() async {}

  @override
  Future<void> hideToTray() async {}

  @override
  Future<void> destroyAndQuit() async {}

  @override
  Future<void> dispose() async {
    await _close.close();
  }

  void emitCloseRequested() => _close.add(null);
}
