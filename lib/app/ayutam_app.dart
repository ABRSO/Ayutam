import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/timer/presentation/session_heartbeat.dart';
import 'app_theme.dart';
import 'desktop_import_drop_target.dart';
import 'desktop_timer_shortcuts.dart';
import 'platform_integration_host.dart';
import 'providers.dart';
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
      home: const SessionHeartbeat(
        child: PlatformIntegrationHost(
          child: DesktopTimerShortcuts(
            child: DesktopImportDropTarget(child: StartupGate()),
          ),
        ),
      ),
      navigatorKey: ayutamNavigatorKey,
      scaffoldMessengerKey: ayutamScaffoldMessengerKey,
      builder: (context, child) {
        final brightness = Theme.of(context).brightness;
        return ReducedMotionScope(
          child: AnnotatedRegion<SystemUiOverlayStyle>(
            value: ayutamSystemUiOverlayStyle(brightness),
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
    );
  }
}

/// ORs the in-app Reduced Motion setting with the platform disable-animations flag.
class ReducedMotionScope extends ConsumerWidget {
  const ReducedMotionScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reduced = ref.watch(reducedMotionProvider).asData?.value ?? false;
    final media = MediaQuery.of(context);
    return MediaQuery(
      data: media.copyWith(
        disableAnimations: media.disableAnimations || reduced,
      ),
      child: child,
    );
  }
}

final GlobalKey<NavigatorState> ayutamNavigatorKey =
    GlobalKey<NavigatorState>();

/// Lets a route show a message that must outlive its own [Scaffold], such as
/// the reminder shown after leaving a still-running timer.
final GlobalKey<ScaffoldMessengerState> ayutamScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();
