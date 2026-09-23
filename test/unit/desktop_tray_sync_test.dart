import 'dart:io';

import 'package:ayutam/features/timer/domain/timer_enums.dart';
import 'package:ayutam/features/timer/domain/timer_platform_ports.dart';
import 'package:ayutam/platform/desktop/plugin_desktop_tray_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const projection = TimerPlatformProjection(
    skillId: 'sk',
    skillName: 'QA Practice',
    machineState: TimerMachineState.running,
    closedActiveSeconds: 3,
    openWorkStartUtc: null,
    sessionId: 's1',
  );

  test(
    'failed tray sync stays unavailable and does not keep refreshing',
    () async {
      final tray = PluginDesktopTrayService();
      addTearDown(tray.dispose);

      await expectLater(
        tray.sync(projection),
        throwsA(isA<MissingPluginException>()),
      );
      expect(await tray.checkAvailable(), isFalse);
    },
  );

  test('a created tray icon still needs a Linux tray host', () async {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    const trayChannel = MethodChannel('tray_manager');
    const desktopChannel = MethodChannel('ayutam/desktop');
    var hostQueries = 0;
    messenger.setMockMethodCallHandler(trayChannel, (_) async => true);
    messenger.setMockMethodCallHandler(desktopChannel, (call) async {
      if (call.method == 'hasTrayHost') hostQueries++;
      return false;
    });
    addTearDown(() {
      messenger.setMockMethodCallHandler(trayChannel, null);
      messenger.setMockMethodCallHandler(desktopChannel, null);
    });
    final tray = PluginDesktopTrayService();
    addTearDown(tray.dispose);

    await tray.sync(projection);

    expect(await tray.checkAvailable(), Platform.isLinux ? isFalse : isTrue);
    expect(hostQueries, Platform.isLinux ? 1 : 0);
  });
}
