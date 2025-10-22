import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:misana_finance_app/feature/session/auth_cubit.dart';
import 'package:misana_finance_app/feature/session/auth_state.dart';

// Brand colors as constants
class BrandColors {
  static const purple = Color(0xFF9E27B4);
  static const orange = Color(0xFFED702E);
  static const white = Color(0xFFFFFFFF);
  static const black = Color(0xFF111111);
  static const gray600 = Color(0xFF5F5F5F);
  static const gray300 = Color(0xFFE3E3E3);
}

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with SingleTickerProviderStateMixin {
  Timer? _failSafeTimer;
  late AnimationController _controller;
  late Animation<double> _fadeIn;
  late Animation<double> _scaleUp;
  late Animation<double> _slideUp;
  bool _showProgress = false;

  @override
  void initState() {
    super.initState();
    
    // Animation setup
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _scaleUp = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.7, curve: Curves.easeOutBack),
      ),
    );

    _slideUp = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    // Start animations
    _controller.forward().then((_) {
      if (mounted) {
        setState(() => _showProgress = true);
      }
    });

    // Session check
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AuthCubit>().checkSession();

      _failSafeTimer = Timer(const Duration(seconds: 12), () {
        if (!mounted) return;
        final s = context.read<AuthCubit>().state;
        if (s.checking) {
          context.read<AuthCubit>().checkSession();
        }
      });
    });
  }

  @override
  void dispose() {
    _failSafeTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _go(String route) {
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(route, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: BlocListener<AuthCubit, AuthState>(
        listenWhen: (prev, curr) =>
            prev.checking != curr.checking ||
            prev.authenticated != curr.authenticated,
        listener: (context, state) {
          if (!state.checking) {
            if (state.authenticated) {
              _go('/home');
            } else {
              _go('/login');
            }
          }
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                BrandColors.purple,
                BrandColors.purple.withOpacity(0.8),
                BrandColors.orange.withOpacity(0.9),
              ],
            ),
          ),
          child: SafeArea(
            child: Stack(
              children: [
                // Decorative circles
                Positioned(
                  top: -size.width * 0.2,
                  left: -size.width * 0.2,
                  child: Container(
                    width: size.width * 0.4,
                    height: size.width * 0.4,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: BrandColors.white.withOpacity(0.1),
                    ),
                  ),
                ),
                Positioned(
                  bottom: size.width * 0.1,
                  right: -size.width * 0.15,
                  child: Container(
                    width: size.width * 0.3,
                    height: size.width * 0.3,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: BrandColors.orange.withOpacity(0.15),
                    ),
                  ),
                ),
                
                // Main content
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo with animations
                      FadeTransition(
                        opacity: _fadeIn,
                        child: ScaleTransition(
                          scale: _scaleUp,
                          child: Image.asset(
                            'assets/images/misana_orange.png',
                            width: size.width * 0.4,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => Container(
                              width: size.width * 0.4,
                              height: size.width * 0.4,
                              decoration: BoxDecoration(
                                color: BrandColors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Icon(
                                Icons.savings_outlined,
                                size: 64,
                                color: BrandColors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      // Loading indicator and text with animations
                      if (_showProgress) ...[
                        FadeTransition(
                          opacity: _fadeIn,
                          child: Transform.translate(
                            offset: Offset(0, _slideUp.value),
                            child: Column(
                              children: [
                                const SizedBox(
                                  width: 32,
                                  height: 32,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(BrandColors.white),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Checking your session...',
                                  style: TextStyle(
                                    color: BrandColors.white.withOpacity(0.9),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                
                // Version text (optional)
                Positioned(
                  bottom: 24,
                  left: 0,
                  right: 0,
                  child: FadeTransition(
                    opacity: _fadeIn,
                    child: Text(
                      'Misana Finance',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: BrandColors.white.withOpacity(0.7),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}