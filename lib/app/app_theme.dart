import 'package:flutter/material.dart';

ThemeData buildAyutamTheme(Brightness brightness) {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF3E6355),
    brightness: brightness,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    visualDensity: VisualDensity.standard,
    appBarTheme: AppBarTheme(
      centerTitle: false,
      backgroundColor: colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 1,
    ),
    navigationBarTheme: NavigationBarThemeData(
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      indicatorColor: colorScheme.secondaryContainer,
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: colorScheme.surface,
      indicatorColor: colorScheme.secondaryContainer,
      selectedIconTheme: IconThemeData(color: colorScheme.onSecondaryContainer),
      unselectedIconTheme: IconThemeData(color: colorScheme.onSurfaceVariant),
    ),
  );
}
