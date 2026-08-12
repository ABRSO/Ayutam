import 'package:flutter_timezone/flutter_timezone.dart';

/// Returns the device IANA timezone id, or `UTC` if the plugin is unavailable.
Future<String> resolveDeviceIanaId() async {
  try {
    final info = await FlutterTimezone.getLocalTimezone();
    final id = info.identifier.trim();
    return id.isEmpty ? 'UTC' : id;
  } catch (_) {
    return 'UTC';
  }
}
