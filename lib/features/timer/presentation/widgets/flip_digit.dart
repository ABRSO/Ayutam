import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Fliqlo-inspired colours for the flip clock (independent of Material seed).
abstract final class FlipClockStyle {
  static const Color card = Color(0xFF161616);
  static const Color digit = Color(0xFFE8E8E8);
  static const Color hinge = Color(0xFF050505);
  static const Color colon = Color(0xFFC8C8C8);
  static const Color cardEdge = Color(0xFF2C2C2C);
}

/// One mechanical flip-clock digit card.
///
/// Two-stage rotateX around the horizontal center hinge:
/// 1. Outgoing upper flap: 0 → π/2
/// 2. Incoming lower flap: π/2 → 0
///
/// Numerals never translate. Each half paints the **same full-size** digit face
/// (identical baseline) and clips with [OverflowBox] so parent half-height
/// constraints cannot squeeze the face (that bug produced duplicated fragments).
class FlipDigit extends StatefulWidget {
  const FlipDigit({
    super.key,
    required this.digit,
    required this.width,
    required this.height,
    this.duration = const Duration(milliseconds: 480),
    this.reduceMotion = false,
    this.backgroundColor = FlipClockStyle.card,
    this.foregroundColor = FlipClockStyle.digit,
  }) : assert(digit >= 0 && digit <= 9);

  final int digit;
  final double width;
  final double height;
  final Duration duration;
  final bool reduceMotion;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  State<FlipDigit> createState() => _FlipDigitState();
}

class _FlipDigitState extends State<FlipDigit>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _outgoingTop;
  late final Animation<double> _incomingBottom;

  late int _currentValue;
  late int _nextValue;
  bool _isAnimating = false;
  int? _pendingValue;

  static const double _perspective = 0.0015;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.digit;
    _nextValue = widget.digit;
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..addStatusListener(_onStatus);
    _outgoingTop = Tween<double>(begin: 0, end: math.pi / 2).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeInCubic),
      ),
    );
    _incomingBottom = Tween<double>(begin: math.pi / 2, end: 0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOutCubic),
      ),
    );
  }

  void _onStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || !mounted) {
      return;
    }
    setState(() {
      _currentValue = _nextValue;
      _isAnimating = false;
    });
    _controller.value = 0;
    final pending = _pendingValue;
    _pendingValue = null;
    if (pending != null && pending != _currentValue) {
      _beginFlip(pending);
    }
  }

  @override
  void didUpdateWidget(covariant FlipDigit oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.duration != oldWidget.duration) {
      _controller.duration = widget.duration;
    }
    if (widget.digit != oldWidget.digit) {
      _requestValue(widget.digit);
    }
  }

  void _requestValue(int value) {
    final reduce =
        widget.reduceMotion || MediaQuery.disableAnimationsOf(context);
    if (reduce) {
      _controller.stop();
      setState(() {
        _currentValue = value;
        _nextValue = value;
        _isAnimating = false;
        _pendingValue = null;
      });
      _controller.value = 0;
      return;
    }
    if (value == _nextValue && _isAnimating) {
      _pendingValue = null;
      return;
    }
    if (value == _currentValue && !_isAnimating) {
      return;
    }
    if (_isAnimating) {
      _pendingValue = value;
      return;
    }
    _beginFlip(value);
  }

  void _beginFlip(int value) {
    if (value == _currentValue) {
      return;
    }
    setState(() {
      _nextValue = value;
      _isAnimating = true;
    });
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.removeStatusListener(_onStatus);
    _controller.dispose();
    super.dispose();
  }

  double get _radius => math.max(6.0, widget.width * 0.14);

  TextStyle get _textStyle => TextStyle(
    fontFamily: 'monospace',
    fontFeatures: const [FontFeature.tabularFigures()],
    fontWeight: FontWeight.w700,
    height: 1.0,
    color: widget.foregroundColor,
    fontSize: widget.height * 0.78,
  );

  @override
  Widget build(BuildContext context) {
    final half = widget.height / 2;
    return ExcludeSemantics(
      child: RepaintBoundary(
        child: SizedBox(
          width: widget.width,
          height: widget.height,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final animating = _isAnimating && _currentValue != _nextValue;
              final phase1 = animating && _controller.value < 0.5;
              final phase2 = animating && _controller.value >= 0.5;

              final topValue = animating ? _nextValue : _currentValue;
              final bottomValue = animating ? _currentValue : _currentValue;

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: widget.width,
                    height: half,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _DigitHalf(
                          value: topValue,
                          isTop: true,
                          width: widget.width,
                          height: widget.height,
                          radius: _radius,
                          background: widget.backgroundColor,
                          textStyle: _textStyle,
                        ),
                        if (phase1)
                          Transform(
                            alignment: Alignment.bottomCenter,
                            filterQuality: FilterQuality.medium,
                            transform: Matrix4.identity()
                              ..setEntry(3, 2, _perspective)
                              ..rotateX(_outgoingTop.value),
                            child: _DigitHalf(
                              value: _currentValue,
                              isTop: true,
                              width: widget.width,
                              height: widget.height,
                              radius: _radius,
                              background: widget.backgroundColor,
                              textStyle: _textStyle,
                              shade: math.sin(_outgoingTop.value) * 0.45,
                            ),
                          ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: widget.width,
                    height: half,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _DigitHalf(
                          value: bottomValue,
                          isTop: false,
                          width: widget.width,
                          height: widget.height,
                          radius: _radius,
                          background: widget.backgroundColor,
                          textStyle: _textStyle,
                        ),
                        if (phase2)
                          Transform(
                            alignment: Alignment.topCenter,
                            filterQuality: FilterQuality.medium,
                            transform: Matrix4.identity()
                              ..setEntry(3, 2, _perspective)
                              ..rotateX(_incomingBottom.value),
                            child: _DigitHalf(
                              value: _nextValue,
                              isTop: false,
                              width: widget.width,
                              height: widget.height,
                              radius: _radius,
                              background: widget.backgroundColor,
                              textStyle: _textStyle,
                              shade: math.sin(_incomingBottom.value) * 0.45,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Renders a full-size digit face, then shows only the upper or lower half.
///
/// Critical: [OverflowBox] lets the face keep its full [height] even though the
/// parent layout slot is only `height / 2`. Without that, tight half-height
/// constraints shrink the face and both halves show the same glyph fragment.
class _DigitHalf extends StatelessWidget {
  const _DigitHalf({
    required this.value,
    required this.isTop,
    required this.width,
    required this.height,
    required this.radius,
    required this.background,
    required this.textStyle,
    this.shade = 0,
  });

  final int value;
  final bool isTop;
  final double width;
  final double height;
  final double radius;
  final Color background;
  final TextStyle textStyle;
  final double shade;

  @override
  Widget build(BuildContext context) {
    final halfHeight = height / 2;
    final borderRadius = isTop
        ? BorderRadius.vertical(top: Radius.circular(radius))
        : BorderRadius.vertical(bottom: Radius.circular(radius));

    final face = _FullDigitFace(
      value: value,
      width: width,
      height: height,
      background: background,
      textStyle: textStyle,
      shade: shade,
      hingeOnBottom: isTop,
    );

    return ClipRRect(
      borderRadius: borderRadius,
      clipBehavior: Clip.hardEdge,
      child: SizedBox(
        width: width,
        height: halfHeight,
        child: ClipRect(
          child: OverflowBox(
            alignment: isTop ? Alignment.topCenter : Alignment.bottomCenter,
            minWidth: width,
            maxWidth: width,
            minHeight: height,
            maxHeight: height,
            child: face,
          ),
        ),
      ),
    );
  }
}

/// Complete digit card in full coordinates (same size for every half).
class _FullDigitFace extends StatelessWidget {
  const _FullDigitFace({
    required this.value,
    required this.width,
    required this.height,
    required this.background,
    required this.textStyle,
    required this.hingeOnBottom,
    this.shade = 0,
  });

  final int value;
  final double width;
  final double height;
  final Color background;
  final TextStyle textStyle;
  final bool hingeOnBottom;
  final double shade;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: background,
          border: Border.all(color: FlipClockStyle.cardEdge, width: 1),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Custom paint keeps the glyph locked to the full-card center.
            CustomPaint(
              painter: _DigitPainter(value: value, style: textStyle),
            ),
            Align(
              alignment: hingeOnBottom
                  ? Alignment.bottomCenter
                  : Alignment.topCenter,
              child: Container(
                height: 1,
                color: FlipClockStyle.hinge.withValues(alpha: 0.9),
              ),
            ),
            if (shade > 0)
              ColoredBox(
                color: Colors.black.withValues(alpha: shade.clamp(0.0, 0.7)),
              ),
          ],
        ),
      ),
    );
  }
}

class _DigitPainter extends CustomPainter {
  _DigitPainter({required this.value, required this.style});

  final int value;
  final TextStyle style;

  @override
  void paint(Canvas canvas, Size size) {
    final painter = TextPainter(
      text: TextSpan(text: '$value', style: style),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout();
    final offset = Offset(
      (size.width - painter.width) / 2,
      (size.height - painter.height) / 2,
    );
    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _DigitPainter oldDelegate) {
    return oldDelegate.value != value || oldDelegate.style != style;
  }
}
