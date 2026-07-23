import 'package:flutter/material.dart';

/// Icon-only timer control with tooltip, semantics, and ≥48×48 target.
class TimerIconControl extends StatelessWidget {
  const TimerIconControl({
    super.key,
    required this.tooltip,
    required this.semanticLabel,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final String semanticLabel;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: Tooltip(
        message: tooltip,
        child: SizedBox(
          width: 56,
          height: 56,
          child: IconButton.filledTonal(
            onPressed: onPressed,
            icon: Icon(icon, size: 28),
            style: IconButton.styleFrom(
              minimumSize: const Size(48, 48),
              fixedSize: const Size(56, 56),
              tapTargetSize: MaterialTapTargetSize.padded,
            ),
          ),
        ),
      ),
    );
  }
}
