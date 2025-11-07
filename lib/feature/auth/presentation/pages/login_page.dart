import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';

import '../../../../core/i18n/locale_cubit.dart';
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

  // Inline i18n (LocaleCubit). Use listen:false when called from handlers/listeners.
  String _t(String key, {bool listen = true}) {
    final lang = listen
        ? context.watch<LocaleCubit>().state.languageCode
        : context.read<LocaleCubit>().state.languageCode;

    final sw = {
      'title': 'Misana Stawi',
      'subtitle': 'Ingia kwa barua pepe, simu au jina la mtumiaji',
      'identifier': 'Barua pepe, Simu au Jina la mtumiaji',
      'password': 'Nenosiri',
      'remember': 'Nikumbuke',
      'forgot': 'Umesahau Nenosiri?',
      'login': 'Ingia',
      'or': 'au',
      'register_q': 'Huna akaunti?',
      'register': 'Sajili',
      'inactive': 'Akaunti haijaamilishwa. Tafadhali thibitisha akaunti yako.',
      'verify': 'Thibitisha',
      'id_required': 'Tafadhali weka barua pepe, simu au jina la mtumiaji',
      'pw_required': 'Tafadhali weka nenosiri lako',
      'terms': 'Kwa kuendelea unakubali Masharti na Sera ya Faragha.',
      'language': 'Lugha',
      'swahili': 'Kiswahili',
      'english': 'Kiingereza',
      // Friendly error messages
      'network_error': 'Hujaunganishwa. Tafadhali angalia intaneti kisha jaribu tena.',
      'bad_credentials': 'Taarifa za kuingia si sahihi. Tafadhali jaribu tena.',
      'server_error': 'Hitilafu ya mfumo. Tafadhali jaribu tena baadaye.',
      'unknown_error': 'Hitilafu imetokea. Tafadhali jaribu tena.',
      'forbidden': 'Huna ruhusa ya kufanya hatua hii.',
      'not_found': 'Akaunti haikupatikana.',
      'too_many': 'Maombi mengi. Jaribu tena baadaye.',
    };
    final en = {
      'title': 'Misana Stawi',
      'subtitle': 'Login with email, phone, or username',
      'identifier': 'Email, Phone, or Username',
      'password': 'Password',
      'remember': 'Remember me',
      'forgot': 'Forgot Password?',
      'login': 'Login',
      'or': 'or',
      'register_q': 'Don’t have an account?',
      'register': 'Register',
      'inactive': 'Account not active. Please verify your account.',
      'verify': 'Verify',
      'id_required': 'Please enter email, phone, or username',
      'pw_required': 'Please enter your password',
      'terms': 'By continuing you agree to our Terms and Privacy Policy.',
      'language': 'Language',
      'swahili': 'Swahili',
      'english': 'English',
      // Friendly error messages
      'network_error': 'You appear offline. Please check your connection and try again.',
      'bad_credentials': 'Incorrect login details. Please try again.',
      'server_error': 'Server error. Please try again later.',
      'unknown_error': 'Something went wrong. Please try again.',
      'forbidden': 'You are not allowed to perform this action.',
      'not_found': 'Account not found.',
      'too_many': 'Too many requests. Please try again later.',
    };
    return (lang == 'sw' ? sw : en)[key] ?? key;
  }

  // Map technical errors to friendly messages for users
  String _humanizeError(Object? err) {
    try {
      if (err is DioException) {
        // Timeouts / connection issues
        if (err.type == DioExceptionType.connectionTimeout ||
            err.type == DioExceptionType.sendTimeout ||
            err.type == DioExceptionType.receiveTimeout ||
            err.type == DioExceptionType.connectionError) {
          return _t('network_error', listen: false);
        }
        final code = err.response?.statusCode ?? 0;
        switch (code) {
          case 400:
          case 422:
          case 401:
            return _t('bad_credentials', listen: false);
          case 403:
            return _t('forbidden', listen: false);
          case 404:
            return _t('not_found', listen: false);
          case 429:
            return _t('too_many', listen: false);
          default:
            if (code >= 500 && code <= 599) {
              return _t('server_error', listen: false);
            }
        }
      } else if (err is SocketException) {
        return _t('network_error', listen: false);
      }
    } catch (_) {
      // fallthrough to unknown
    }
    return _t('unknown_error', listen: false);
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
                      content: Text(_t('inactive', listen: false)),
                      action: SnackBarAction(
                        label: _t('verify', listen: false),
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
                          current: context.watch<LocaleCubit>().state.languageCode == 'sw' ? 'sw' : 'en',
                          onSelect: (v) => context.read<LocaleCubit>().setFromCode(v),
                          label: _t('language'),
                          swLabel: _t('swahili'),
                          enLabel: _t('english'),
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
                                      // const SizedBox(height: 14),
                                      // Text(
                                      //   _t('title'),
                                      //   textAlign: TextAlign.center,
                                      //   style: TextStyle(
                                      //     fontSize: wide ? 28 : 24,
                                      //     fontWeight: FontWeight.w800,
                                      //     color: scheme.onSurface,
                                      //   ),
                                      // ),
                                      const SizedBox(height: 6),
                                      Text(
                                        _t('subtitle'),
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
                                          label: _t('identifier'),
                                          icon: Icons.person_outline,
                                          keyboard: TextInputType.text,
                                          textInputAction: TextInputAction.next,
                                          validator: (v) => (v == null || v.trim().isEmpty)
                                              ? _t('id_required', listen: false)
                                              : null,
                                          onSubmitted: (_) => _pwFocus.requestFocus(),
                                        ),
                                        const SizedBox(height: 14),
                                        _TextForm(
                                          controller: passCtrl,
                                          focusNode: _pwFocus,
                                          label: _t('password'),
                                          icon: Icons.lock_outline,
                                          obscure: _obscure,
                                          suffix: IconButton(
                                            tooltip: _obscure ? "Show password" : "Hide password",
                                            onPressed: () => setState(() => _obscure = !_obscure),
                                            icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                                          ),
                                          validator: (v) => (v == null || v.trim().isEmpty)
                                              ? _t('pw_required', listen: false)
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
                                            Text(_t('remember')),
                                            const Spacer(),
                                            TextButton(
                                              onPressed: () => _toast("Coming soon"),
                                              child: Text(_t('forgot')),
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
                                                _t('login'),
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
                                        child: Text(_t('or'), style: TextStyle(color: scheme.onSurfaceVariant)),
                                      ),
                                      Expanded(child: Divider(color: scheme.outlineVariant)),
                                    ],
                                  ),
                                  const SizedBox(height: 14),

                                  // Register
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text("${_t('register_q')} "),
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
                                        child: Text(_t('register'),
                                            style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w800)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),

                                  // Footer small print
                                  Text(
                                    _t('terms'),
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