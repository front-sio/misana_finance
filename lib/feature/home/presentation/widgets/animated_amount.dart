import 'package:flutter/material.dart';

class AnimatedAmount extends StatelessWidget {
  final double value;
  final TextStyle? style;

  const AnimatedAmount({
    super.key,
    required this.value,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Text(
        'TSh ${value.toStringAsFixed(2)}',
        style: style ?? const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
    );
  }
}