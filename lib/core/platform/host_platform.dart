import 'dart:io' show Platform;

/// Stable platform id for backup manifests (`android` / `windows` / `linux`).
String hostPlatformId() {
  if (Platform.isAndroid) return 'android';
  if (Platform.isWindows) return 'windows';
  if (Platform.isLinux) return 'linux';
  return 'unknown';
}
