import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import '../../core/time/duration_format.dart';
import '../../features/timer/domain/timer_enums.dart';
import '../../features/timer/domain/timer_platform_ports.dart';

const _serviceId = 2601;
const _channelId = 'ayutam_timer';

/// Top-level entry for the FGS isolate (must stay top-level / static).
@pragma('vm:entry-point')
void ayutamForegroundTaskStartCallback() {
  FlutterForegroundTask.setTaskHandler(AyutamTimerTaskHandler());
}

/// Android FGS type: `specialUse` — deliberate-practice session timer with
/// Pause/Stop controls; not covered by health/media/dataSync (ADR-016).
final class AndroidForegroundTimerNotification
    implements ForegroundTimerNotification {
  AndroidForegroundTimerNotification();

  final _actions = StreamController<TimerPlatformAction>.broadcast();
  final _timeouts = StreamController<void>.broadcast();

  var _initialized = false;
  var _listening = false;

  @override
  Stream<TimerPlatformAction> get actions => _actions.stream;

  @override
  Stream<void> get serviceTimeouts => _timeouts.stream;

  @override
  Future<void> ensureReady() async {
    if (!Platform.isAndroid) return;
    if (!_listening) {
      FlutterForegroundTask.addTaskDataCallback(_onTaskData);
      _listening = true;
    }
    if (_initialized) return;

    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: _channelId,
        channelName: 'Practice timer',
        channelDescription:
            'Shows the running practice session with Pause and Stop.',
        onlyAlertOnce: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(1000),
        autoRunOnBoot: false,
        autoRunOnMyPackageReplaced: false,
        allowWakeLock: true,
        allowWifiLock: false,
      ),
    );
    _initialized = true;

    final permission =
        await FlutterForegroundTask.checkNotificationPermission();
    if (permission != NotificationPermission.granted) {
      await FlutterForegroundTask.requestNotificationPermission();
    }
  }

  @override
  Future<void> sync(TimerPlatformProjection projection) async {
    if (!Platform.isAndroid) return;
    await ensureReady();

    final buttons = <NotificationButton>[
      if (projection.machineState == TimerMachineState.running)
        const NotificationButton(id: 'pause', text: 'Pause')
      else if (projection.machineState == TimerMachineState.paused)
        const NotificationButton(id: 'resume', text: 'Resume'),
      const NotificationButton(id: 'stop', text: 'Stop'),
    ];

    final title = projection.skillName;
    final text = _notificationText(projection, DateTime.now().toUtc());
    final payload = _encodeProjection(projection);

    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.updateService(
        notificationTitle: title,
        notificationText: text,
        notificationButtons: buttons,
      );
      FlutterForegroundTask.sendDataToTask(payload);
      return;
    }

    await FlutterForegroundTask.startService(
      serviceId: _serviceId,
      serviceTypes: const [ForegroundServiceTypes.specialUse],
      notificationTitle: title,
      notificationText: text,
      notificationButtons: buttons,
      callback: ayutamForegroundTaskStartCallback,
    );
    FlutterForegroundTask.sendDataToTask(payload);
  }

  @override
  Future<void> clear() async {
    if (!Platform.isAndroid) return;
    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.stopService();
    }
  }

  @override
  Future<void> dispose() async {
    if (_listening) {
      FlutterForegroundTask.removeTaskDataCallback(_onTaskData);
      _listening = false;
    }
    await clear();
    await _actions.close();
    await _timeouts.close();
  }

  void _onTaskData(Object data) {
    if (data is! Map) return;
    final map = Map<String, dynamic>.from(data);
    final type = map['type'] as String?;
    if (type == 'action') {
      final id = map['id'] as String?;
      switch (id) {
        case 'pause':
          _actions.add(TimerPlatformAction.pause);
        case 'resume':
          _actions.add(TimerPlatformAction.resume);
        case 'stop':
          _actions.add(TimerPlatformAction.stop);
      }
    } else if (type == 'timeout') {
      _timeouts.add(null);
    }
  }
}

String _notificationText(TimerPlatformProjection p, DateTime nowUtc) {
  final elapsed = formatActiveDuration(p.displayActiveSeconds(nowUtc));
  final phase = p.machineState == TimerMachineState.paused
      ? 'Paused'
      : 'Running';
  return '$phase · $elapsed';
}

Map<String, dynamic> _encodeProjection(TimerPlatformProjection p) {
  return {
    'type': 'projection',
    'skillName': p.skillName,
    'machineState': p.machineState.name,
    'closedActiveSeconds': p.closedActiveSeconds,
    'openWorkStartUtcMs': p.openWorkStartUtc?.millisecondsSinceEpoch,
    'sessionId': p.sessionId,
  };
}

/// FGS isolate handler: refreshes elapsed text; forwards button presses.
final class AyutamTimerTaskHandler extends TaskHandler {
  String _skillName = 'Ayutam';
  String _machineState = TimerMachineState.running.name;
  int _closedActiveSeconds = 0;
  int? _openWorkStartUtcMs;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    final raw = await FlutterForegroundTask.getData<String>(key: 'projection');
    if (raw is String) {
      _applyJson(raw);
    }
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    final now = timestamp.toUtc();
    var total = _closedActiveSeconds;
    if (_machineState == TimerMachineState.running.name &&
        _openWorkStartUtcMs != null) {
      final open = now
          .difference(
            DateTime.fromMillisecondsSinceEpoch(
              _openWorkStartUtcMs!,
              isUtc: true,
            ),
          )
          .inSeconds;
      total += open < 0 ? 0 : open;
    }
    final phase = _machineState == TimerMachineState.paused.name
        ? 'Paused'
        : 'Running';
    FlutterForegroundTask.updateService(
      notificationTitle: _skillName,
      notificationText: '$phase · ${formatActiveDuration(total)}',
    );
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    if (isTimeout) {
      FlutterForegroundTask.sendDataToMain({'type': 'timeout'});
    }
  }

  @override
  void onReceiveData(Object data) {
    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      if (map['type'] == 'projection') {
        _applyMap(map);
        unawaited(
          FlutterForegroundTask.saveData(
            key: 'projection',
            value: jsonEncode(map),
          ),
        );
        onRepeatEvent(DateTime.now().toUtc());
      }
    } else if (data is String) {
      _applyJson(data);
    }
  }

  @override
  void onNotificationButtonPressed(String id) {
    FlutterForegroundTask.sendDataToMain({'type': 'action', 'id': id});
  }

  @override
  void onNotificationPressed() {
    FlutterForegroundTask.launchApp('/');
  }

  void _applyJson(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        _applyMap(Map<String, dynamic>.from(decoded));
      }
    } catch (_) {}
  }

  void _applyMap(Map<String, dynamic> map) {
    _skillName = (map['skillName'] as String?) ?? _skillName;
    _machineState = (map['machineState'] as String?) ?? _machineState;
    _closedActiveSeconds =
        (map['closedActiveSeconds'] as num?)?.toInt() ?? _closedActiveSeconds;
    _openWorkStartUtcMs = (map['openWorkStartUtcMs'] as num?)?.toInt();
  }
}
