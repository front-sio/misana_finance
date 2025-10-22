import 'package:flutter/material.dart';
import 'package:misana_finance_app/screens/login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';


class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with TickerProviderStateMixin {
  final PageController _controller = PageController();
  int _page = 0;

  final List<_OnboardPage> _pages = [
    _OnboardPage(
      image: 'https://picsum.photos/seed/onboard1/800/600',
      title: 'Save Easily',
      subtitle: 'Create goals and reach them with small regular deposits.',
    ),
    _OnboardPage(
      image: 'https://picsum.photos/seed/onboard2/800/600',
      title: 'Smart Insights',
      subtitle: 'Track your progress and learn to save smarter.',
    ),
    _OnboardPage(
      image: 'https://picsum.photos/seed/onboard3/800/600',
      title: 'Secure & Fast',
      subtitle: 'Bank-grade security and smooth transactions.',
    ),
  ];

  late final AnimationController _fadeController;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fade = CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut);

    _controller.addListener(() {
      final page = (_controller.page ?? _controller.initialPage).round();
      if (page != _page) setState(() => _page = page);
    });
    _fadeController.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seenOnboarding', true);
  }

  void _goToNext() {
    if (_page == _pages.length - 1) {
      _completeOnboarding().then((_) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
      });
      return;
    }
    _controller.nextPage(duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLast = _page == _pages.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            PageView.builder(
              controller: _controller,
              itemCount: _pages.length,
              padEnds: true,
              itemBuilder: (_, index) {
                final p = _pages[index];
                return _OnboardCard(
                  page: p,
                  active: index == _page,
                );
              },
            ),
            // skip / indicator / next
            Positioned(
              left: 16,
              right: 16,
              bottom: 24,
              child: Row(
                children: [
                  TextButton(
                    onPressed: () {
                      _controller.animateToPage(_pages.length - 1,
                          duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
                    },
                    child: const Text('Skip', style: TextStyle(color: Colors.black54)),
                  ),
                  Expanded(
                    child: Center(
                      child: SmoothPageIndicator(
                        controller: _controller,
                        count: _pages.length,
                        effect: ExpandingDotsEffect(
                          activeDotColor: theme.colorScheme.primary,
                          dotColor: theme.colorScheme.onSurface.withOpacity(0.16),
                          dotHeight: 10,
                          dotWidth: 10,
                          expansionFactor: 3,
                          spacing: 8,
                        ),
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _goToNext,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(isLast ? 'Get Started' : 'Next'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardPage {
  final String image;
  final String title;
  final String subtitle;
  const _OnboardPage({required this.image, required this.title, required this.subtitle});
}

class _OnboardCard extends StatelessWidget {
  final _OnboardPage page;
  final bool active;
  const _OnboardCard({required this.page, required this.active});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final img = page.image;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      width: double.infinity,
      child: Column(
        children: [
          Expanded(
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 450),
              opacity: active ? 1.0 : 0.65,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(img, fit: BoxFit.cover, loadingBuilder: (c, child, progress) {
                      if (progress == null) return child;
                      return Container(
                        color: theme.colorScheme.surfaceVariant,
                        child: const Center(child: CircularProgressIndicator()),
                      );
                    }),
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.center,
                            colors: [theme.colorScheme.onPrimary.withOpacity(0.14), Colors.transparent],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 26),
          AnimatedSlide(
            duration: const Duration(milliseconds: 500),
            offset: active ? Offset.zero : const Offset(0, 0.1),
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 500),
              opacity: active ? 1 : 0.6,
              child: Column(
                children: [
                  Text(
                    page.title,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    page.subtitle,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}