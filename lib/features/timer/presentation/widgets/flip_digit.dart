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

/// Single split-flap digit with optional rotateX flip on change.
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
    this.showOwnCard = true,
  }) : assert(digit >= 0 && digit <= 9);

  final int digit;
  final double width;
  final double height;
  final Duration duration;
  final bool reduceMotion;
  final Color backgroundColor;
  final Color foregroundColor;

  /// When false, only the digit face is drawn (parent supplies the card chrome).
  final bool showOwnCard;

  @override
  State<FlipDigit> createState() => _FlipDigitState();
}

class _FlipDigitState extends State<FlipDigit>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late int _current;
  late int _next;

  @override
  void initState() {
    super.initState();
    _current = widget.digit;
    _next = widget.digit;
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          setState(() => _current = _next);
          _controller.value = 0;
        }
      });
  }

  @override
  void didUpdateWidget(covariant FlipDigit oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.digit == _next) {
      return;
    }
    final reduce =
        widget.reduceMotion || MediaQuery.disableAnimationsOf(context);
    if (reduce) {
      _controller.stop();
      setState(() {
        _current = widget.digit;
        _next = widget.digit;
      });
      return;
    }
    if (_controller.isAnimating) {
      _controller.stop();
      _current = _next;
    }
    setState(() => _next = widget.digit);
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  TextStyle get _textStyle => TextStyle(
    fontFamily: 'monospace',
    fontFeatures: const [FontFeature.tabularFigures()],
    fontWeight: FontWeight.w700,
    height: 1,
    color: widget.foregroundColor,
    fontSize: widget.height * 0.82,
  );

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final t = Curves.easeIn.transform(_controller.value);
            final flipping = _controller.isAnimating && _current != _next;
            final upperDigit = flipping ? _next : _current;
            final lowerDigit = flipping ? _current : _current;

            return Stack(
              fit: StackFit.expand,
              children: [
                _HalfClip(
                  isTop: true,
                  child: _DigitFace(
                    digit: upperDigit,
                    width: widget.width,
                    height: widget.height,
                    background: widget.backgroundColor,
                    textStyle: _textStyle,
                    showCard: widget.showOwnCard,
                  ),
                ),
                _HalfClip(
                  isTop: false,
                  child: _DigitFace(
                    digit: lowerDigit,
                    width: widget.width,
                    height: widget.height,
                    background: widget.backgroundColor,
                    textStyle: _textStyle,
                    showCard: widget.showOwnCard,
                  ),
                ),
                if (flipping && t < 0.5)
                  Transform(
                    alignment: Alignment.bottomCenter,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.0015)
                      ..rotateX(-t * math.pi),
                    child: _HalfClip(
                      isTop: true,
                      child: _DigitFace(
                        digit: _current,
                        width: widget.width,
                        height: widget.height,
                        background: widget.backgroundColor,
                        textStyle: _textStyle,
                        showCard: widget.showOwnCard,
                        shade: t * 0.35,
                      ),
                    ),
                  ),
                if (flipping && t >= 0.5)
                  Transform(
                    alignment: Alignment.topCenter,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.0015)
                      ..rotateX((1 - t) * math.pi),
                    child: _HalfClip(
                      isTop: false,
                      child: _DigitFace(
                        digit: _next,
                        width: widget.width,
                        height: widget.height,
                        background: Color.lerp(
                          widget.backgroundColor,
                          Colors.black,
                          0.22,
                        )!,
                        textStyle: _textStyle,
                        showCard: widget.showOwnCard,
                        shade: (1 - t) * 0.25,
                      ),
                    ),
                  ),
                if (widget.showOwnCard)
                  Align(
                    child: Container(
                      height: math.max(2, widget.height * 0.015),
                      color: FlipClockStyle.hinge,
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _HalfClip extends StatelessWidget {
  const _HalfClip({required this.isTop, required this.child});

  final bool isTop;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Align(
        alignment: isTop ? Alignment.topCenter : Alignment.bottomCenter,
        heightFactor: 0.5,
        child: child,
      ),
    );
  }
}

class _DigitFace extends StatelessWidget {
  const _DigitFace({
    required this.digit,
    required this.width,
    required this.height,
    required this.background,
    required this.textStyle,
    required this.showCard,
    this.shade = 0,
  });

  final int digit;
  final double width;
  final double height;
  final Color background;
  final TextStyle textStyle;
  final bool showCard;
  final double shade;

  @override
  Widget build(BuildContext context) {
    final text = Text('$digit', style: textStyle);
    final shaded = shade <= 0
        ? text
        : ColorFiltered(
            colorFilter: ColorFilter.mode(
              Colors.black.withValues(alpha: shade.clamp(0.0, 1.0)),
              BlendMode.srcATop,
            ),
            child: text,
          );

    return Container(
      width: width,
      height: height,
      decoration: showCard
          ? BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(math.max(6, width * 0.12)),
              border: Border.all(color: FlipClockStyle.cardEdge),
            )
          : BoxDecoration(color: background),
      alignment: Alignment.center,
      child: shaded,
    );
  }
}
