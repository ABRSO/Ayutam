import 'package:flutter/material.dart';

/// Fixed colourblind-considerate skill accents (Paul Tol–inspired hues).
abstract final class SkillAccentPalette {
  static const List<Color> colors = [
    Color(0xFF0077BB), // blue
    Color(0xFFEE7733), // orange
    Color(0xFF009988), // teal
    Color(0xFFCC3311), // vermillion
    Color(0xFF33BBEE), // cyan
    Color(0xFFEE3377), // magenta
    Color(0xFFBB5566), // rose
    Color(0xFFAAAA00), // olive
    Color(0xFF882255), // wine
    Color(0xFF44AA99), // muted teal
  ];

  static int toArgb(Color color) => color.toARGB32();

  static Color fromArgb(int? argb, {Color fallback = const Color(0xFF3E6355)}) {
    if (argb == null) {
      return fallback;
    }
    return Color(argb);
  }

  /// Picks the least-used palette colour among [usedArgb] values.
  static Color nextAccent(Iterable<int?> usedArgb) {
    final counts = <int, int>{};
    for (final color in colors) {
      counts[toArgb(color)] = 0;
    }
    for (final argb in usedArgb) {
      if (argb == null) {
        continue;
      }
      if (counts.containsKey(argb)) {
        counts[argb] = counts[argb]! + 1;
      }
    }
    var best = colors.first;
    var bestCount = counts[toArgb(best)] ?? 0;
    for (final color in colors.skip(1)) {
      final count = counts[toArgb(color)] ?? 0;
      if (count < bestCount) {
        best = color;
        bestCount = count;
      }
    }
    return best;
  }
}
