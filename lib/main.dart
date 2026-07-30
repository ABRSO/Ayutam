import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app_theme.dart';
import 'app/ayutam_app.dart';
import 'bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    ayutamSystemUiOverlayStyle(Brightness.light),
  );
  final container = await bootstrap();
  runApp(
    UncontrolledProviderScope(container: container, child: const AyutamApp()),
  );
}
