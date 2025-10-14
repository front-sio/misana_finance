import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../services/api_service.dart';
import 'home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final TextEditingController identifierCtrl = TextEditingController();
  final TextEditingController passCtrl = TextEditingController();
  final ApiService api = ApiService();

  bool isLoading = false;
  bool _obscure = true;

  late final AnimationController _bgController;
  LottieComposition? _loaderComposition; // optional: preload Lottie

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);

    // Preload lottie (optional) to reduce jank
    Lottie.asset('assets/loader.json', onLoaded: (c) {
      setState(() => _loaderComposition = c);
    });
  }

  @override
  void dispose() {
    _bgController.dispose();
    identifierCtrl.dispose();
    passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    // Guard double tap
    if (isLoading) return;

    final identifier = identifierCtrl.text.trim();
    final password = passCtrl.text.trim();

    if (identifier.isEmpty) {
      _toast("Please enter email, phone, or username");
      return;
    }
    if (password.isEmpty) {
      _toast("Please enter your password");
      return;
    }

    FocusScope.of(context).unfocus(); // close keyboard
    setState(() => isLoading = true);

    try {
      // Add timeout to avoid “loader kuganda”
      final user = await api.login(identifier, password).timeout(const Duration(seconds: 20));

      if (!mounted) return;
      // Prefer: stop loader before navigating to avoid setState-after-dispose
      setState(() => isLoading = false);

      // Navigate
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const HomeScreen(),
          transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 250),
        ),
      );
    } on TimeoutException {
      if (!mounted) return;
      setState(() => isLoading = false);
      _toast("Network slow. Please try again.");
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      _toast("Login failed: $e");
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isCompact = size.width < 360;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Animated soft background (very cheap)
          Positioned(
            top: -80,
            left: -50,
            child: AnimatedBuilder(
              animation: _bgController,
              builder: (context, child) => Transform.scale(
                scale: 0.9 + _bgController.value * 0.2,
                child: child,
              ),
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(color: Colors.blue.withOpacity(0.12), shape: BoxShape.circle),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            right: -60,
            child: AnimatedBuilder(
              animation: _bgController,
              builder: (context, child) => Transform.scale(
                scale: 0.9 + _bgController.value * 0.2,
                child: child,
              ),
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(color: Colors.blue.withOpacity(0.08), shape: BoxShape.circle),
              ),
            ),
          ),

          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480), // mobile-first, scales up nicely
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Logo
                    Center(child: Icon(Icons.savings, size: isCompact ? 64 : 80, color: Colors.blue)),
                    const SizedBox(height: 24),

                    // Title + Subtitle
                    Text(
                      "Welcome Back 👋",
                      style: TextStyle(
                        fontSize: isCompact ? 24 : 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text("Login with email, phone, or username",
                        style: TextStyle(fontSize: 16, color: Colors.black54)),
                    const SizedBox(height: 28),

                    // Identifier
                    _buildField(
                      controller: identifierCtrl,
                      label: "Email, Phone, or Username",
                      icon: Icons.person_outline,
                      keyboard: TextInputType.text,
                    ),
                    const SizedBox(height: 16),

                    // Password
                    _buildField(
                      controller: passCtrl,
                      label: "Password",
                      icon: Icons.lock_outline,
                      obscure: _obscure,
                      suffix: IconButton(
                        icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off, color: Colors.blue),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Forgot
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: isLoading ? null : () {/* TODO: reset password flow */},
                        child: const Text("Forgot Password?"),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Login button
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 6,
                        ),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: isLoading
                              ? (_loaderComposition != null
                                  ? Lottie(composition: _loaderComposition!, width: 44, height: 44, repeat: true)
                                  : const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                                    ))
                              : const Text("Login", style: TextStyle(fontSize: 18)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Register link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Don’t have an account? "),
                        TextButton(
                          onPressed: isLoading
                              ? null
                              : () {
                                  Navigator.push(
                                    context,
                                    PageRouteBuilder(
                                      pageBuilder: (_, __, ___) => const RegisterScreen(),
                                      transitionsBuilder: (_, anim, __, child) =>
                                          SlideTransition(position: Tween(begin: const Offset(1, 0), end: Offset.zero).animate(anim), child: child),
                                      transitionDuration: const Duration(milliseconds: 250),
                                    ),
                                  );
                                },
                          child: Text("Register", style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ),

          // Optional: full-screen modal overlay during loading (safer UX on slow devices)
          if (isLoading)
            IgnorePointer(
              ignoring: true,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                color: Colors.black.withOpacity(0.05),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboard,
    bool obscure = false,
    Widget? suffix,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboard,
      obscureText: obscure,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.blue),
        suffixIcon: suffix,
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      ),
    );
  }
}