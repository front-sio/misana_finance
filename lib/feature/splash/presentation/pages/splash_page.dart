import 'dart:async';
import 'dart:math';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:misana_finance_app/core/theme/app_theme.dart';
import 'package:misana_finance_app/core/i18n/locale_extensions.dart';
import 'package:misana_finance_app/feature/session/auth_cubit.dart';
import 'package:misana_finance_app/feature/session/auth_state.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  Timer? _failSafeTimer;
  Timer? _messageTimer;
  
  late AnimationController _logoController;
  late AnimationController _backgroundController;
  late AnimationController _progressController;
  late AnimationController _messageController;
  late AnimationController _breatheController;
  late AnimationController _glowController;
  
  late Animation<double> _logoFadeIn;
  late Animation<double> _logoScale;
  late Animation<double> _backgroundGradient;
  late Animation<double> _progressFade;
  late Animation<double> _textSlide;
  late Animation<double> _brandFade;
  late Animation<double> _messageFade;
  late Animation<double> _breatheScale;
  late Animation<double> _glowPulse;
  
  bool _showProgress = false;
  String _currentMessage = '';
  String _finalMessage = '';
  int _messageIndex = 0;
  bool _hasError = false;

  // Messages will be loaded from localized strings
  List<String> get _messages => [
    context.welcomeToMisana,
    context.securingFuture,
    context.buildingWealth,
    context.trustedPartner,
    context.empoweringGrowth,
    context.creatingProsperity,
    context.checkingSession,
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

    _breatheController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    )..repeat(reverse: true);

    _glowController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..repeat(reverse: true);

    _logoFadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _logoScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.2, 1.0, curve: Curves.elasticOut),
      ),
    );

    _breatheScale = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(
        parent: _breatheController,
        curve: Curves.easeInOut,
      ),
    );

    _glowPulse = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(
        parent: _glowController,
        curve: Curves.easeInOut,
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
    
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _logoController.forward();
    });

    Future.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) {
        setState(() => _showProgress = true);
        _progressController.forward();
      }
    });
  }

  void _startMessageRotation() {
    _updateMessage();
    _messageTimer = Timer.periodic(const Duration(milliseconds: 2200), (timer) {
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
    if (hour < 12) return context.goodMorning;
    if (hour < 17) return context.goodAfternoon;
    return context.goodEvening;
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
          _setFinalMessage(context.takingLonger, isError: true);
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
    _breatheController.dispose();
    _glowController.dispose();
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
                      BrandColors.orange,
                      BrandColors.orange,
                      _backgroundGradient.value,
                    )!,
                    Color.lerp(
                      BrandColors.orange,
                      BrandColors.orange,
                      _backgroundGradient.value,
                    )!,
                    Color.lerp(
                      BrandColors.orange,
                      BrandColors.orange,
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
                          SizedBox(height: size.height * 0.1),
                          _buildGreetingSection(isTablet),
                          SizedBox(height: size.height * 0.05),
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
          color: BrandColors.white.withValues(alpha: 0.95),
          fontSize: isTablet ? 22 : 19,
          fontWeight: FontWeight.w300,
          letterSpacing: 0.8,
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
              top: -size.width * 0.2,
              left: -size.width * 0.2,
              child: Transform.scale(
                scale: 0.5 + (0.5 * _backgroundGradient.value),
                child: Container(
                  width: size.width * 0.5,
                  height: size.width * 0.5,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: BrandColors.white.withValues(alpha: 0.1),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: size.height * 0.05,
              right: -size.width * 0.15,
              child: Transform.scale(
                scale: 0.7 + (0.3 * _backgroundGradient.value),
                child: Container(
                  width: size.width * 0.45,
                  height: size.width * 0.45,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: BrandColors.white.withValues(alpha: 0.08),
                  ),
                ),
              ),
            ),
            Positioned(
              top: size.height * 0.3,
              right: size.width * 0.85,
              child: Transform.scale(
                scale: _backgroundGradient.value,
                child: Container(
                  width: size.width * 0.25,
                  height: size.width * 0.25,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: BrandColors.white.withValues(alpha: 0.06),
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
      animation: Listenable.merge([_logoController, _breatheController, _glowController]),
      builder: (context, child) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FadeTransition(
                opacity: _logoFadeIn,
                child: ScaleTransition(
                  scale: _logoScale,
                  child: AnimatedBuilder(
                    animation: _breatheController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _breatheScale.value,
                        child: Container(
                         
                          child: ClipOval(
                            child: Image.asset(
                              'assets/images/misana_white.png',
                              width: isTablet ? size.width * 0.35 : size.width * 0.45,
                              height: isTablet ? size.width * 0.35 : size.width * 0.45,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: isTablet ? size.width * 0.35 : size.width * 0.45,
                                height: isTablet ? size.width * 0.35 : size.width * 0.45,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: BrandColors.white.withValues(alpha: 0.15),
                                ),
                                child: Icon(
                                  Icons.account_balance_wallet_rounded,
                                  size: isTablet ? 100 : 80,
                                  color: BrandColors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              SizedBox(height: isTablet ? 40 : 32),
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
                    width: isTablet ? 44 : 36,
                    height: isTablet ? 44 : 36,
                    child: CircularProgressIndicator(
                      strokeWidth: 3.5,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        BrandColors.white.withValues(alpha: 0.95),
                      ),
                      backgroundColor: BrandColors.white.withValues(alpha: 0.25),
                    ),
                  ),
                  SizedBox(height: isTablet ? 28 : 24),
                ] else ...[
                  Icon(
                    Icons.wifi_off_rounded,
                    size: isTablet ? 44 : 36,
                    color: BrandColors.white.withValues(alpha: 0.95),
                  ),
                  SizedBox(height: isTablet ? 28 : 24),
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
                          color: BrandColors.white.withValues(alpha: 0.92),
                          fontSize: isTablet ? 19 : 17,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.6,
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
                context.financialJourney,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: BrandColors.white.withValues(alpha: 0.85),
                  fontSize: isTablet ? 17 : 15,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.4,
                ),
              ),
              SizedBox(height: isTablet ? 14 : 10),
              Text(
                context.misanaBrand,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: BrandColors.white.withValues(alpha: 0.75),
                  fontSize: isTablet ? 15 : 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
