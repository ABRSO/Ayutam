import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'flip_digit.dart';

/// Split-flap duration display. Hours expand unbounded (min 2 digits).
///
/// Fliqlo-style: large charcoal unit panels (HH / MM / SS) with a shared hinge,
/// light digits, black immersive backdrop expected from the parent.
class FlipClock extends StatelessWidget {
  const FlipClock({
    super.key,
    required this.totalSeconds,
    this.digitWidth,
    this.digitHeight,
    this.spacing,
    this.reduceMotion,
    this.semanticLabel,
  });

  final int totalSeconds;
  final double? digitWidth;
  final double? digitHeight;
  final double? spacing;
  final bool? reduceMotion;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final reduce = reduceMotion ?? MediaQuery.disableAnimationsOf(context);
    final digits = flipClockDigits(totalSeconds);
    final label =
        semanticLabel ?? 'Duration ${formatFlipClockDuration(totalSeconds)}';
    final digitCount =
        digits.hours.length + digits.minutes.length + digits.seconds.length;

    return Semantics(
      label: label,
      readOnly: true,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final sized = _resolveSizes(
            constraints: constraints,
            digitCount: digitCount,
          );
          final w = digitWidth ?? sized.width;
          final h = digitHeight ?? sized.height;
          final gap = spacing ?? math.max(10.0, w * 0.16);
          final colonW = math.max(16.0, w * 0.5);

          return FittedBox(
            fit: BoxFit.contain,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _FlipUnit(
                  digits: digits.hours,
                  digitWidth: w,
                  digitHeight: h,
                  reduceMotion: reduce,
                ),
                SizedBox(width: gap * 0.35),
                _Colon(width: colonW, height: h),
                SizedBox(width: gap * 0.35),
                _FlipUnit(
                  digits: digits.minutes,
                  digitWidth: w,
                  digitHeight: h,
                  reduceMotion: reduce,
                ),
                SizedBox(width: gap * 0.35),
                _Colon(width: colonW, height: h),
                SizedBox(width: gap * 0.35),
                _FlipUnit(
                  digits: digits.seconds,
                  digitWidth: w,
                  digitHeight: h,
                  reduceMotion: reduce,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  static ({double width, double height}) _resolveSizes({
    required BoxConstraints constraints,
    required int digitCount,
  }) {
    final maxW = constraints.maxWidth.isFinite ? constraints.maxWidth : 900.0;
    final maxH = constraints.maxHeight.isFinite ? constraints.maxHeight : 320.0;

    // Slightly tall flaps; clock should dominate width.
    const aspect = 0.72;
    final widthFromW = (maxW * 0.88) / (digitCount + 1.2);
    var width = widthFromW;
    var height = width / aspect;
    if (height > maxH * 0.95) {
      height = maxH * 0.95;
      width = height * aspect;
    }
    return (width: width.clamp(48.0, 180.0), height: height.clamp(68.0, 260.0));
  }
}

class _FlipUnit extends StatelessWidget {
  const _FlipUnit({
    required this.digits,
    required this.digitWidth,
    required this.digitHeight,
    required this.reduceMotion,
  });

  final List<int> digits;
  final double digitWidth;
  final double digitHeight;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(math.max(10.0, digitWidth * 0.2));
    final padX = math.max(8.0, digitWidth * 0.1);
    final padY = math.max(6.0, digitHeight * 0.05);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: FlipClockStyle.card,
        borderRadius: radius,
        border: Border.all(color: FlipClockStyle.cardEdge, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.55),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: padX, vertical: padY),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final d in digits)
                  FlipDigit(
                    digit: d,
                    width: digitWidth,
                    height: digitHeight,
                    reduceMotion: reduceMotion,
                    showOwnCard: false,
                    backgroundColor: FlipClockStyle.card,
                  ),
              ],
            ),
          ),
          Positioned(
            left: 6,
            right: 6,
            child: Container(
              height: math.max(2.5, digitHeight * 0.016),
              decoration: BoxDecoration(
                color: FlipClockStyle.hinge,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.65),
                    blurRadius: 1.5,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Colon extends StatelessWidget {
  const _Colon({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final dot = math.max(7.0, height * 0.075);
    return ExcludeSemantics(
      child: SizedBox(
        width: width,
        height: height,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _Dot(size: dot),
            SizedBox(height: height * 0.18),
            _Dot(size: dot),
          ],
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: FlipClockStyle.colon,
        shape: BoxShape.circle,
      ),
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
