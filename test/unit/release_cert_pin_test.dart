import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('pinned Android release certificate SHA-256 is well-formed', () {
    final pin = File('android/release-cert.sha256');
    expect(pin.existsSync(), isTrue);
    final fingerprints = pin
        .readAsLinesSync()
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty && !line.startsWith('#'))
        .toList();
    expect(fingerprints, hasLength(1));
    final hex = fingerprints.single.replaceAll(RegExp(r'[^0-9A-Fa-f]'), '');
    expect(hex.length, 64);
    expect(
      hex.toUpperCase(),
      '197CE383A63879E98CD1C72FDA5E83EFCF39FEECA04D17762F7313ADB8F92249',
    );
  });
}
