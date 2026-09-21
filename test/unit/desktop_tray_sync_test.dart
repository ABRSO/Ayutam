import 'package:ayutam/features/timer/domain/timer_enums.dart';
import 'package:ayutam/features/timer/domain/timer_platform_ports.dart';
import 'package:ayutam/platform/desktop/plugin_desktop_tray_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'failed tray sync stays unavailable and does not keep refreshing',
    () async {
      final tray = PluginDesktopTrayService();
      addTearDown(tray.dispose);
      const projection = TimerPlatformProjection(
        skillId: 'sk',
        skillName: 'QA Practice',
        machineState: TimerMachineState.running,
        closedActiveSeconds: 3,
        openWorkStartUtc: null,
        sessionId: 's1',
      );

      await expectLater(
        tray.sync(projection),
        throwsA(isA<MissingPluginException>()),
      );
      expect(tray.isAvailable, isFalse);
    },
  );
}
