import 'dart:async';
import 'dart:io';

import 'package:tray_manager/tray_manager.dart';

import '../../core/time/duration_format.dart';
import '../../features/timer/domain/timer_enums.dart';
import '../../features/timer/domain/timer_platform_ports.dart';

/// Windows/Linux tray icon while a practice session is live.
final class PluginDesktopTrayService
    with TrayListener
    implements DesktopTrayService {
  PluginDesktopTrayService();

  final _actions = StreamController<TimerPlatformAction>.broadcast();
  var _ready = false;
  var _visible = false;
  Timer? _tick;
  TimerPlatformProjection? _current;

  @override
  Stream<TimerPlatformAction> get actions => _actions.stream;

  @override
  Future<void> ensureReady() async {
    if (!Platform.isWindows && !Platform.isLinux) return;
    if (_ready) return;
    trayManager.addListener(this);
    _ready = true;
  }

  @override
  Future<void> sync(TimerPlatformProjection projection) async {
    if (!Platform.isWindows && !Platform.isLinux) return;
    await ensureReady();
    _current = projection;
    _tick?.cancel();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      unawaited(_refreshTooltip());
    });

    try {
      if (!_visible) {
        await trayManager.setIcon(_iconPath());
        _visible = true;
      }
      await _setMenu(projection);
      await _refreshTooltip();
    } catch (_) {
      // Linux without appindicator: degrade — caller logs via coordinator.
      rethrow;
    }
  }

  @override
  Future<void> clear() async {
    _tick?.cancel();
    _tick = null;
    _current = null;
    if (!_visible) return;
    try {
      await trayManager.destroy();
    } catch (_) {}
    _visible = false;
  }

  @override
  Future<void> dispose() async {
    await clear();
    if (_ready) {
      trayManager.removeListener(this);
      _ready = false;
    }
    await _actions.close();
  }

  @override
  void onTrayIconMouseDown() {
    if (Platform.isWindows) {
      _actions.add(TimerPlatformAction.showWindow);
    } else {
      unawaited(trayManager.popUpContextMenu());
    }
  }

  @override
  void onTrayIconRightMouseDown() {
    unawaited(trayManager.popUpContextMenu());
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    switch (menuItem.key) {
      case 'pause':
        _actions.add(TimerPlatformAction.pause);
      case 'resume':
        _actions.add(TimerPlatformAction.resume);
      case 'stop':
        _actions.add(TimerPlatformAction.stop);
      case 'show':
        _actions.add(TimerPlatformAction.showWindow);
      case 'exit':
        _actions.add(TimerPlatformAction.exitApp);
    }
  }

  Future<void> _setMenu(TimerPlatformProjection projection) async {
    final items = <MenuItem>[
      MenuItem(key: 'show', label: 'Show Ayutam'),
      MenuItem.separator(),
      if (projection.machineState == TimerMachineState.running)
        MenuItem(key: 'pause', label: 'Pause')
      else if (projection.machineState == TimerMachineState.paused)
        MenuItem(key: 'resume', label: 'Resume'),
      MenuItem(key: 'stop', label: 'Stop'),
      MenuItem.separator(),
      MenuItem(key: 'exit', label: 'Exit'),
    ];
    await trayManager.setContextMenu(Menu(items: items));
  }

  Future<void> _refreshTooltip() async {
    final p = _current;
    if (p == null || !_visible) return;
    final now = DateTime.now().toUtc();
    final elapsed = formatActiveDuration(p.displayActiveSeconds(now));
    final phase = p.machineState == TimerMachineState.paused
        ? 'Paused'
        : 'Running';
    await trayManager.setToolTip('${p.skillName} · $phase · $elapsed');
  }

  String _iconPath() {
    if (Platform.isWindows) {
      return 'windows/runner/resources/app_icon.ico';
    }
    return 'branding/ayutam-logo.png';
  }
}
