import 'dart:async';

import '../../../core/logging/app_logger.dart';
import '../domain/timer_platform_ports.dart';

/// Best-effort sync of notification + tray after DB commits (ADR-014).
///
/// Platform failures are logged and never rethrown into timer commands.
final class TimerPlatformCoordinator {
  TimerPlatformCoordinator({
    required ForegroundTimerNotification notification,
    required DesktopTrayService tray,
    required AppLogger logger,
  }) : _notification = notification,
       _tray = tray,
       _logger = logger;

  final ForegroundTimerNotification _notification;
  final DesktopTrayService _tray;
  final AppLogger _logger;

  final _actionController = StreamController<TimerPlatformAction>.broadcast();
  final _timeoutController = StreamController<void>.broadcast();

  StreamSubscription<TimerPlatformAction>? _notifActions;
  StreamSubscription<TimerPlatformAction>? _trayActions;
  StreamSubscription<void>? _timeouts;

  var _started = false;
  TimerPlatformProjection? _last;

  Stream<TimerPlatformAction> get actions => _actionController.stream;

  Stream<void> get serviceTimeouts => _timeoutController.stream;

  Future<void> start() async {
    if (_started) return;
    _started = true;
    try {
      await _notification.ensureReady();
    } catch (e, st) {
      _logger.warning(
        'Notification ensureReady failed: $e',
        error: e,
        stackTrace: st,
      );
    }
    try {
      await _tray.ensureReady();
    } catch (e, st) {
      _logger.warning('Tray ensureReady failed: $e', error: e, stackTrace: st);
    }
    _notifActions = _notification.actions.listen(_actionController.add);
    _trayActions = _tray.actions.listen(_actionController.add);
    _timeouts = _notification.serviceTimeouts.listen(_timeoutController.add);
  }

  Future<void> sync(TimerPlatformProjection? projection) async {
    _last = projection;
    if (projection == null || !projection.isLive) {
      await clear();
      return;
    }
    try {
      await _notification.sync(projection);
    } catch (e, st) {
      _logger.warning('Notification sync failed: $e', error: e, stackTrace: st);
    }
    try {
      await _tray.sync(projection);
    } catch (e, st) {
      _logger.warning('Tray sync failed: $e', error: e, stackTrace: st);
    }
  }

  Future<void> clear() async {
    _last = null;
    try {
      await _notification.clear();
    } catch (e, st) {
      _logger.warning(
        'Notification clear failed: $e',
        error: e,
        stackTrace: st,
      );
    }
    try {
      await _tray.clear();
    } catch (e, st) {
      _logger.warning('Tray clear failed: $e', error: e, stackTrace: st);
    }
  }

  TimerPlatformProjection? get lastProjection => _last;

  Future<void> dispose() async {
    await _notifActions?.cancel();
    await _trayActions?.cancel();
    await _timeouts?.cancel();
    await _actionController.close();
    await _timeoutController.close();
    await _notification.dispose();
    await _tray.dispose();
  }
}
