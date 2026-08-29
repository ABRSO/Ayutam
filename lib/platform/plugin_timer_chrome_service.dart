import 'dart:io';

import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../features/timer/domain/timer_platform_ports.dart';

/// Keep-awake + optional Android landscape while the timer route is visible.
final class PluginTimerChromeService implements TimerChromeService {
  var _entered = false;

  @override
  Future<void> enterTimerVisible({
    required bool keepScreenAwake,
    required bool requestLandscape,
  }) async {
    _entered = true;
    if (keepScreenAwake) {
      try {
        await WakelockPlus.enable();
      } catch (_) {}
    }
    if (requestLandscape && Platform.isAndroid) {
      try {
        await SystemChrome.setPreferredOrientations(const [
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
      } catch (_) {
        // OS may refuse; timer remains usable in portrait (ux-spec §4.3).
      }
    }
  }

  @override
  Future<void> leaveTimerVisible() async {
    if (!_entered) return;
    _entered = false;
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
  }
}
