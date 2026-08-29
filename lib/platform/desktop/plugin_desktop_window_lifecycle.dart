import 'dart:async';
import 'dart:io';

import 'package:window_manager/window_manager.dart';

import '../../features/timer/domain/timer_platform_ports.dart';

/// Desktop window show/hide; close is always forwarded to the app host.
final class PluginDesktopWindowLifecycle
    with WindowListener
    implements DesktopWindowLifecycle {
  PluginDesktopWindowLifecycle();

  final _close = StreamController<void>.broadcast();
  var _ready = false;

  @override
  Stream<void> get closeRequested => _close.stream;

  @override
  Future<void> ensureReady() async {
    if (!Platform.isWindows && !Platform.isLinux) return;
    if (_ready) return;
    await windowManager.ensureInitialized();
    windowManager.addListener(this);
    await windowManager.setPreventClose(true);
    _ready = true;
  }

  @override
  void setCloseToTray(bool enabled) {
    // Host reads timer state when handling [closeRequested].
  }

  @override
  Future<void> showAndFocus() async {
    if (!_ready) return;
    await windowManager.show();
    await windowManager.focus();
    await windowManager.setSkipTaskbar(false);
  }

  @override
  Future<void> hideToTray() async {
    if (!_ready) return;
    await windowManager.hide();
    await windowManager.setSkipTaskbar(true);
  }

  @override
  Future<void> destroyAndQuit() async {
    if (!_ready) return;
    await windowManager.setPreventClose(false);
    await windowManager.destroy();
  }

  @override
  Future<void> dispose() async {
    if (_ready) {
      windowManager.removeListener(this);
      _ready = false;
    }
    await _close.close();
  }

  @override
  void onWindowClose() {
    _close.add(null);
  }
}
