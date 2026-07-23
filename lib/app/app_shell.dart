import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/learning_log/presentation/learning_log_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/skills/presentation/skills_screen.dart';
import '../features/statistics/presentation/statistics_screen.dart';

/// Primary destinations: Skills, Learning Log, Statistics, Settings.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _index = 0;

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

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final useRail = width >= 840;
    final pages = const <Widget>[
      SkillsScreen(),
      LearningLogScreen(),
      StatisticsScreen(),
      SettingsScreen(),
    ];

    if (useRail) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _index,
              onDestinationSelected: (i) => setState(() => _index = i),
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
            Expanded(child: pages[_index]),
          ],
        ),
      );
    }

    return Scaffold(
      body: pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
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
