import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import 'app/app_theme.dart';
import 'app/ayutam_app.dart';
import 'bootstrap.dart';
import 'core/time/iana_timezone_service.dart';
import 'platform/device_timezone.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isAndroid) {
    FlutterForegroundTask.initCommunicationPort();
  }
  if (Platform.isWindows || Platform.isLinux) {
    await windowManager.ensureInitialized();
  }
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    ayutamSystemUiOverlayStyle(Brightness.light),
  );
  final container = await bootstrap(
    timezones: IanaTimezoneService(ianaId: await resolveDeviceIanaId()),
  );
  runApp(
    UncontrolledProviderScope(container: container, child: const AyutamApp()),
  );
}
