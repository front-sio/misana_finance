import 'dart:async';
import 'dart:math';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:misana_finance_app/core/theme/app_theme.dart';
import 'package:misana_finance_app/feature/session/auth_cubit.dart';
import 'package:misana_finance_app/feature/session/auth_state.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with TickerProviderStateMixin {
  Timer? _failSafeTimer;
  Timer? _messageTimer;
  
  late AnimationController _logoController;
  late AnimationController _backgroundController;
  late AnimationController _progressController;
  late AnimationController _messageController;
  
  late Animation<double> _logoFadeIn;
  late Animation<double> _logoScale;
  late Animation<double> _logoRotation;
  late Animation<double> _backgroundGradient;
  late Animation<double> _progressFade;
  late Animation<double> _textSlide;
  late Animation<double> _brandFade;
  late Animation<double> _messageFade;
  
  bool _showProgress = false;
  String _currentMessage = '';
  String _finalMessage = '';
  int _messageIndex = 0;
  bool _hasError = false;

  final List<String> _messages = [
    'Welcome to Misana Finance',
    'Securing your financial future',
    'Building wealth together',
    'Your trusted financial partner',
    'Empowering financial growth',
    'Creating prosperity for all',
    'Checking your session...',
  ];

  @override
  void initState() {
    super.initState();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FlutterNativeSplash.remove();
    });
    
    _initializeAnimations();
    _startAnimationSequence();
    _startMessageRotation();
    _checkSession();
  }

  void _initializeAnimations() {
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _backgroundController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );

    _progressController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _messageController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _logoFadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _logoScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.2, 0.8, curve: Curves.elasticOut),
      ),
    );

    _logoRotation = Tween<double>(begin: -0.2, end: 0.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.3, 0.9, curve: Curves.easeOutBack),
      ),
    );

    _backgroundGradient = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _backgroundController,
        curve: Curves.easeInOut,
      ),
    );

    _progressFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _progressController,
        curve: Curves.easeOut,
      ),
    );

    _textSlide = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _progressController,
        curve: Curves.easeOutCubic,
      ),
    );

    _brandFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _backgroundController,
        curve: const Interval(0.7, 1.0, curve: Curves.easeIn),
      ),
    );

    _messageFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _messageController,
        curve: Curves.easeInOut,
      ),
    );
  }

  void _startAnimationSequence() {
    _backgroundController.forward();
    
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _logoController.forward();
    });

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        setState(() => _showProgress = true);
        _progressController.forward();
      }
    });
  }

  void _startMessageRotation() {
    _updateMessage();
    _messageTimer = Timer.periodic(const Duration(milliseconds: 2000), (timer) {
      if (mounted && _messageIndex < _messages.length - 1 && _finalMessage.isEmpty) {
        _updateMessage();
      } else if (!mounted) {
        timer.cancel();
      }
    });
  }

  void _updateMessage() {
    if (!mounted || _finalMessage.isNotEmpty) return;
    
    _messageController.reverse().then((_) {
      if (mounted && _finalMessage.isEmpty) {
        setState(() {
          _currentMessage = _messages[_messageIndex];
          _messageIndex = min(_messageIndex + 1, _messages.length - 1);
        });
        _messageController.forward();
      }
    });
  }

  void _setFinalMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    
    developer.log('Setting final message: $message (error: $isError)', name: 'SplashPage');
    
    _messageTimer?.cancel();
    
    _messageController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _finalMessage = message;
          _currentMessage = message;
          _hasError = isError;
        });
        _messageController.forward();
      }
    });
  }

  String _getTimeBasedGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  void _checkSession() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      
      developer.log('Initiating session check from splash', name: 'SplashPage');
      context.read<AuthCubit>().checkSession();

      _failSafeTimer = Timer(const Duration(seconds: 15), () {
        if (!mounted) return;
        final state = context.read<AuthCubit>().state;
        if (state.checking) {
          developer.log('Failsafe timer triggered, retrying session check', name: 'SplashPage');
          _setFinalMessage('Taking longer than expected. Retrying...', isError: true);
          context.read<AuthCubit>().checkSession();
        }
      });
    });
  }

  @override
  void dispose() {
    _failSafeTimer?.cancel();
    _messageTimer?.cancel();
    _logoController.dispose();
    _backgroundController.dispose();
    _progressController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _navigateTo(String route) {
    if (!mounted) return;
    developer.log('Navigating to: $route', name: 'SplashPage');
    Navigator.of(context).pushNamedAndRemoveUntil(route, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    return Scaffold(
      body: BlocListener<AuthCubit, AuthState>(
        listenWhen: (prev, curr) =>
            prev.checking != curr.checking ||
            prev.authenticated != curr.authenticated ||
            prev.userMessage != curr.userMessage,
        listener: (context, state) {
          developer.log('Auth state changed - checking: ${state.checking}, authenticated: ${state.authenticated}', name: 'SplashPage');
          
          if (state.userMessage != null) {
            _setFinalMessage(state.userMessage!, isError: state.error != null);
          }
          
          if (!state.checking) {
            Future.delayed(const Duration(milliseconds: 1500), () {
              if (state.authenticated) {
                _navigateTo('/home');
              } else {
                _navigateTo('/login');
              }
            });
          }
        },
        child: AnimatedBuilder(
          animation: _backgroundController,
          builder: (context, child) {
            return Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color.lerp(
                      BrandColors.orange.withOpacity(0.8),
                      BrandColors.orange,
                      _backgroundGradient.value,
                    )!,
                    Color.lerp(
                      BrandColors.orange,
                      BrandColors.orange.withOpacity(0.9),
                      _backgroundGradient.value,
                    )!,
                    Color.lerp(
                      BrandColors.orange.withOpacity(0.9),
                      BrandColors.orange.withOpacity(0.7),
                      _backgroundGradient.value,
                    )!,
                  ],
                ),
              ),
              child: Stack(
                children: [
                  _buildBackgroundElements(size),
                  SafeArea(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isTablet ? 48.0 : 24.0,
                      ),
                      child: Column(
                        children: [
                          SizedBox(height: size.height * 0.12),
                          _buildGreetingSection(isTablet),
                          SizedBox(height: size.height * 0.04),
                          Expanded(
                            flex: 3,
                            child: _buildLogoSection(size, isTablet),
                          ),
                          Expanded(
                            flex: 1,
                            child: _buildProgressSection(isTablet),
                          ),
                          _buildBrandSection(isTablet),
                          SizedBox(height: size.height * 0.08),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildGreetingSection(bool isTablet) {
    return FadeTransition(
      opacity: _brandFade,
      child: Text(
        _getTimeBasedGreeting(),
        style: TextStyle(
          color: BrandColors.white.withOpacity(0.9),
          fontSize: isTablet ? 20 : 18,
          fontWeight: FontWeight.w300,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildBackgroundElements(Size size) {
    return AnimatedBuilder(
      animation: _backgroundController,
      builder: (context, child) {
        return Stack(
          children: [
            Positioned(
              top: -size.width * 0.15,
              left: -size.width * 0.15,
              child: Transform.scale(
                scale: 0.5 + (0.5 * _backgroundGradient.value),
                child: Container(
                  width: size.width * 0.4,
                  height: size.width * 0.4,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: BrandColors.white.withOpacity(0.08),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: size.height * 0.1,
              right: -size.width * 0.1,
              child: Transform.scale(
                scale: 0.7 + (0.3 * _backgroundGradient.value),
                child: Container(
                  width: size.width * 0.35,
                  height: size.width * 0.35,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: BrandColors.white.withOpacity(0.06),
                  ),
                ),
              ),
            ),
            Positioned(
              top: size.height * 0.25,
              right: size.width * 0.8,
              child: Transform.scale(
                scale: _backgroundGradient.value,
                child: Container(
                  width: size.width * 0.2,
                  height: size.width * 0.2,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: BrandColors.white.withOpacity(0.05),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLogoSection(Size size, bool isTablet) {
    return AnimatedBuilder(
      animation: _logoController,
      builder: (context, child) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FadeTransition(
                opacity: _logoFadeIn,
                child: ScaleTransition(
                  scale: _logoScale,
                  child: Transform.rotate(
                    angle: _logoRotation.value,
                    child: Container(
                      width: isTablet ? size.width * 0.25 : size.width * 0.35,
                      height: isTablet ? size.width * 0.25 : size.width * 0.35,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: BrandColors.white.withOpacity(0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Image.asset(
                          'assets/images/orange.svg',
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => Container(
                            decoration: BoxDecoration(
                              color: BrandColors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Icon(
                              Icons.account_balance_wallet_rounded,
                              size: isTablet ? 72 : 56,
                              color: BrandColors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: isTablet ? 32 : 24),
              FadeTransition(
                opacity: _logoFadeIn,
                child: Text(
                  'Misana Finance',
                  style: TextStyle(
                    color: BrandColors.white,
                    fontSize: isTablet ? 32 : 28,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    shadows: [
                      Shadow(
                        color: BrandColors.orange.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProgressSection(bool isTablet) {
    if (!_showProgress) return const SizedBox.shrink();
    
    return AnimatedBuilder(
      animation: _progressController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _progressFade,
          child: Transform.translate(
            offset: Offset(0, _textSlide.value),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!_hasError) ...[
                  SizedBox(
                    width: isTablet ? 40 : 32,
                    height: isTablet ? 40 : 32,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        BrandColors.white.withOpacity(0.9),
                      ),
                      backgroundColor: BrandColors.white.withOpacity(0.2),
                    ),
                  ),
                  SizedBox(height: isTablet ? 24 : 20),
                ] else ...[
                  Icon(
                    Icons.wifi_off_rounded,
                    size: isTablet ? 40 : 32,
                    color: BrandColors.white.withOpacity(0.9),
                  ),
                  SizedBox(height: isTablet ? 24 : 20),
                ],
                AnimatedBuilder(
                  animation: _messageController,
                  builder: (context, child) {
                    return FadeTransition(
                      opacity: _messageFade,
                      child: Text(
                        _currentMessage.isEmpty ? _messages[0] : _currentMessage,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: BrandColors.white.withOpacity(0.9),
                          fontSize: isTablet ? 18 : 16,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBrandSection(bool isTablet) {
    return AnimatedBuilder(
      animation: _backgroundController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _brandFade,
          child: Column(
            children: [
              Text(
                'Your Financial Journey Starts Here',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: BrandColors.white.withOpacity(0.8),
                  fontSize: isTablet ? 16 : 14,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.3,
                ),
              ),
              SizedBox(height: isTablet ? 12 : 8),
              Text(
                'Misana Stawi',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: BrandColors.white.withOpacity(0.7),
                  fontSize: isTablet ? 14 : 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}