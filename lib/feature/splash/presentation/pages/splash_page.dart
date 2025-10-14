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

    // Kick off session check exactly once when Splash shows
    scheduleMicrotask(() {
      if (!mounted) return;
      context.read<AuthCubit>().checkSession();

      // Failsafe: if something hangs (e.g., network stall), bounce to login
      _failSafeTimer = Timer(const Duration(seconds: 12), () {
        if (!mounted) return;
        final s = context.read<AuthCubit>().state;
        if (s.checking) {
          _go('/login');
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
          // Decide where to go as soon as we have a result
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
              // Brand mark or logo placeholder
              Icon(Icons.savings_rounded, size: 64, color: cs.primary),
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