import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:misana_finance_app/feature/session/auth_cubit.dart';
import 'package:misana_finance_app/feature/session/auth_state.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  Timer? _failSafeTimer;

  @override
  void initState() {
    super.initState();
    // Kick off session check once
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AuthCubit>().checkSession();

      // Fail-safe: re-run check instead of forcing /login to avoid false logouts on slow refresh
      _failSafeTimer = Timer(const Duration(seconds: 12), () {
        if (!mounted) return;
        final s = context.read<AuthCubit>().state;
        if (s.checking) {
          // retry check instead of navigating
          context.read<AuthCubit>().checkSession();
        }
      });
    });
  }

  @override
  void dispose() {
    _failSafeTimer?.cancel();
    super.dispose();
  }

  void _go(String route) {
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(route, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
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
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/misana_orange.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: cs.primary.withOpacity(0.08),
                  child: Icon(Icons.savings_outlined, size: 40, color: cs.primary),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 2, color: cs.primary),
              ),
              const SizedBox(height: 12),
              Text(
                'Checking your session...',
                style: TextStyle(color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}