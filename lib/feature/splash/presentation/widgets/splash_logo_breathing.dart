import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class BreathingLogo extends StatefulWidget {
  const BreathingLogo({super.key});

  @override
  State<BreathingLogo> createState() => _BreathingLogoState();
}

class _BreathingLogoState extends State<BreathingLogo>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1700),
      vsync: this,
    )..repeat(reverse: true);

    _scale = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );
    _opacity = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final logoSize = size.width * 0.32; // Responsive for mobile first

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacity.value,
          child: Transform.scale(
            scale: _scale.value,
            child: SvgPicture.asset(
              'assets/images/orange.svg',
              width: logoSize,
              height: logoSize,
              fit: BoxFit.contain,
              placeholderBuilder: (ctx) => Icon(
                Icons.account_balance_wallet_rounded,
                color: Colors.white70,
                size: logoSize * 0.7,
              ),
            ),
          ),
        );
      },
    );
  }
}