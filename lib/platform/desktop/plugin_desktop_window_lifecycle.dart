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
  var _quitting = false;

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

  /// Never use `windowManager.destroy()` here. On Windows it only posts
  /// WM_QUIT: the message loop stops while the engine is alive, the window
  /// shows "Not responding", and teardown crashes in flutter_windows.dll.
  /// A real close runs WM_DESTROY (Windows) / GTK window destruction (Linux)
  /// with the loop still pumping.
  @override
  Future<void> quit() async {
    if (_quitting) return;
    _quitting = true;
    // The isolate dies with the engine; if it is still running after this,
    // the close did not happen and Exit must still be honoured.
    Timer(const Duration(seconds: 5), () => exit(0));
    try {
      await windowManager.setPreventClose(false);
      await windowManager.close();
    } catch (_) {
      exit(0);
    }
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
    // quit() triggers one more close event; it must not re-enter the host.
    if (_quitting) return;
    _close.add(null);
  }
}
