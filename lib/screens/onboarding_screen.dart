// lib/screens/onboarding_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  bool isLastPage = false;

  final List<Map<String, dynamic>> pages = [
    {
      "icon": Icons.savings_outlined,
      "title": "Save Easily",
      "subtitle": "Track your savings goals with ease."
    },
    {
      "icon": Icons.show_chart_outlined,
      "title": "Statistics",
      "subtitle": "Monitor your financial growth and progress."
    },
    {
      "icon": Icons.lock_outline,
      "title": "Secure",
      "subtitle": "Your money is safe with our encrypted system."
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // Decorative circles
          Positioned(top: -50, left: -50, child: _patternCircle(120, Colors.white.withOpacity(0.1))),
          Positioned(bottom: 100, right: -40, child: _patternCircle(160, Colors.white.withOpacity(0.08))),
          Positioned(top: 220, right: -60, child: _patternCircle(100, Colors.white.withOpacity(0.05))),

          // PageView
          PageView.builder(
            controller: _controller,
            itemCount: pages.length,
            onPageChanged: (index) => setState(() => isLastPage = (index == pages.length - 1)),
            itemBuilder: (_, index) {
              final page = pages[index];
              return _buildPage(page["icon"], page["title"], page["subtitle"]);
            },
          ),

          // Bottom navigation
          Align(
            alignment: Alignment.bottomCenter,
            child: isLastPage
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: GestureDetector(
                      onTap: () async {
                        await _completeOnboarding();
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                        );
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        height: 60,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          "Get Started",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ),
                  )
                : Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    height: 80,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          child: const Text("Skip", style: TextStyle(color: Colors.white, fontSize: 16)),
                          onPressed: () => _controller.jumpToPage(pages.length - 1),
                        ),
                        SmoothPageIndicator(
                          controller: _controller,
                          count: pages.length,
                          effect: ExpandingDotsEffect(
                            dotHeight: 10,
                            dotWidth: 10,
                            activeDotColor: Colors.white,
                            dotColor: Colors.white54,
                          ),
                        ),
                        TextButton(
                          child: const Text("Next", style: TextStyle(color: Colors.white, fontSize: 16)),
                          onPressed: () => _controller.nextPage(
                              duration: const Duration(milliseconds: 500), curve: Curves.easeInOut),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(IconData icon, String title, String subtitle) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            child: Icon(
              icon,
              key: ValueKey(icon),
              size: 100,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 30),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 600),
            child: Text(
              title,
              key: ValueKey(title),
              style: const TextStyle(
                  fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 15),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 700),
            child: Text(
              subtitle,
              key: ValueKey(subtitle),
              style: const TextStyle(fontSize: 18, color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _patternCircle(double size, Color color) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      );

  // Mark onboarding as complete
  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seenOnboarding', true);
  }
}
