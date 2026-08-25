import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/learning_log/presentation/learning_log_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/skills/presentation/skills_screen.dart';
import '../features/statistics/presentation/statistics_screen.dart';
import 'ayutam_app.dart';
import 'providers.dart';

/// Primary destinations: Skills, Learning Log, Statistics, Settings.
///
/// Skills is the shell back root: system back (Android) or Escape (desktop)
/// on another tab returns to Skills; a second back from Skills exits.
/// Nested routes (Timer, detail, sheets) still pop first via the navigator.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  static const _destinations = <_NavDest>[
    _NavDest(
      label: 'Skills',
      icon: Icons.fitness_center_outlined,
      selectedIcon: Icons.fitness_center,
    ),
    _NavDest(
      label: 'Learning Log',
      icon: Icons.menu_book_outlined,
      selectedIcon: Icons.menu_book,
    ),
    _NavDest(
      label: 'Statistics',
      icon: Icons.insights_outlined,
      selectedIcon: Icons.insights,
    ),
    _NavDest(
      label: 'Settings',
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings,
    ),
  ];

  void _goHome() => ref.read(appShellIndexProvider.notifier).setIndex(0);

  /// Handles Escape before focused [TextField]s consume it. Nested routes and
  /// modal sheets still win: we only remap when this shell route is current.
  bool _onKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    if (event.logicalKey != LogicalKeyboardKey.escape) return false;
    if (!mounted) return false;

    final nav = ayutamNavigatorKey.currentState;
    if (nav != null && nav.canPop()) return false;

    if (ref.read(appShellIndexProvider) != 0) {
      _goHome();
      return true;
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_onKeyEvent);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKeyEvent);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final index = ref.watch(appShellIndexProvider);
    final width = MediaQuery.sizeOf(context).width;
    final useRail = width >= 840;
    final pages = const <Widget>[
      SkillsScreen(),
      LearningLogScreen(),
      StatisticsScreen(),
      SettingsScreen(),
    ];

    final shell = useRail
        ? Scaffold(
            // SafeArea keeps destinations clear of system bars; Scaffold
            // surface fills edge-to-edge behind the insets.
            body: SafeArea(
              child: Row(
                children: [
                  NavigationRail(
                    selectedIndex: index,
                    onDestinationSelected: (i) =>
                        ref.read(appShellIndexProvider.notifier).setIndex(i),
                    labelType: NavigationRailLabelType.all,
                    destinations: [
                      for (final d in _destinations)
                        NavigationRailDestination(
                          icon: Icon(d.icon),
                          selectedIcon: Icon(d.selectedIcon),
                          label: Text(d.label),
                        ),
                    ],
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(child: pages[index]),
                ],
              ),
            ),
          )
        : Scaffold(
            body: pages[index],
            bottomNavigationBar: NavigationBar(
              selectedIndex: index,
              onDestinationSelected: (i) =>
                  ref.read(appShellIndexProvider.notifier).setIndex(i),
              destinations: [
                for (final d in _destinations)
                  NavigationDestination(
                    icon: Icon(d.icon),
                    selectedIcon: Icon(d.selectedIcon),
                    label: d.label,
                  ),
              ],
            ),
          );

    return PopScope(
      canPop: index == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && index != 0) _goHome();
      },
      child: shell,
    );
  }
}

class _NavDest {
  const _NavDest({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}
