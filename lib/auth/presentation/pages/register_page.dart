import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:misana_finance_app/core/i18n/locale_cubit.dart';
import 'package:misana_finance_app/core/utils/phone.dart';
import '../bloc/registration/registration_bloc.dart';
import '../bloc/registration/registration_event.dart';
import '../bloc/registration/registration_state.dart';
import 'verify_account_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

/// Centered Card layout, BIG logo on top (no app name text),
/// subtitle below the logo, Swahili-first copy, and a floating language switcher.
class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  final firstNameCtrl = TextEditingController();
  final lastNameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final usernameCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();
  final confirmPasswordCtrl = TextEditingController();

  final _firstFocus = FocusNode();
  final _lastFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _userFocus = FocusNode();
  final _passFocus = FocusNode();
  final _confirmPassFocus = FocusNode();

  String? gender;
  String countryCode = "255";
  bool acceptedTerms = false;
  bool _obscure = true;
  bool _obscureConfirm = true;
  bool get _passwordsMatch =>
      passwordCtrl.text.trim().isNotEmpty &&
      confirmPasswordCtrl.text.trim().isNotEmpty &&
      passwordCtrl.text.trim() == confirmPasswordCtrl.text.trim();

  bool get _isFormReady =>
      firstNameCtrl.text.trim().isNotEmpty &&
      lastNameCtrl.text.trim().isNotEmpty &&
      _validPhone(phoneCtrl.text) &&
      _validEmail(emailCtrl.text) &&
      usernameCtrl.text.trim().length >= 3 &&
      passwordCtrl.text.trim().length >= 8 &&
      _passwordsMatch &&
      gender != null &&
      acceptedTerms;

  @override
  void dispose() {
    _firstFocus.dispose();
    _lastFocus.dispose();
    _phoneFocus.dispose();
    _emailFocus.dispose();
    _userFocus.dispose();
    _passFocus.dispose();
    _confirmPassFocus.dispose();

    firstNameCtrl.dispose();
    lastNameCtrl.dispose();
    phoneCtrl.dispose();
    emailCtrl.dispose();
    usernameCtrl.dispose();
    passwordCtrl.dispose();
    confirmPasswordCtrl.dispose();
    super.dispose();
  }

  static const _strings = {
    'subtitle': {
      'sw': 'Jiunge na uanze safari yako salama ya Pay Career.',
      'en': 'Join and start your secure Pay Career journey.'
    },
    'create': {'sw': 'Fungua Akaunti', 'en': 'Create Account'},
    'first': {'sw': 'Jina la kwanza', 'en': 'First name'},
    'last': {'sw': 'Jina la mwisho', 'en': 'Last name'},
    'phone': {'sw': 'Namba ya simu', 'en': 'Phone number'},
    'username': {'sw': 'Jina la mtumiaji', 'en': 'Username'},
    'email': {'sw': 'Barua pepe', 'en': 'Email'},
    'password': {'sw': 'Nenosiri', 'en': 'Password'},
    'confirm_password': {'sw': 'Thibitisha nenosiri', 'en': 'Confirm password'},
    'gender': {'sw': 'Jinsia', 'en': 'Gender'},
    'male': {'sw': 'Mwanaume', 'en': 'Male'},
    'female': {'sw': 'Mwanamke', 'en': 'Female'},
    'country': {'sw': 'Msimbo wa nchi', 'en': 'Country code'},
    'terms': {
      'sw': 'Ninakubali Masharti ya Huduma na Sera ya Faragha',
      'en': 'I agree to the Terms of Service and Privacy Policy'
    },
    'submit': {'sw': 'Unda akaunti', 'en': 'Create account'},
    'to_login_q': {'sw': 'Tayari una akaunti?', 'en': 'Already have an account?'},
    'to_login': {'sw': 'Ingia', 'en': 'Login'},
    'required': {'sw': 'Lazima kujazwa', 'en': 'Required'},
    'min3': {'sw': 'Angalau herufi 3', 'en': 'Min 3 characters'},
    'email_invalid': {'sw': 'Weka barua pepe sahihi', 'en': 'Enter a valid email'},
    'pw_min': {'sw': 'Angalau herufi 8', 'en': 'Min 8 characters'},
    'pw_match': {'sw': 'Nenosiri hazilingani', 'en': 'Passwords do not match'},
    'pick_gender': {'sw': 'Chagua jinsia yako', 'en': 'Select your gender'},
    'accept_terms': {'sw': 'Kubali masharti na sera ya faragha', 'en': 'Accept terms & privacy policy'},
    'verify_hint': {
      'sw':
          'Baada ya kuunda akaunti, chagua popote utapokea msimbo wa uthibitisho (barua pepe au SMS).',
      'en':
          'After creating an account, choose where to receive your verification code (email or SMS).'
    },
    'language': {'sw': 'Lugha', 'en': 'Language'},
    'swahili': {'sw': 'Kiswahili', 'en': 'Swahili'},
    'english': {'sw': 'Kiingereza', 'en': 'English'},
    'steps_title': {'sw': 'Hatua za kusajili', 'en': 'Sign-up steps'},
    'step_profile': {'sw': 'Maelezo', 'en': 'Profile'},
    'step_security': {'sw': 'Usalama', 'en': 'Security'},
    'step_verify': {'sw': 'Thibitisha', 'en': 'Verify'},
    'password_strength': {'sw': 'Nguvu ya nenosiri', 'en': 'Password strength'},
    'password_weak': {'sw': 'Dhaifu', 'en': 'Weak'},
    'password_good': {'sw': 'Nzuri', 'en': 'Good'},
    'password_strong': {'sw': 'Imara', 'en': 'Strong'},
    'ready_to_submit': {'sw': 'Uko tayari kutuma', 'en': 'Ready to submit'},
  };

  String _translate(String key, String lang) {
    return _strings[key]?[lang] ?? key;
  }

  void _toast(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  bool _validEmail(String value) => value.contains("@") && value.contains(".");
  bool _validPhone(String value) => RegExp(r'^\+?\d{6,}$').hasMatch(value.trim());

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    
    final lang = context.read<LocaleCubit>().state.languageCode;
    
    if (gender == null) {
      _toast(_translate('pick_gender', lang));
      return;
    }
    if (!acceptedTerms) {
      _toast(_translate('accept_terms', lang));
      return;
    }
    
    // Check if passwords match
    if (passwordCtrl.text.trim() != confirmPasswordCtrl.text.trim()) {
      _toast(_translate('pw_match', lang));
      return;
    }
    
    final phone = normalizePhone(phoneCtrl.text, countryCode);

    context.read<RegistrationBloc>().add(SubmitRegistration(
          username: usernameCtrl.text.trim(),
          password: passwordCtrl.text.trim(),
          email: emailCtrl.text.trim(),
          phone: phone,
          firstName: firstNameCtrl.text.trim(),
          lastName: lastNameCtrl.text.trim(),
          gender: gender!,
        ));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final lang = context.watch<LocaleCubit>().state.languageCode;
    String t(String key) => _translate(key, lang);

    return Scaffold(
      body: SafeArea(
        child: BlocConsumer<RegistrationBloc, RegistrationState>(
          listener: (context, state) {
            if (state.error != null) {
              _toast("❌ ${state.error}");
            } else if (state.userPayload != null) {
              _toast(
                "✅ ${lang == 'sw' ? 'Akaunti imeundwa. Thibitisha akaunti.' : 'Account created. Verify your account.'}",
              );
              final fallback = usernameCtrl.text.trim();
              final email = emailCtrl.text.trim();
              Navigator.of(context).pushReplacement(
                PageRouteBuilder(
                  pageBuilder: (_, __, ___) =>
                      VerifyAccountPage(usernameOrEmail: email.isNotEmpty ? email : fallback),
                  transitionsBuilder: (_, anim, __, child) =>
                      FadeTransition(opacity: anim, child: child),
                ),
              );
            }
          },
          builder: (context, state) {
            final loading = state.loading;

            return LayoutBuilder(
              builder: (ctx, constraints) {
                final wide = constraints.maxWidth >= 740;

                return Stack(
                  children: [
                    // Floating language switcher (top-right)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: _LangButton(
                        current: lang == 'sw' ? 'sw' : 'en',
                        onSelect: (v) => context.read<LocaleCubit>().setFromCode(v),
                        label: t('language'),
                        swLabel: t('swahili'),
                        enLabel: t('english'),
                      ),
                    ),
                    Center(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.symmetric(horizontal: wide ? 32 : 20, vertical: wide ? 24 : 16),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 820),
                          child: Card(
                            elevation: 3,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            child: Padding(
                              padding: const EdgeInsets.all(18),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Header: BIG logo centered, subtitle below (no app name text beside it)
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(20),
                                    child: Image.asset(
                                      'assets/images/misana_orange.png',
                                      width: 96,
                                      height: 96,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          Icon(Icons.payments_outlined, color: scheme.primary, size: 48),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    t('subtitle'),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      t('steps_title'),
                                      style: TextStyle(fontWeight: FontWeight.w800, color: scheme.primary),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        _StepPill(icon: Icons.person, label: t('step_profile'), active: true),
                                        const SizedBox(width: 8),
                                        _StepPill(icon: Icons.lock, label: t('step_security'), active: true),
                                        const SizedBox(width: 8),
                                        _StepPill(icon: Icons.verified, label: t('step_verify'), active: false),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              // Title aligned to start
                              Text(
                                t('create'),
                                textAlign: TextAlign.start,
                                style: TextStyle(
                                      fontSize: wide ? 28 : 24,
                                      fontWeight: FontWeight.bold,
                                      color: scheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 12),

                                  // FORM
                                  Form(
                                    key: _formKey,
                                    child: Column(
                                      children: [
                                        if (wide)
                                          Row(
                                            children: [
                                              Expanded(
                                                child: _Field(
                                                  controller: firstNameCtrl,
                                                  label: t('first'),
                                                  icon: Icons.badge,
                                                  focusNode: _firstFocus,
                                                  textInputAction: TextInputAction.next,
                                                  validator: (v) =>
                                                      (v == null || v.trim().isEmpty) ? t('required') : null,
                                                  onSubmitted: (_) => _lastFocus.requestFocus(),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: _Field(
                                                  controller: lastNameCtrl,
                                                  label: t('last'),
                                                  icon: Icons.badge_outlined,
                                                  focusNode: _lastFocus,
                                                  textInputAction: TextInputAction.next,
                                                  validator: (v) =>
                                                      (v == null || v.trim().isEmpty) ? t('required') : null,
                                                  onSubmitted: (_) => _phoneFocus.requestFocus(),
                                                ),
                                              ),
                                            ],
                                          )
                                        else ...[
                                              _Field(
                                                controller: firstNameCtrl,
                                                label: t('first'),
                                                icon: Icons.badge,
                                                focusNode: _firstFocus,
                                                textInputAction: TextInputAction.next,
                                                onChanged: (_) => setState(() {}),
                                                validator: (v) =>
                                                    (v == null || v.trim().isEmpty) ? t('required') : null,
                                                onSubmitted: (_) => _lastFocus.requestFocus(),
                                              ),
                                          const SizedBox(height: 12),
                                              _Field(
                                                controller: lastNameCtrl,
                                                label: t('last'),
                                                icon: Icons.badge_outlined,
                                                focusNode: _lastFocus,
                                                textInputAction: TextInputAction.next,
                                                onChanged: (_) => setState(() {}),
                                                validator: (v) =>
                                                    (v == null || v.trim().isEmpty) ? t('required') : null,
                                                onSubmitted: (_) => _phoneFocus.requestFocus(),
                                              ),
                                        ],
                                        const SizedBox(height: 12),

                                        // Phone + country
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                              decoration: BoxDecoration(
                                                color: scheme.primary.withValues(alpha: 0.08),
                                                borderRadius: BorderRadius.circular(14),
                                              ),
                                              child: DropdownButton<String>(
                                                value: countryCode,
                                                items: const [
                                                  DropdownMenuItem(value: "255", child: Text("+255")),
                                                  DropdownMenuItem(value: "256", child: Text("+256")),
                                                  DropdownMenuItem(value: "254", child: Text("+254")),
                                                ],
                                                onChanged: (v) => setState(() => countryCode = v ?? "255"),
                                                underline: const SizedBox(),
                                                dropdownColor: Theme.of(context).cardColor,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: _Field(
                                                controller: phoneCtrl,
                                                label: t('phone'),
                                                icon: Icons.phone,
                                                focusNode: _phoneFocus,
                                                keyboard: TextInputType.phone,
                                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                                textInputAction: TextInputAction.next,
                                                onChanged: (_) => setState(() {}),
                                                validator: (v) =>
                                                    (v == null || v.trim().isEmpty) ? t('required') : null,
                                                onSubmitted: (_) => _userFocus.requestFocus(),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),

                                        _Field(
                                          controller: usernameCtrl,
                                          label: t('username'),
                                          icon: Icons.person,
                                          focusNode: _userFocus,
                                          textInputAction: TextInputAction.next,
                                          onChanged: (_) => setState(() {}),
                                          validator: (v) {
                                            if (v == null || v.trim().isEmpty) return t('required');
                                            if (v.trim().length < 3) return t('min3');
                                            return null;
                                          },
                                          onSubmitted: (_) => _emailFocus.requestFocus(),
                                        ),
                                        const SizedBox(height: 12),

                                        _Field(
                                          controller: emailCtrl,
                                          label: t('email'),
                                          icon: Icons.email,
                                          focusNode: _emailFocus,
                                          keyboard: TextInputType.emailAddress,
                                          textInputAction: TextInputAction.next,
                                          onChanged: (_) => setState(() {}),
                                          validator: (v) {
                                            if (v == null || v.trim().isEmpty) return t('required');
                                            if (!v.contains("@") || !v.contains(".")) {
                                              return t('email_invalid');
                                            }
                                            return null;
                                          },
                                          onSubmitted: (_) => _passFocus.requestFocus(),
                                        ),
                                        const SizedBox(height: 12),

                                        _Field(
                                          controller: passwordCtrl,
                                          label: t('password'),
                                          icon: Icons.lock,
                                          focusNode: _passFocus,
                                          obscure: _obscure,
                                          textInputAction: TextInputAction.next,
                                          validator: (v) =>
                                              (v == null || v.length < 8) ? t('pw_min') : null,
                                          suffix: IconButton(
                                            tooltip: _obscure ? "Show" : "Hide",
                                            onPressed: () => setState(() => _obscure = !_obscure),
                                            icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                                          ),
                                          onChanged: (_) {
                                            // Clear confirm password validation when password changes
                                            if (confirmPasswordCtrl.text.isNotEmpty) {
                                              _formKey.currentState?.validate();
                                            }
                                            setState(() {});
                                          },
                                        ),
                                        const SizedBox(height: 6),
                                        _PasswordStrengthBar(
                                          label: t('password_strength'),
                                          password: passwordCtrl.text,
                                          colorScheme: scheme,
                                          weakLabel: t('password_weak'),
                                          goodLabel: t('password_good'),
                                          strongLabel: t('password_strong'),
                                        ),
                                        const SizedBox(height: 12),

                                        _Field(
                                          controller: confirmPasswordCtrl,
                                          label: t('confirm_password'),
                                          icon: Icons.lock_outline,
                                          focusNode: _confirmPassFocus,
                                          obscure: _obscureConfirm,
                                          textInputAction: TextInputAction.next,
                                          validator: (v) {
                                            if (v == null || v.trim().isEmpty) return t('required');
                                            if (v != passwordCtrl.text) return t('pw_match');
                                            return null;
                                          },
                                          onChanged: (_) => setState(() {}),
                                          suffix: IconButton(
                                            tooltip: _obscureConfirm ? "Show" : "Hide",
                                            onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                                            icon: Icon(_obscureConfirm ? Icons.visibility : Icons.visibility_off),
                                          ),
                                        ),
                                        const SizedBox(height: 12),

                                        // Gender
                                        Align(
                                          alignment: Alignment.centerLeft,
                                          child: Text(t('gender'),
                                              style: TextStyle(fontWeight: FontWeight.bold, color: scheme.primary)),
                                        ),
                                        const SizedBox(height: 8),
                                        Wrap(
                                          spacing: 10,
                                          children: [
                                            ChoiceChip(
                                              label: Text(t('male')),
                                              selected: gender == 'male',
                                              selectedColor: scheme.primary,
                                              backgroundColor: scheme.primary.withValues(alpha: 0.08),
                                              labelStyle: TextStyle(
                                                  color: gender == 'male' ? Colors.white : scheme.onSurface),
                                              onSelected: (_) => setState(() => gender = 'male'),
                                            ),
                                            ChoiceChip(
                                              label: Text(t('female')),
                                              selected: gender == 'female',
                                              selectedColor: scheme.primary,
                                              backgroundColor: scheme.primary.withValues(alpha: 0.08),
                                              labelStyle: TextStyle(
                                                  color: gender == 'female' ? Colors.white : scheme.onSurface),
                                              onSelected: (_) => setState(() => gender = 'female'),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),

                                        // Terms
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Checkbox(
                                              value: acceptedTerms,
                                              onChanged: (v) => setState(() => acceptedTerms = v ?? false),
                                              activeColor: scheme.primary,
                                            ),
                                            Expanded(child: Text(t('terms'))),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        if (_isFormReady)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                            decoration: BoxDecoration(
                                              color: scheme.primary.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(color: scheme.primary.withValues(alpha: 0.25)),
                                            ),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                const Icon(Icons.verified_rounded, color: Colors.green),
                                                const SizedBox(width: 8),
                                                Text(
                                                  t('ready_to_submit'),
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w700,
                                                    color: scheme.primary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        if (_isFormReady) const SizedBox(height: 12),

                                        // Submit
                                        SizedBox(
                                          width: double.infinity,
                                          height: 52,
                                          child: ElevatedButton.icon(
                                            icon: const Icon(Icons.person_add_alt_1),
                                            onPressed: loading || !_isFormReady ? null : _submit,
                                            label: Text(
                                              t('submit'),
                                              style: const TextStyle(fontWeight: FontWeight.w700),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 10),

                                        Text(
                                          t('verify_hint'),
                                          textAlign: TextAlign.center,
                                          style: TextStyle(color: scheme.onSurfaceVariant),
                                        ),
                                        const SizedBox(height: 14),

                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(t('to_login_q')),
                                            const SizedBox(width: 6),
                                            GestureDetector(
                                              onTap: () => Navigator.of(context).pushReplacementNamed('/login'),
                                              child: Text(
                                                t('to_login'),
                                                style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w800),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
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
    );
  }
}

class _LangButton extends StatelessWidget {
  final String current; // 'sw' | 'en'
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

class _StepPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;

  const _StepPill({required this.icon, required this.label, required this.active});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: active ? cs.primary.withValues(alpha: 0.12) : cs.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.primary.withValues(alpha: active ? 0.5 : 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: cs.primary),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontWeight: FontWeight.w700, color: cs.onSurface)),
        ],
      ),
    );
  }
}

class _PasswordStrengthBar extends StatelessWidget {
  final String label;
  final String password;
  final ColorScheme colorScheme;
  final String weakLabel;
  final String goodLabel;
  final String strongLabel;

  const _PasswordStrengthBar({
    required this.label,
    required this.password,
    required this.colorScheme,
    required this.weakLabel,
    required this.goodLabel,
    required this.strongLabel,
  });

  @override
  Widget build(BuildContext context) {
    final score = _scorePassword(password);
    final double value = score / 4;
    final bool strong = score >= 3;
    final bool good = score == 2;

    String text = weakLabel;
    Color color = Colors.red;
    if (good) {
      text = goodLabel;
      color = Colors.orange;
    }
    if (strong) {
      text = strongLabel;
      color = Colors.green;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12)),
            Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: LinearProgressIndicator(
            value: value.clamp(0, 1),
            minHeight: 6,
            backgroundColor: colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  int _scorePassword(String pw) {
    int score = 0;
    if (pw.length >= 8) score++;
    if (pw.length >= 12) score++;
    if (RegExp(r'[A-Z]').hasMatch(pw) && RegExp(r'[a-z]').hasMatch(pw)) score++;
    if (RegExp(r'[0-9]').hasMatch(pw) && RegExp(r'[!@#\$%^&*(),.?\":{}|<>]').hasMatch(pw)) score++;
    return score.clamp(0, 4);
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscure;
  final TextInputType keyboard;
  final String? Function(String?)? validator;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final void Function(String)? onSubmitted;
  final List<TextInputFormatter>? inputFormatters;
  final Widget? suffix;
  final void Function(String)? onChanged;

  const _Field({
    required this.controller,
    required this.label,
    required this.icon,
    this.obscure = false,
    this.keyboard = TextInputType.text,
    this.validator,
    this.focusNode,
    this.textInputAction,
    this.onSubmitted,
    this.inputFormatters,
    this.suffix,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboard,
      obscureText: obscure,
      validator: validator,
      textInputAction: textInputAction,
      onFieldSubmitted: onSubmitted,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: scheme.primary),
        suffixIcon: suffix,
        filled: true,
        fillColor: isDark ? scheme.surfaceContainerHighest.withValues(alpha: 0.4) : Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      ),
    );
  }
}
