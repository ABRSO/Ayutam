import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Windows runner quits only after WM_DESTROY tears the engine down', () {
    final main = File('windows/runner/main.cpp').readAsStringSync();
    expect(main, contains('window.SetQuitOnClose(true);'));
    expect(main, isNot(contains('SetQuitOnClose(false)')));
    expect(
      main.indexOf('window.Destroy();'),
      allOf(isNonNegative, lessThan(main.indexOf('::CoUninitialize();'))),
      reason: 'engine teardown must happen before COM is uninitialized',
    );
  });

  test('desktop quit closes the window instead of window_manager destroy', () {
    final adapter = File(
      'lib/platform/desktop/plugin_desktop_window_lifecycle.dart',
    ).readAsStringSync();
    expect(adapter, isNot(contains('await windowManager.destroy(')));
    expect(adapter, contains('await windowManager.setPreventClose(false);'));
    expect(adapter, contains('await windowManager.close();'));
  });

  test('Windows drop target never echoes a move effect', () {
    final plugin = File(
      'third_party/desktop_drop/windows/desktop_drop_plugin.cpp',
    ).readAsStringSync();
    expect(plugin, contains('DROPEFFECT_COPY'));
    expect(
      RegExp(r'\*pdwEffect = drop_effect_;').allMatches(plugin).length,
      3,
      reason: 'DragEnter, DragOver and Drop must all report the effect',
    );
  });
}
