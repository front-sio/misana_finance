import 'package:flutter/material.dart';
import 'package:misana_finance_app/core/theme/app_theme.dart';
import 'package:misana_finance_app/core/i18n/locale_extensions.dart';
import 'package:misana_finance_app/feature/splash/presentation/pages/splash_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:misana_finance_app/feature/auth/presentation/pages/login_page.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> with TickerProviderStateMixin {
  final PageController _controller = PageController();
  int _page = 0;

  // Using placeholder images from Unsplash
  List<OnboardContent> _getPages() {
    return [
      OnboardContent(
        image: 'https://images.unsplash.com/photo-1579621970795-87facc2f976d',
        title: context.welcomeToMisanaOnboarding,
        subtitle: context.trustedPartnerOnboarding,
        backgroundColor: BrandColors.purple,
      ),
      OnboardContent(
        image: 'https://images.unsplash.com/photo-1554224155-6726b3ff858f',
        title: context.setYourGoals,
        subtitle: context.setYourGoalsDesc,
        backgroundColor: BrandColors.orange,
      ),
      OnboardContent(
        image: 'https://images.unsplash.com/photo-1565514020179-026b92b84bb6',
        title: context.saveFlexibly,
        subtitle: context.saveFlexiblyDesc,
        backgroundColor: BrandColors.purple,
      ),
      OnboardContent(
        image: 'https://images.unsplash.com/photo-1559526324-593bc073d938',
        title: context.trackProgress,
        subtitle: context.trackProgressDesc,
        backgroundColor: BrandColors.orange,
      ),
      OnboardContent(
        image: 'https://images.unsplash.com/photo-1563986768817-257bf91c5e9d',
        title: context.bankGradeSecurity,
        subtitle: context.bankGradeSecurityDesc,
        backgroundColor: BrandColors.purple,
      ),
    ];
  }

  late final AnimationController _fadeController;
  late final AnimationController _slideController;
  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeIn = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _controller.addListener(() {
      final page = (_controller.page ?? _controller.initialPage).round();
      if (page != _page) {
        setState(() => _page = page);
        _fadeController.reset();
        _slideController.reset();
        _fadeController.forward();
        _slideController.forward();
      }
    });

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seenOnboarding', true);
  }

  void _goToNext() {
    final pages = _getPages();
    if (_page == pages.length - 1) {
      _completeOnboarding().then((_) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          CustomPageTransition(page: const LoginPage()),
        );
      });
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = _getPages();
    final isLast = _page == pages.length - 1;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background color
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            decoration: BoxDecoration(
              color: pages[_page].backgroundColor,
            ),
          ),

          // Decorative elements
          _buildDecorations(),

          SafeArea(
            child: Column(
              children: [
                if (!isLast) _buildSkipButton(pages.length),
                
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    itemCount: pages.length,
                    itemBuilder: (context, index) {
                      final page = pages[index];
                      return OnboardingContentWidget(
                        content: page,
                        fadeAnimation: _fadeIn,
                        slideAnimation: _slideUp,
                      );
                    },
                  ),
                ),

                _buildNavigation(isLast, pages),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDecorations() {
    return Stack(
      children: [
        Positioned(
          top: -100,
          right: -100,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withAlpha(26),
            ),
          ),
        ),
        Positioned(
          bottom: -50,
          left: -50,
          child: Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withAlpha(20),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSkipButton(int pagesLength) {
    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: TextButton(
          onPressed: () => _controller.animateToPage(
            pagesLength - 1,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
          ),
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          ),
          child: Text(
            context.skip,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ),
      ),
    );
  }

  Widget _buildNavigation(bool isLast, List<OnboardContent> pages) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SmoothPageIndicator(
            controller: _controller,
            count: pages.length,
            effect: ExpandingDotsEffect(
              activeDotColor: Colors.white,
              dotColor: Colors.white.withAlpha(128),
              dotHeight: 8,
              dotWidth: 8,
              expansionFactor: 3,
              spacing: 6,
            ),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 180),
            child: ElevatedButton(
              onPressed: _goToNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: pages[_page].backgroundColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isLast ? context.getStarted : context.next,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (!isLast) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_rounded, size: 20),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardContent {
  final String image;
  final String title;
  final String subtitle;
  final Color backgroundColor;

  const OnboardContent({
    required this.image,
    required this.title,
    required this.subtitle,
    required this.backgroundColor,
  });
}

class OnboardingContentWidget extends StatelessWidget {
  final OnboardContent content;
  final Animation<double> fadeAnimation;
  final Animation<Offset> slideAnimation;

  const OnboardingContentWidget({
    super.key,
    required this.content,
    required this.fadeAnimation,
    required this.slideAnimation,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final imageSize = size.width * 0.7;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SlideTransition(
              position: slideAnimation,
              child: FadeTransition(
                opacity: fadeAnimation,
                child: Container(
                  width: imageSize,
                  height: imageSize,
                  constraints: BoxConstraints(
                    maxWidth: 400,
                    maxHeight: 400,
                    minWidth: 200,
                    minHeight: 200,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(40),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.network(
                      content.image,
                      fit: BoxFit.cover,
                      loadingBuilder: (_, child, progress) {
                        if (progress == null) return child;
                        return Container(
                          color: Colors.white.withAlpha(30),
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.white.withAlpha(30),
                        child: const Icon(
                          Icons.image_not_supported_outlined,
                          color: Colors.white54,
                          size: 48,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: size.height * 0.05),
            SlideTransition(
              position: slideAnimation,
              child: FadeTransition(
                opacity: fadeAnimation,
                child: Column(
                  children: [
                    Text(
                      content.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 300),
                      child: Text(
                        content.subtitle,
                        style: TextStyle(
                          color: Colors.white.withAlpha(230),
                          fontSize: 16,
                          height: 1.5,
                          letterSpacing: 0.3,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CustomPageTransition extends PageRouteBuilder {
  final Widget page;

  CustomPageTransition({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: const Duration(milliseconds: 800),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curve = Curves.easeOutCubic;
            
            final slideAnimation = Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: animation, curve: curve));

            final scaleAnimation = Tween<double>(
              begin: 0.9,
              end: 1.0,
            ).animate(CurvedAnimation(parent: animation, curve: curve));

            final fadeAnimation = Tween<double>(
              begin: 0.0,
              end: 1.0,
            ).animate(CurvedAnimation(parent: animation, curve: curve));

            return SlideTransition(
              position: slideAnimation,
              child: ScaleTransition(
                scale: scaleAnimation,
                child: FadeTransition(
                  opacity: fadeAnimation,
                  child: child,
                ),
              ),
            );
          },
        );
}