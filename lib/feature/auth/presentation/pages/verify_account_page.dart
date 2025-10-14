import 'dart:io';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';

import '../../../../core/i18n/locale_cubit.dart';
import '../../domain/repositories/auth_repository.dart';
import '../bloc/verification/verification_bloc.dart';
import '../bloc/verification/verification_event.dart';
import '../bloc/verification/verification_state.dart';

class VerifyAccountPage extends StatefulWidget {
  final String usernameOrEmail;
  const VerifyAccountPage({super.key, required this.usernameOrEmail});

  @override
  State<VerifyAccountPage> createState() => _VerifyAccountPageState();
}

class _VerifyAccountPageState extends State<VerifyAccountPage> {
  VerifyChannel channel = VerifyChannel.email;

  // OTP: 6 vibox (mobile-first)
  static const int _otpLength = 6;
  late final List<TextEditingController> _otpCtrls;
  late final List<FocusNode> _otpNodes;
  bool _isPasting = false; // guard to avoid re-entrant onChanged loops
  bool _handledSuccessNavigation = false; // prevent double navigation (black screen)

  @override
  void initState() {
    super.initState();
    _otpCtrls = List.generate(_otpLength, (_) => TextEditingController());
    _otpNodes = List.generate(_otpLength, (_) => FocusNode());

    // Autofocus kisanduku cha kwanza kwa urahisi kwenye mobile
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_otpNodes.isNotEmpty) _otpNodes.first.requestFocus();
    });
  }

  @override
  void dispose() {
    for (final c in _otpCtrls) {
      c.dispose();
    }
    for (final f in _otpNodes) {
      f.dispose();
    }
    super.dispose();
  }

  // i18n (pass listen:false inside listeners/handlers)
  String _t(String key, {bool listen = true}) {
    final lang = listen
        ? context.watch<LocaleCubit>().state.languageCode
        : context.read<LocaleCubit>().state.languageCode;

    final sw = {
      'title': 'Thibitisha Akaunti',
      'helper': 'Chagua njia utakayopokea msimbo wa tarakimu 6 ili kuwasha akaunti yako.',
      'choose_channel': 'Chagua njia ya kutuma',
      'email': 'Barua pepe',
      'sms': 'SMS',
      'send_code': 'Tuma msimbo',
      'resend_in': 'Tuma tena baada ya',
      'seconds_short': 's',
      'enter_code': 'Weka msimbo wa uthibitisho',
      'code_label': 'Msimbo wa uthibitisho',
      'confirm': 'Thibitisha na Washa Akaunti',
      'sending_to': 'Inatumwa kwa',
      'sent_to': 'Imetumwa kwa',
      'verified_toast': '✅ Uthibitisho umekamilika! Sasa unaweza kuendelea.',
      'error_prefix': '❌',
      'registered_email': 'barua pepe iliyosajiliwa',
      'registered_phone': 'namba ya simu iliyosajiliwa',
      'change_language': 'Badili Lugha',
      'kiswahili_now': 'Kiswahili (Sasa)',
      'english_now': 'English (Current)',
      'paste_hint': 'Bandika msimbo',
      'clear': 'Futa',
      'destination': 'Inatumwa kwa',
      'sent': 'Imetumwa kwa',
      'tip_autofocus': 'Jaza tarakimu 6; kisanduku kinahamia chenyewe.',
      // Friendly error messages
      'network_error': 'Hujunganishwa. Tafadhali angalia intaneti kisha jaribu tena.',
      'code_invalid': 'Msimbo si sahihi au muda wake umeisha. Jaribu tena au omba msimbo mpya.',
      'server_error': 'Hitilafu ya mfumo. Tafadhali jaribu tena baadaye.',
      'unknown_error': 'Hitilafu imetokea. Tafadhali jaribu tena.',
      'forbidden': 'Huna ruhusa ya kufanya hatua hii.',
      'not_found': 'Hatukupata taarifa zako. Hakikisha umeweka taarifa sahihi.',
      'too_many': 'Maombi mengi. Tafadhali jaribu tena baadaye.',
    };
    final en = {
      'title': 'Verify Account',
      'helper': 'Choose how you want to receive a 6-digit code to activate your account.',
      'choose_channel': 'Choose delivery channel',
      'email': 'Email',
      'sms': 'SMS',
      'send_code': 'Send code',
      'resend_in': 'Resend in',
      'seconds_short': 's',
      'enter_code': 'Enter the verification code',
      'code_label': 'Verification code',
      'confirm': 'Confirm & Activate',
      'sending_to': 'Sending to',
      'sent_to': 'Sent to',
      'verified_toast': '✅ Verification complete! You can continue.',
      'error_prefix': '❌',
      'registered_email': 'registered email',
      'registered_phone': 'registered phone number',
      'change_language': 'Change Language',
      'kiswahili_now': 'Kiswahili',
      'english_now': 'English (Current)',
      'paste_hint': 'Paste code',
      'clear': 'Clear',
      'destination': 'Sending to',
      'sent': 'Sent to',
      'tip_autofocus': 'Enter 6 digits; boxes advance automatically.',
      // Friendly error messages
      'network_error': 'You appear offline. Please check your connection and try again.',
      'code_invalid': 'The code is incorrect or has expired. Please retry or request a new code.',
      'server_error': 'Server error. Please try again later.',
      'unknown_error': 'Something went wrong. Please try again.',
      'forbidden': 'You are not allowed to perform this action.',
      'not_found': 'We could not find your details. Please check and try again.',
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
            return _t('code_invalid', listen: false);
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

  void _switchLang(String v) => context.read<LocaleCubit>().setFromCode(v);

  void _sendCode() {
    context.read<VerificationBloc>().add(SendVerificationCode(channel, widget.usernameOrEmail));
  }

  void _confirmCode() {
    final code = _currentOtp();
    if (code.length != _otpLength) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_t('enter_code', listen: false))),
      );
      return;
    }
    context.read<VerificationBloc>().add(ConfirmVerificationCode(channel, widget.usernameOrEmail, code));
  }

  bool _looksLikeEmail(String value) => value.contains('@') && value.contains('.');
  bool _looksLikePhone(String value) => RegExp(r'^\+?\d{6,}$').hasMatch(value);

  String _maskEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return email;
    final name = parts[0];
    final domain = parts[1];
    if (name.isEmpty) return '***@$domain';
    if (name.length == 1) return '${name[0]}***@$domain';
    final head = name.substring(0, min(2, name.length));
    return '$head***@$domain';
  }

  String _maskPhone(String phone) {
    final p = phone.replaceAll(' ', '');
    if (p.length <= 4) return p;
    final startLen = p.startsWith('+') ? 4 : 2;
    final start = p.substring(0, min(startLen, p.length - 2));
    final end = p.substring(p.length - 2);
    return '$start***$end';
  }

  String _destinationForChannel() {
    final id = widget.usernameOrEmail.trim();
    if (channel == VerifyChannel.email) {
      if (_looksLikeEmail(id)) return _maskEmail(id);
      return _t('registered_email');
    } else {
      if (_looksLikePhone(id)) return _maskPhone(id);
      return _t('registered_phone');
    }
  }

  // --- OTP helpers ---
  String _currentOtp() => _otpCtrls.map((c) => c.text).join();

  bool get _otpComplete => _otpCtrls.every((c) => c.text.length == 1);

  void _handleOtpChanged(int index, String raw) {
    if (_isPasting) return; // ignore while distributing
    final digitsOnly = raw.replaceAll(RegExp(r'\D'), '');

    // If user pasted many digits into one box (Android/iOS paste)
    if (digitsOnly.length > 1) {
      _applyBulkPaste(digitsOnly);
      return;
    }

    // Single character flow
    if (digitsOnly.isEmpty) {
      // keep empty; do not auto-move
      _otpCtrls[index].text = '';
      setState(() {});
      return;
    }

    // Avoid redundant set loops
    if (_otpCtrls[index].text != digitsOnly[0]) {
      _otpCtrls[index].text = digitsOnly[0];
      _otpCtrls[index].selection = const TextSelection.collapsed(offset: 1);
    }

    // Move to next automatically (mobile-friendly)
    if (index < _otpLength - 1) {
      _otpNodes[index + 1].requestFocus();
    } else {
      _otpNodes[index].unfocus();
    }
    setState(() {});
  }

  void _applyBulkPaste(String digits) {
    _isPasting = true;
    final d = digits.replaceAll(RegExp(r'\D'), '');
    final take = d.substring(0, min(_otpLength, d.length));
    for (int i = 0; i < _otpLength; i++) {
      final ch = i < take.length ? take[i] : '';
      _otpCtrls[i].text = ch;
      _otpCtrls[i].selection = TextSelection.collapsed(offset: ch.length);
    }
    // focus next empty or unfocus when complete
    final firstEmpty = _otpCtrls.indexWhere((c) => c.text.isEmpty);
    if (firstEmpty == -1) {
      _otpNodes.last.unfocus();
    } else {
      _otpNodes[firstEmpty].requestFocus();
    }
    _isPasting = false;
    setState(() {});
  }

  // Clear all OTP inputs
  void _clearOtp() {
    for (final c in _otpCtrls) {
      c.text = '';
    }
    if (_otpNodes.isNotEmpty) {
      _otpNodes.first.requestFocus();
    }
    setState(() {});
  }

  // Robust navigation after success: always go to a safe landing route
  // to avoid leaving Navigator with an empty stack (black screen).
  Future<void> _navigateAfterSuccess() async {
    if (_handledSuccessNavigation) return;
    _handledSuccessNavigation = true;

    if (!mounted) return;
    // Give the snackbar a tiny moment to display
    await Future<void>.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;

    // Decide your landing route. For activation flows, login is typical.
    // Change to '/home' if your product wants to continue inside the app.
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    final scheme = Theme.of(context).colorScheme;
    final isSw = context.watch<LocaleCubit>().state.languageCode == 'sw';

    // Mobile-first sizing
    final w = MediaQuery.of(context).size.width;
    final maxCardWidth = min<double>(w - 24, 520);
    const horizontalPadding = 16.0;
    const spacing = 8.0;

    // OTP box size responsive for mobile
    final available = maxCardWidth - (horizontalPadding * 2) - (spacing * (_otpLength - 1));
    final boxSize = max(46.0, min(56.0, available / _otpLength));

    return Scaffold(
      appBar: AppBar(
        title: Text(_t('title')),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            tooltip: _t('change_language'),
            icon: const Icon(Icons.language),
            onSelected: _switchLang,
            itemBuilder: (ctx) => [
              PopupMenuItem(value: 'sw', child: Text(isSw ? _t('kiswahili_now') : 'Kiswahili')),
              PopupMenuItem(value: 'en', child: Text(isSw ? 'Kiingereza' : _t('english_now'))),
            ],
          ),
        ],
      ),
      body: BlocConsumer<VerificationBloc, VerificationState>(
        listener: (context, state) async {
          if (state.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(_humanizeError(state.error))),
            );
          }
          if (state.confirmed) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(_t('verified_toast', listen: false))),
            );
            await _navigateAfterSuccess(); // always route safely to avoid empty stack
          }
        },
        builder: (context, state) {
          final bool sent = !state.sending && state.resendInSeconds > 0;
          final String sendLabel = sent ? _t('sent_to') : _t('sending_to');
          final String destination = _destinationForChannel();

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(12, 16, 12, 20),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxCardWidth),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Helper card – soft background, icon, better spacing
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.verified_user_rounded, color: color),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _t('helper'),
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Section title
                      Text(
                        _t('choose_channel'),
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: color,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Segmented – mobile-friendly, pill look
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: SegmentedButton<VerifyChannel>(
                          style: ButtonStyle(
                            overlayColor: WidgetStateProperty.all(color.withValues(alpha: 0.06)),
                            padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 12)),
                            side: WidgetStateProperty.all(const BorderSide(color: Colors.transparent)),
                            backgroundColor: WidgetStateProperty.resolveWith((states) {
                              final selected = states.contains(WidgetState.selected);
                              return selected ? color.withValues(alpha: 0.18) : Colors.transparent;
                            }),
                            foregroundColor: WidgetStateProperty.resolveWith((states) {
                              final selected = states.contains(WidgetState.selected);
                              return selected ? scheme.onPrimaryContainer : scheme.onSurface;
                            }),
                          ),
                          segments: <ButtonSegment<VerifyChannel>>[
                            ButtonSegment(
                              value: VerifyChannel.email,
                              label: Text(_t('email')),
                              icon: const Icon(Icons.email_outlined),
                            ),
                            ButtonSegment(
                              value: VerifyChannel.phone,
                              label: Text(_t('sms')),
                              icon: const Icon(Icons.sms_outlined),
                            ),
                          ],
                          selected: {channel},
                          onSelectionChanged: (s) => setState(() => channel = s.first),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Destination line + actions (mobile-focused)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(sent ? Icons.check_circle : Icons.outgoing_mail, color: color),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  sendLabel,
                                  style: TextStyle(
                                    color: scheme.onSurfaceVariant,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  destination,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: color,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () async {
                              final clip = await Clipboard.getData('text/plain');
                              final digits = (clip?.text ?? '').replaceAll(RegExp(r'\D'), '');
                              if (digits.isNotEmpty) _applyBulkPaste(digits);
                            },
                            icon: const Icon(Icons.content_paste_rounded, size: 18),
                            label: Text(_t('paste_hint')),
                          ),
                          TextButton(
                            onPressed: () => _clearOtp(),
                            child: Text(_t('clear')),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Small tip
                      Row(
                        children: [
                          Icon(Icons.touch_app_outlined, size: 16, color: scheme.onSurfaceVariant),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _t('tip_autofocus'),
                              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // OTP vibox – animated, auto-advance, mobile tap area
                      GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTap: () {
                          // Focus kisanduku cha kwanza kilicho wazi
                          final idx = _otpCtrls.indexWhere((c) => c.text.isEmpty);
                          if (idx >= 0) {
                            _otpNodes[idx].requestFocus();
                          } else {
                            _otpNodes.last.requestFocus();
                          }
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(_otpLength, (i) {
                            return _OtpBox(
                              controller: _otpCtrls[i],
                              focusNode: _otpNodes[i],
                              size: boxSize,
                              color: color,
                              onChanged: (v) => _handleOtpChanged(i, v),
                            );
                          }),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Send code button
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: state.sending || state.resendInSeconds > 0 ? null : _sendCode,
                              icon: const Icon(Icons.send_rounded),
                              label: Text(
                                state.resendInSeconds > 0
                                    ? "${_t('resend_in')} ${state.resendInSeconds}${_t('seconds_short')}"
                                    : _t('send_code'),
                              ),
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                            ),
                          ),
                          if (state.sending) ...[
                            const SizedBox(width: 12),
                            Lottie.asset("assets/loading.json", width: 44, height: 44),
                          ]
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Confirm button
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: state.confirming
                            ? Center(child: Lottie.asset("assets/loading.json", width: 66, height: 66))
                            : SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _otpComplete ? _confirmCode : null,
                                  icon: const Icon(Icons.check_circle_outline),
                                  label: Text(_t('confirm')),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  ),
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _OtpBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final double size;
  final Color color;
  final ValueChanged<String> onChanged;

  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.size,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: size,
      height: max(56, size + 4),
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: controller,
        builder: (context, value, _) {
          final filled = value.text.isNotEmpty;
          final hasFocus = focusNode.hasFocus;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: hasFocus
                    ? color
                    : (filled ? color.withValues(alpha: 0.6) : scheme.outlineVariant),
                width: hasFocus ? 2 : 1,
              ),
              color: Theme.of(context).brightness == Brightness.light
                  ? Colors.white
                  : scheme.surfaceContainerHighest.withValues(alpha: 0.35),
              boxShadow: [
                if (hasFocus)
                  BoxShadow(
                    color: color.withValues(alpha: 0.16),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
              ],
            ),
            child: Center(
              child: AnimatedScale(
                duration: const Duration(milliseconds: 160),
                scale: filled ? 1.06 : 1.0,
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface,
                    letterSpacing: 1.5,
                  ),
                  keyboardType: TextInputType.number,
                  // Keep this non-const to avoid analyzer error
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  maxLines: 1,
                  cursorColor: color,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isCollapsed: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                  ),
                  onChanged: onChanged,
                  onTap: () {
                    // Select all for quick replace
                    controller.selection = TextSelection(baseOffset: 0, extentOffset: controller.text.length);
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}