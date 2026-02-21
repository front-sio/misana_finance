import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';
import 'package:misana_finance_app/core/i18n/locale_cubit.dart';

import 'package:misana_finance_app/core/i18n/localization_service.dart';
import 'package:misana_finance_app/auth/session/auth_cubit.dart';
import '../bloc/login/login_bloc.dart';
import '../bloc/login/login_event.dart';
import '../bloc/login/login_state.dart';
import 'register_page.dart';
import 'verify_account_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

/// Mobile-first, responsive login.
/// Adds language switcher and SAFE user-friendly errors (no technical messages).
class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController identifierCtrl = TextEditingController();
  final TextEditingController passCtrl = TextEditingController();
  final _idFocus = FocusNode();
  final _pwFocus = FocusNode();

  late AnimationController _bgCtrl;
  bool _obscure = true;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _bgCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 6))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    identifierCtrl.dispose();
    passCtrl.dispose();
    _idFocus.dispose();
    _pwFocus.dispose();
    super.dispose();
  }

  void _toast(String m) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  void _submit() {
    HapticFeedback.selectionClick();
    if (!_formKey.currentState!.validate()) return;

    final id = identifierCtrl.text.trim();
    final pw = passCtrl.text.trim();
    context.read<LoginBloc>().add(SubmitLogin(usernameOrEmail: id, password: pw));
  }

  // Map technical errors to friendly messages for users
  String _humanizeError(Object? err) {
    final lang = context.currentLanguage;
    try {
      if (err is DioException) {
        // Timeouts / connection issues
        if (err.type == DioExceptionType.connectionTimeout ||
            err.type == DioExceptionType.sendTimeout ||
            err.type == DioExceptionType.receiveTimeout ||
            err.type == DioExceptionType.connectionError) {
          return context.t('network_error');
        }
        final code = err.response?.statusCode ?? 0;
        switch (code) {
          case 400:
          case 422:
          case 401:
            return context.t('bad_credentials');
          case 403:
            return context.t('forbidden');
          case 404:
            return context.t('not_found');
          case 429:
            return context.t('too_many');
          default:
            if (code >= 500 && code <= 599) {
              return context.t('server_error');
            }
        }
      } else if (err is SocketException) {
        return context.t('network_error');
      }
    } catch (_) {
      // fallthrough to unknown
    }
    return context.t('unknown_error');
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: scheme.surface,
        body: SafeArea(
          child: BlocConsumer<LoginBloc, LoginState>(
            listener: (context, state) {
              if (state.error != null) {
                _toast(_humanizeError(state.error));
              } else if (state.userPayload != null) {
                if (state.inactive) {
                  final usernameOrEmail = identifierCtrl.text.trim();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(context.t('inactive')),
                      action: SnackBarAction(
                        label: context.t('verify'),
                        onPressed: () {
                          Navigator.of(context).push(
                            PageRouteBuilder(
                              pageBuilder: (_, __, ___) =>
                                  VerifyAccountPage(usernameOrEmail: usernameOrEmail),
                              transitionsBuilder: (_, anim, __, child) =>
                                  FadeTransition(opacity: anim, child: child),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                } else {
                  context.read<AuthCubit>().checkSession();
                  Navigator.of(context).pushReplacementNamed('/home');
                }
              }
            },
            builder: (context, state) {
              final loading = state.loading;

              return LayoutBuilder(
                builder: (ctx, constraints) {
                  final wide = constraints.maxWidth >= 640;

                  return Stack(
                    children: [
                      // Soft animated background shapes
                      Positioned(
                        top: -120,
                        left: -80,
                        child: AnimatedBuilder(
                          animation: _bgCtrl,
                          builder: (context, child) => Transform.scale(
                            scale: 0.9 + (_bgCtrl.value * 0.18),
                            child: child,
                          ),
                          child: Container(
                            width: 260,
                            height: 260,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: scheme.primary.withValues(alpha: 0.12),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: -140,
                        right: -100,
                        child: AnimatedBuilder(
                          animation: _bgCtrl,
                          builder: (context, child) => Transform.scale(
                            scale: 0.9 + ((1 - _bgCtrl.value) * 0.22),
                            child: child,
                          ),
                          child: Container(
                            width: 320,
                            height: 320,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: scheme.secondary.withValues(alpha: 0.10),
                            ),
                          ),
                        ),
                      ),

                      // Floating language switcher
                      Positioned(
                        top: 8,
                        right: 8,
                        child: _LangButton(
                          current: context.currentLanguage == 'sw' ? 'sw' : 'en',
                          onSelect: (v) => context.read<LocaleCubit>().setFromCode(v),
                          label: context.t('language'),
                          swLabel: context.t('swahili'),
                          enLabel: context.t('english'),
                        ),
                      ),

                      // Content
                      SingleChildScrollView(
                        padding: EdgeInsets.symmetric(
                          horizontal: wide ? 32 : 20,
                          vertical: wide ? 40 : 28,
                        ),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minHeight: constraints.maxHeight - (wide ? 80 : 56)),
                          child: Center(
                            child: Container(
                              constraints: const BoxConstraints(maxWidth: 520),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // App Logo + Title
                                  Column(
                                    children: [
                                      Hero(
                                        tag: 'app_logo',
                                        child: SizedBox(
                                          width: 100,
                                          height: 100,
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(20),
                                            child: Image.asset(
                                              'assets/images/misana_orange.png',
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) => Container(
                                                color: scheme.primary.withValues(alpha: 0.08),
                                                child: Icon(Icons.savings_outlined, size: 40, color: scheme.primary),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        context.t('subtitle'),
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: wide ? 16 : 14,
                                          color: scheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 28),

                                  // Form
                                  Form(
                                    key: _formKey,
                                    child: Column(
                                      children: [
                                        _TextForm(
                                          controller: identifierCtrl,
                                          focusNode: _idFocus,
                                          label: context.t('identifier'),
                                          icon: Icons.person_outline,
                                          keyboard: TextInputType.text,
                                          textInputAction: TextInputAction.next,
                                          validator: (v) => (v == null || v.trim().isEmpty)
                                              ? context.t('id_required')
                                              : null,
                                          onSubmitted: (_) => _pwFocus.requestFocus(),
                                        ),
                                        const SizedBox(height: 14),
                                        _TextForm(
                                          controller: passCtrl,
                                          focusNode: _pwFocus,
                                          label: context.t('password'),
                                          icon: Icons.lock_outline,
                                          obscure: _obscure,
                                          suffix: IconButton(
                                            tooltip: _obscure ? "Show password" : "Hide password",
                                            onPressed: () => setState(() => _obscure = !_obscure),
                                            icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                                          ),
                                          validator: (v) => (v == null || v.trim().isEmpty)
                                              ? context.t('pw_required')
                                              : null,
                                          onSubmitted: (_) => _submit(),
                                        ),
                                        const SizedBox(height: 6),

                                        // Remember + Forgot
                                        Row(
                                          children: [
                                            Checkbox.adaptive(
                                              value: _rememberMe,
                                              onChanged: (v) => setState(() => _rememberMe = v ?? false),
                                            ),
                                            Text(context.t('remember')),
                                            const Spacer(),
                                            TextButton(
                                              onPressed: () => _toast("Coming soon"),
                                              child: Text(context.t('forgot')),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 12),

                                  // Login button
                                  AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 250),
                                    child: loading
                                        ? Center(
                                            key: const ValueKey('loading'),
                                            child: Lottie.asset("assets/loading.json", width: 80, height: 80),
                                          )
                                        : SizedBox(
                                            key: const ValueKey('login_btn'),
                                            width: double.infinity,
                                            height: 54,
                                            child: ElevatedButton.icon(
                                              icon: const Icon(Icons.login),
                                              onPressed: _submit,
                                              label: Text(
                                                context.t('login'),
                                                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                                              ),
                                            ),
                                          ),
                                  ),
                                  const SizedBox(height: 18),

                                  // Divider
                                  Row(
                                    children: [
                                      Expanded(child: Divider(color: scheme.outlineVariant)),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 12),
                                        child: Text(context.t('or'), style: TextStyle(color: scheme.onSurfaceVariant)),
                                      ),
                                      Expanded(child: Divider(color: scheme.outlineVariant)),
                                    ],
                                  ),
                                  const SizedBox(height: 14),

                                  // Register
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text("${context.t('register_q')} "),
                                      GestureDetector(
                                        onTap: () {
                                          Navigator.of(context).push(
                                            PageRouteBuilder(
                                              pageBuilder: (_, __, ___) => const RegisterPage(),
                                              transitionsBuilder: (_, anim, __, child) => SlideTransition(
                                                position: Tween(begin: const Offset(1, 0), end: Offset.zero).animate(
                                                  CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
                                                ),
                                                child: FadeTransition(opacity: anim, child: child),
                                              ),
                                            ),
                                          );
                                        },
                                        child: Text(context.t('register'),
                                            style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w800)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),

                                  // Footer small print
                                  Text(
                                    context.t('terms'),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                                  ),
                                  const SizedBox(height: 16),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _LangButton extends StatelessWidget {
  final String current; // 'sw' or 'en'
  final void Function(String) onSelect;
  final String label;
  final String swLabel;
  final String enLabel;
  const _LangButton({
    required this.current,
    required this.onSelect,
    required this.label,
    required this.swLabel,
    required this.enLabel,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: PopupMenuButton<String>(
        tooltip: label,
        elevation: 3,
        position: PopupMenuPosition.under,
        icon: CircleAvatar(
          radius: 18,
          backgroundColor: scheme.primary.withValues(alpha: 0.12),
          child: Icon(Icons.language, color: scheme.primary),
        ),
        initialValue: current,
        onSelected: onSelect,
        itemBuilder: (ctx) => [
          PopupMenuItem(value: 'sw', child: Text("🇹🇿 $swLabel")),
          PopupMenuItem(value: 'en', child: Text("🇬🇧 $enLabel")),
        ],
      ),
    );
  }
}

class _TextForm extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String label;
  final IconData icon;
  final TextInputType? keyboard;
  final bool obscure;
  final Widget? suffix;
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;
  final void Function(String)? onSubmitted;

  const _TextForm({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboard,
    this.obscure = false,
    this.suffix,
    this.validator,
    this.textInputAction,
    this.onSubmitted,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboard,
      obscureText: obscure,
      textInputAction: textInputAction,
      onFieldSubmitted: onSubmitted,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: scheme.primary),
        suffixIcon: suffix,
        filled: true,
        fillColor: Theme.of(context).brightness == Brightness.light
            ? Colors.grey.shade100
            : scheme.surfaceContainerHighest.withValues(alpha: 0.4),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      ),
    );
  }
}
