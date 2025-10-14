import 'dart:ui';
import 'package:flutter/material.dart';

class SavingsHeaderGradient extends StatelessWidget {
  final String title;
  final String subtitle;
  const SavingsHeaderGradient({super.key, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.purple.shade800,
                Colors.deepPurple.shade600,
                Colors.deepPurple.shade900,
              ],
            ),
          ),
        ),
        Positioned(
          right: -30,
          top: -20,
          child: _BlurCircle(size: 160, color: Colors.white.withOpacity(0.08)),
        ),
        Positioned(
          left: -20,
          bottom: -30,
          child: _BlurCircle(size: 120, color: Colors.white.withOpacity(0.06)),
        ),
        Align(
          alignment: Alignment.bottomLeft,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 70, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _BlurCircle extends StatelessWidget {
  final double size;
  final Color color;
  const _BlurCircle({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(width: size, height: size, color: color),
      ),
    );
  }
}