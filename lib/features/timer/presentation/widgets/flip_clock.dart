import 'package:flutter/material.dart';

import 'flip_digit.dart';

/// Split-flap duration display. Hours expand unbounded (min 2 digits).
class FlipClock extends StatelessWidget {
  const FlipClock({
    super.key,
    required this.totalSeconds,
    this.digitWidth = 56,
    this.digitHeight = 84,
    this.spacing = 6,
    this.reduceMotion,
    this.semanticLabel,
  });

  final int totalSeconds;
  final double digitWidth;
  final double digitHeight;
  final double spacing;
  final bool? reduceMotion;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final reduce = reduceMotion ?? MediaQuery.disableAnimationsOf(context);
    final digits = flipClockDigits(totalSeconds);
    final label =
        semanticLabel ?? 'Duration ${formatFlipClockDuration(totalSeconds)}';

    return Semantics(
      label: label,
      readOnly: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < digits.hours.length; i++) ...[
            if (i > 0) SizedBox(width: spacing),
            FlipDigit(
              digit: digits.hours[i],
              width: digitWidth,
              height: digitHeight,
              reduceMotion: reduce,
            ),
          ],
          _Colon(
            height: digitHeight,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          for (var i = 0; i < digits.minutes.length; i++) ...[
            if (i > 0) SizedBox(width: spacing),
            FlipDigit(
              digit: digits.minutes[i],
              width: digitWidth,
              height: digitHeight,
              reduceMotion: reduce,
            ),
          ],
          _Colon(
            height: digitHeight,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          for (var i = 0; i < digits.seconds.length; i++) ...[
            if (i > 0) SizedBox(width: spacing),
            FlipDigit(
              digit: digits.seconds[i],
              width: digitWidth,
              height: digitHeight,
              reduceMotion: reduce,
            ),
          ],
        ],
      ),
    );
  }
}

class _Colon extends StatelessWidget {
  const _Colon({required this.height, required this.color});

  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox(
        width: height * 0.35,
        height: height,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _Dot(color: color),
            SizedBox(height: height * 0.18),
            _Dot(color: color),
          ],
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

final class FlipClockDigits {
  const FlipClockDigits({
    required this.hours,
    required this.minutes,
    required this.seconds,
  });

  final List<int> hours;
  final List<int> minutes;
  final List<int> seconds;
}

/// Hours: at least 2 digits, unbounded. Minutes/seconds always 2 digits.
FlipClockDigits flipClockDigits(int totalSeconds) {
  final seconds = totalSeconds < 0 ? 0 : totalSeconds;
  final h = seconds ~/ 3600;
  final m = (seconds % 3600) ~/ 60;
  final s = seconds % 60;
  return FlipClockDigits(
    hours: _intToDigits(h, minWidth: 2),
    minutes: _intToDigits(m, minWidth: 2),
    seconds: _intToDigits(s, minWidth: 2),
  );
}

String formatFlipClockDuration(int totalSeconds) {
  final seconds = totalSeconds < 0 ? 0 : totalSeconds;
  final h = seconds ~/ 3600;
  final m = (seconds % 3600) ~/ 60;
  final s = seconds % 60;
  final hours = h.toString().padLeft(2, '0');
  return '$hours:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
}

List<int> _intToDigits(int value, {required int minWidth}) {
  final text = value.toString().padLeft(minWidth, '0');
  return [for (final c in text.codeUnits) c - 48];
}
