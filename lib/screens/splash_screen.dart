import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:math';
import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _strokeController;
  late Animation<double> _strokeAnimation;

  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();

    // Stroke animation controller
    _strokeController =
        AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _strokeAnimation =
        Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
      parent: _strokeController,
      curve: Curves.easeInOut,
    ));

    // Glow animation controller
    _glowController =
        AnimationController(vsync: this, duration: const Duration(seconds: 1));
    _glowAnimation =
        Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));

    // Start stroke animation
    _strokeController.forward();
    _strokeController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _glowController.forward();
      }
    });

    // Navigate to onboarding after animation
    Future.delayed(const Duration(seconds: 4), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
    });
  }

  @override
  void dispose() {
    _strokeController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: AnimatedBuilder(
          animation: Listenable.merge([_strokeAnimation, _glowAnimation]),
          builder: (context, child) {
            return CustomPaint(
              painter: _LogoTracePainter(
                strokeProgress: _strokeAnimation.value,
                glowProgress: _glowAnimation.value,
              ),
              size: const Size(150, 150),
            );
          },
        ),
      ),
    );
  }
}

/// CustomPainter for tracing the savings icon
class _LogoTracePainter extends CustomPainter {
  final double strokeProgress;
  final double glowProgress;

  _LogoTracePainter({required this.strokeProgress, required this.glowProgress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final double scale = size.width / 100;

    // Define the "coin + piggy" path (approximation)
    Path path = Path();

    // Coin outer circle
    path.addOval(Rect.fromCircle(center: center, radius: 40 * scale));

    // Inner line for the dollar sign
    path.moveTo(center.dx, center.dy - 20 * scale);
    path.lineTo(center.dx, center.dy + 20 * scale);

    path.moveTo(center.dx - 10 * scale, center.dy - 10 * scale);
    path.lineTo(center.dx + 10 * scale, center.dy - 10 * scale);

    path.moveTo(center.dx - 10 * scale, center.dy + 10 * scale);
    path.lineTo(center.dx + 10 * scale, center.dy + 10 * scale);

    // Stroke paint
    final strokePaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    // Draw traced path
    final metrics = path.computeMetrics().toList();
    for (final metric in metrics) {
      final extractLength = metric.length * strokeProgress;
      final subPath = metric.extractPath(0, extractLength);
      canvas.drawPath(subPath, strokePaint);
    }

    // Glow fill
    if (glowProgress > 0) {
      final glowPaint = Paint()
        ..shader = RadialGradient(
          colors: [Colors.blue.withOpacity(glowProgress), Colors.transparent],
        ).createShader(Rect.fromCircle(center: center, radius: 40 * scale))
        ..style = PaintingStyle.fill;

      canvas.drawCircle(center, 40 * scale * glowProgress, glowPaint);
    }

    // Optional: draw icon in center for realism
    final iconSize = 60.0;
    final iconPainter = TextPainter(
      text: TextSpan(
        children: [
          WidgetSpan(
            child: Icon(Icons.savings, size: iconSize, color: Colors.blue.shade800),
          ),
        ],
      ),
      textDirection: TextDirection.ltr,
    );
    iconPainter.layout();
    iconPainter.paint(
        canvas, Offset(center.dx - iconPainter.width / 2, center.dy - iconSize/2));
  }

  @override
  bool shouldRepaint(covariant _LogoTracePainter oldDelegate) {
    return oldDelegate.strokeProgress != strokeProgress ||
        oldDelegate.glowProgress != glowProgress;
  }
}
