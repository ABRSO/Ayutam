import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Single split-flap digit with optional rotateX flip on change.
class FlipDigit extends StatefulWidget {
  const FlipDigit({
    super.key,
    required this.digit,
    this.width = 56,
    this.height = 84,
    this.duration = const Duration(milliseconds: 450),
    this.reduceMotion = false,
    this.backgroundColor,
    this.foregroundColor,
    this.hingeColor,
  }) : assert(digit >= 0 && digit <= 9);

  final int digit;
  final double width;
  final double height;
  final Duration duration;
  final bool reduceMotion;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? hingeColor;

  @override
  State<FlipDigit> createState() => _FlipDigitState();
}

class _FlipDigitState extends State<FlipDigit>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late int _displayDigit;
  late int _previousDigit;

  @override
  void initState() {
    super.initState();
    _displayDigit = widget.digit;
    _previousDigit = widget.digit;
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          setState(() {
            _previousDigit = _displayDigit;
          });
          _controller.reset();
        }
      });
  }

  @override
  void didUpdateWidget(covariant FlipDigit oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.digit == _displayDigit) {
      return;
    }
    if (widget.reduceMotion || MediaQuery.disableAnimationsOf(context)) {
      setState(() {
        _displayDigit = widget.digit;
        _previousDigit = widget.digit;
      });
      _controller.reset();
      return;
    }
    setState(() {
      _previousDigit = _displayDigit;
      _displayDigit = widget.digit;
    });
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = widget.backgroundColor ?? scheme.surfaceContainerHighest;
    final fg = widget.foregroundColor ?? scheme.onSurface;
    final hinge = widget.hingeColor ?? scheme.outlineVariant;
    final half = widget.height / 2;
    final style = Theme.of(context).textTheme.displayMedium?.copyWith(
      fontFamily: 'monospace',
      fontFeatures: const [FontFeature.tabularFigures()],
      fontWeight: FontWeight.w600,
      height: 1,
      color: fg,
      fontSize: widget.height * 0.62,
    );

    return ExcludeSemantics(
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final t = Curves.fastOutSlowIn.transform(_controller.value);
            return Stack(
              alignment: Alignment.center,
              children: [
                _HalfPanel(
                  digit: _displayDigit,
                  isTop: true,
                  width: widget.width,
                  height: half,
                  background: bg,
                  textStyle: style,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(widget.width * 0.12),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  child: _HalfPanel(
                    digit: _controller.isAnimating
                        ? _previousDigit
                        : _displayDigit,
                    isTop: false,
                    width: widget.width,
                    height: half,
                    background: bg,
                    textStyle: style,
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(widget.width * 0.12),
                    ),
                  ),
                ),
                if (_controller.isAnimating && t < 0.5)
                  Positioned(
                    top: 0,
                    child: Transform(
                      alignment: Alignment.bottomCenter,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.002)
                        ..rotateX(-t * math.pi),
                      child: _HalfPanel(
                        digit: _previousDigit,
                        isTop: true,
                        width: widget.width,
                        height: half,
                        background: bg,
                        textStyle: style,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(widget.width * 0.12),
                        ),
                      ),
                    ),
                  ),
                if (_controller.isAnimating && t >= 0.5)
                  Positioned(
                    bottom: 0,
                    child: Transform(
                      alignment: Alignment.topCenter,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.002)
                        ..rotateX((1 - t) * math.pi),
                      child: _HalfPanel(
                        digit: _displayDigit,
                        isTop: false,
                        width: widget.width,
                        height: half,
                        background: Color.lerp(bg, Colors.black, 0.12)!,
                        textStyle: style,
                        borderRadius: BorderRadius.vertical(
                          bottom: Radius.circular(widget.width * 0.12),
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  left: 2,
                  right: 2,
                  child: Container(height: 1.5, color: hinge),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _HalfPanel extends StatelessWidget {
  const _HalfPanel({
    required this.digit,
    required this.isTop,
    required this.width,
    required this.height,
    required this.background,
    required this.textStyle,
    required this.borderRadius,
  });

  final int digit;
  final bool isTop;
  final double width;
  final double height;
  final Color background;
  final TextStyle? textStyle;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: SizedBox(
        width: width,
        height: height,
        child: ColoredBox(
          color: background,
          child: ClipRect(
            child: Align(
              alignment: isTop ? Alignment.bottomCenter : Alignment.topCenter,
              heightFactor: 0.5,
              child: SizedBox(
                height: height * 2,
                width: width,
                child: Center(child: Text('$digit', style: textStyle)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
