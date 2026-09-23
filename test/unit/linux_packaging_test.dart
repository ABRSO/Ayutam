import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('linux .deb ships a hicolor icon and mentions portable backups', () {
    final script = File('tool/package_linux_deb.sh').readAsStringSync();
    expect(
      script,
      contains('/usr/share/icons/hicolor/256x256/apps/ayutam.png'),
    );
    expect(script, contains('linux/runner/resources/ayutam.png'));
    expect(script, contains('gtk-update-icon-cache'));
    expect(script, contains('.skilltracker'));
    expect(
      script,
      contains(
        'Ayutam tracks deliberate practice with a timer, Learning Log, statistics,',
      ),
    );
    expect(
      RegExp(
        r'^Depends:.*libayatana-appindicator3-1',
        multiLine: true,
      ).hasMatch(script),
      isTrue,
      reason:
          'tray_manager links the appindicator runtime and does not '
          'bundle it',
    );
    expect(
      File('.github/workflows/release.yml').readAsStringSync(),
      contains('libayatana-appindicator3-dev'),
    );
    expect(File('branding/ayutam-logo.png').existsSync(), isTrue);
    expect(File('linux/runner/resources/ayutam.png').existsSync(), isTrue);
    expect(File('windows/runner/resources/app_icon.ico').existsSync(), isTrue);
    expect(
      File(
        'android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png',
      ).existsSync(),
      isTrue,
    );
  });
}
