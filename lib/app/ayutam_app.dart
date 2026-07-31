import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_theme.dart';
import 'startup_gate.dart';

class AyutamApp extends StatelessWidget {
  const AyutamApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ayutam',
      debugShowCheckedModeBanner: false,
      theme: buildAyutamTheme(Brightness.light),
      darkTheme: buildAyutamTheme(Brightness.dark),
      themeMode: ThemeMode.system,
      home: const StartupGate(),
      navigatorKey: ayutamNavigatorKey,
      builder: (context, child) {
        final brightness = Theme.of(context).brightness;
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: ayutamSystemUiOverlayStyle(brightness),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}

final GlobalKey<NavigatorState> ayutamNavigatorKey =
    GlobalKey<NavigatorState>();
