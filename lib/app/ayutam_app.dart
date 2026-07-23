import 'package:flutter/material.dart';

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
    );
  }
}

final GlobalKey<NavigatorState> ayutamNavigatorKey =
    GlobalKey<NavigatorState>();
