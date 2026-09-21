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
    // window_manager 0.5.2 leaves the Windows ITaskbarList3 null until this
    // call. setSkipTaskbar then dereferences it (access violation 0xc0000005).
    await windowManager.waitUntilReadyToShow();
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
    // Drop the skip-taskbar hint before mapping. A hidden window whose hint
    // is still set can stay unmapped when Show/Exit asks for it back.
    try {
      await windowManager.setSkipTaskbar(false);
    } catch (_) {}
    await windowManager.show();
    try {
      await windowManager.focus();
    } catch (_) {}
  }

  @override
  Future<void> hideToTray() async {
    if (!_ready) return;
    await windowManager.hide();
    try {
      await windowManager.setSkipTaskbar(true);
    } catch (_) {
      try {
        await windowManager.setSkipTaskbar(false);
      } catch (_) {}
      try {
        await windowManager.show();
      } catch (_) {}
      rethrow;
    }
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
