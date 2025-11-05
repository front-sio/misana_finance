import 'package:flutter/material.dart';

class TabAnimationController {
  final AnimationController controller;
  late final Animation<double> fadeAnimation;
  late final Animation<Offset> slideAnimation;
  late final Animation<double> scaleAnimation;

  TabAnimationController({required TickerProvider vsync}) 
    : controller = AnimationController(
        duration: const Duration(milliseconds: 300),
        vsync: vsync,
      ) {
    final curved = CurvedAnimation(
      parent: controller,
      curve: Curves.easeOutCubic,
    );

    fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(curved);

    slideAnimation = Tween<Offset>(
      begin: const Offset(0.1, 0),
      end: Offset.zero,
    ).animate(curved);

    scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(curved);
  }

  void dispose() {
    controller.dispose();
  }

  void forward() => controller.forward();
  void reverse() => controller.reverse();
  void reset() => controller.reset();
}