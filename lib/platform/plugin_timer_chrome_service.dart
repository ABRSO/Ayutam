import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../features/timer/domain/timer_platform_ports.dart';

/// Keep-awake + optional Android landscape while the timer route is visible.
final class PluginTimerChromeService
    with WidgetsBindingObserver
    implements TimerChromeService {
  var _entered = false;
  var _landscapePending = false;
  var _observing = false;
  var _generation = 0;
  Future<void> _tail = Future<void>.value();

  @override
  Future<void> enterTimerVisible({
    required bool keepScreenAwake,
    required bool requestLandscape,
  }) async {
    final generation = ++_generation;
    await _enqueue(() async {
      if (generation != _generation) return;
      _entered = true;
      if (keepScreenAwake) {
        try {
          await WakelockPlus.enable();
        } catch (_) {}
      } else {
        try {
          await WakelockPlus.disable();
        } catch (_) {}
      }
      if (requestLandscape && Platform.isAndroid) {
        _landscapePending = true;
        _ensureObserving();
      } else {
        _landscapePending = false;
      }
    });
    if (generation == _generation && _landscapePending) {
      _scheduleLandscape();
    }
  }

  @override
  Future<void> leaveTimerVisible() async {
    _generation++;
    _entered = false;
    _landscapePending = false;
    _stopObserving();
    await _enqueue(() async {
      try {
        await WakelockPlus.disable();
      } catch (_) {}
      try {
        await SystemChrome.setPreferredOrientations(const [
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
      } catch (_) {}
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _entered && _landscapePending) {
      _scheduleLandscape();
    }
  }

  /// Rotate only after a frame has been drawn and the activity is resumed.
  ///
  /// An acceptance run ANR'd on a focus-loss event while a forced landscape
  /// change left the window `waitingToShow` with no drawn frame (often beside
  /// the notification-permission activity). Waiting avoids stacking that
  /// rotation on top of another focus change.
  void _scheduleLandscape() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_applyLandscape());
    });
  }

  Future<void> _applyLandscape() async {
    await _enqueue(() async {
      if (!_entered || !_landscapePending || !Platform.isAndroid) return;
      final state = WidgetsBinding.instance.lifecycleState;
      if (state != null && state != AppLifecycleState.resumed) return;
      try {
        await SystemChrome.setPreferredOrientations(const [
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
      } catch (_) {
        // OS may refuse; timer remains usable in portrait (ux-spec §4.3).
      }
      if (_entered && _landscapePending) {
        _landscapePending = false;
      }
    });
  }

  void _ensureObserving() {
    if (_observing) return;
    WidgetsBinding.instance.addObserver(this);
    _observing = true;
  }

  void _stopObserving() {
    if (!_observing) return;
    WidgetsBinding.instance.removeObserver(this);
    _observing = false;
  }

  Future<void> _enqueue(Future<void> Function() action) {
    final run = _tail.then((_) => action());
    _tail = run.catchError((Object _) async {});
    return run;
  }
}
