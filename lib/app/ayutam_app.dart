import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_shell.dart';
import 'app_theme.dart';

class AyutamApp extends ConsumerWidget {
  const AyutamApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Ayutam',
      debugShowCheckedModeBanner: false,
      theme: buildAyutamTheme(Brightness.light),
      darkTheme: buildAyutamTheme(Brightness.dark),
      themeMode: ThemeMode.system,
      home: const AppShell(),
    );
  }
}
