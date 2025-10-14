import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/i18n/locale_cubit.dart';
import '../../../../core/utils/phone.dart';
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

  final _firstFocus = FocusNode();
  final _lastFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _userFocus = FocusNode();
  final _passFocus = FocusNode();

  String? gender;
  String countryCode = "255";
  bool acceptedTerms = false;
  bool _obscure = true;

  @override
  void dispose() {
    _firstFocus.dispose();
    _lastFocus.dispose();
    _phoneFocus.dispose();
    _emailFocus.dispose();
    _userFocus.dispose();
    _passFocus.dispose();

    firstNameCtrl.dispose();
    lastNameCtrl.dispose();
    phoneCtrl.dispose();
    emailCtrl.dispose();
    usernameCtrl.dispose();
    passwordCtrl.dispose();
    super.dispose();
  }

  // Inline i18n based on global LocaleCubit
  // NOTE:
  // - Use default listen:true when called during build so UI updates with language.
  // - Use listen:false inside handlers/validators to avoid Provider assertion.
  String _t(String key, {bool listen = true}) {
    final lang = listen
        ? context.watch<LocaleCubit>().state.languageCode
        : context.read<LocaleCubit>().state.languageCode;

    final sw = {
      'subtitle': 'Jiunge na uanze safari yako salama ya kuweka akiba.',
      'create': 'Fungua Akaunti',
      'first': 'Jina la kwanza',
      'last': 'Jina la mwisho',
      'phone': 'Namba ya simu',
      'username': 'Jina la mtumiaji',
      'email': 'Barua pepe',
      'password': 'Nenosiri',
      'gender': 'Jinsia',
      'male': 'Mwanaume',
      'female': 'Mwanamke',
      'country': 'Msimbo wa nchi',
      'terms': 'Ninakubali Masharti ya Huduma na Sera ya Faragha',
      'submit': 'Unda akaunti',
      'to_login_q': 'Tayari una akaunti?',
      'to_login': 'Ingia',
      'required': 'Lazima kujazwa',
      'min3': 'Angalau herufi 3',
      'email_invalid': 'Weka barua pepe sahihi',
      'pw_min': 'Angalau herufi 8',
      'pick_gender': 'Chagua jinsia yako',
      'accept_terms': 'Kubali masharti na sera ya faragha',
      'verify_hint':
          'Baada ya kuunda akaunti, chagua popote utapokea msimbo wa uthibitisho (barua pepe au SMS).',
      'language': 'Lugha',
      'swahili': 'Kiswahili',
      'english': 'Kiingereza',
    };
    final en = {
      'subtitle': 'Join and start your secure savings journey.',
      'create': 'Create Account',
      'first': 'First name',
      'last': 'Last name',
      'phone': 'Phone number',
      'username': 'Username',
      'email': 'Email',
      'password': 'Password',
      'gender': 'Gender',
      'male': 'Male',
      'female': 'Female',
      'country': 'Country code',
      'terms': 'I agree to the Terms of Service and Privacy Policy',
      'submit': 'Create account',
      'to_login_q': 'Already have an account?',
      'to_login': 'Login',
      'required': 'Required',
      'min3': 'Min 3 characters',
      'email_invalid': 'Enter a valid email',
      'pw_min': 'Min 8 characters',
      'pick_gender': 'Select your gender',
      'accept_terms': 'Accept terms & privacy policy',
      'verify_hint':
          'After creating an account, choose where to receive your verification code (email or SMS).',
      'language': 'Language',
      'swahili': 'Swahili',
      'english': 'English',
    };
    return (lang == 'sw' ? sw : en)[key] ?? key;
  }

  void _toast(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (gender == null) {
      _toast(_t('pick_gender', listen: false));
      return;
    }
    if (!acceptedTerms) {
      _toast(_t('accept_terms', listen: false));
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

    return Scaffold(
      body: SafeArea(
        child: BlocConsumer<RegistrationBloc, RegistrationState>(
          listener: (context, state) {
            if (state.error != null) {
              _toast("❌ ${state.error}");
            } else if (state.userPayload != null) {
              _toast(
                "✅ ${context.read<LocaleCubit>().state.languageCode == 'sw' ? 'Akaunti imeundwa. Thibitisha akaunti.' : 'Account created. Verify your account.'}",
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
                        current: context.watch<LocaleCubit>().state.languageCode == 'sw' ? 'sw' : 'en',
                        onSelect: (v) => context.read<LocaleCubit>().setFromCode(v),
                        label: _t('language'),
                        swLabel: _t('swahili'),
                        enLabel: _t('english'),
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
                                              Icon(Icons.savings_outlined, color: scheme.primary, size: 48),
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        _t('subtitle'),
                                        textAlign: TextAlign.center,
                                        style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  // Title aligned to start
                                  Text(
                                    _t('create'),
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
                                                  label: _t('first'),
                                                  icon: Icons.badge,
                                                  focusNode: _firstFocus,
                                                  textInputAction: TextInputAction.next,
                                                  validator: (v) =>
                                                      (v == null || v.trim().isEmpty) ? _t('required', listen: false) : null,
                                                  onSubmitted: (_) => _lastFocus.requestFocus(),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: _Field(
                                                  controller: lastNameCtrl,
                                                  label: _t('last'),
                                                  icon: Icons.badge_outlined,
                                                  focusNode: _lastFocus,
                                                  textInputAction: TextInputAction.next,
                                                  validator: (v) =>
                                                      (v == null || v.trim().isEmpty) ? _t('required', listen: false) : null,
                                                  onSubmitted: (_) => _phoneFocus.requestFocus(),
                                                ),
                                              ),
                                            ],
                                          )
                                        else ...[
                                          _Field(
                                            controller: firstNameCtrl,
                                            label: _t('first'),
                                            icon: Icons.badge,
                                            focusNode: _firstFocus,
                                            textInputAction: TextInputAction.next,
                                            validator: (v) =>
                                                (v == null || v.trim().isEmpty) ? _t('required', listen: false) : null,
                                            onSubmitted: (_) => _lastFocus.requestFocus(),
                                          ),
                                          const SizedBox(height: 12),
                                          _Field(
                                            controller: lastNameCtrl,
                                            label: _t('last'),
                                            icon: Icons.badge_outlined,
                                            focusNode: _lastFocus,
                                            textInputAction: TextInputAction.next,
                                            validator: (v) =>
                                                (v == null || v.trim().isEmpty) ? _t('required', listen: false) : null,
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
                                                color: scheme.primary.withOpacity(0.08),
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
                                                label: _t('phone'),
                                                icon: Icons.phone,
                                                focusNode: _phoneFocus,
                                                keyboard: TextInputType.phone,
                                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                                textInputAction: TextInputAction.next,
                                                validator: (v) =>
                                                    (v == null || v.trim().isEmpty) ? _t('required', listen: false) : null,
                                                onSubmitted: (_) => _userFocus.requestFocus(),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),

                                        _Field(
                                          controller: usernameCtrl,
                                          label: _t('username'),
                                          icon: Icons.person,
                                          focusNode: _userFocus,
                                          textInputAction: TextInputAction.next,
                                          validator: (v) {
                                            if (v == null || v.trim().isEmpty) return _t('required', listen: false);
                                            if (v.trim().length < 3) return _t('min3', listen: false);
                                            return null;
                                          },
                                          onSubmitted: (_) => _emailFocus.requestFocus(),
                                        ),
                                        const SizedBox(height: 12),

                                        _Field(
                                          controller: emailCtrl,
                                          label: _t('email'),
                                          icon: Icons.email,
                                          focusNode: _emailFocus,
                                          keyboard: TextInputType.emailAddress,
                                          textInputAction: TextInputAction.next,
                                          validator: (v) {
                                            if (v == null || v.trim().isEmpty) return _t('required', listen: false);
                                            if (!v.contains("@") || !v.contains(".")) {
                                              return _t('email_invalid', listen: false);
                                            }
                                            return null;
                                          },
                                          onSubmitted: (_) => _passFocus.requestFocus(),
                                        ),
                                        const SizedBox(height: 12),

                                        _Field(
                                          controller: passwordCtrl,
                                          label: _t('password'),
                                          icon: Icons.lock,
                                          focusNode: _passFocus,
                                          obscure: _obscure,
                                          textInputAction: TextInputAction.done,
                                          validator: (v) =>
                                              (v == null || v.length < 8) ? _t('pw_min', listen: false) : null,
                                          suffix: IconButton(
                                            tooltip: _obscure ? "Show" : "Hide",
                                            onPressed: () => setState(() => _obscure = !_obscure),
                                            icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                                          ),
                                        ),
                                        const SizedBox(height: 12),

                                        // Gender
                                        Align(
                                          alignment: Alignment.centerLeft,
                                          child: Text(_t('gender'),
                                              style: TextStyle(fontWeight: FontWeight.bold, color: scheme.primary)),
                                        ),
                                        const SizedBox(height: 8),
                                        Wrap(
                                          spacing: 10,
                                          children: [
                                            ChoiceChip(
                                              label: Text(_t('male')),
                                              selected: gender == 'male',
                                              selectedColor: scheme.primary,
                                              backgroundColor: scheme.primary.withOpacity(0.08),
                                              labelStyle: TextStyle(
                                                  color: gender == 'male' ? Colors.white : scheme.onSurface),
                                              onSelected: (_) => setState(() => gender = 'male'),
                                            ),
                                            ChoiceChip(
                                              label: Text(_t('female')),
                                              selected: gender == 'female',
                                              selectedColor: scheme.primary,
                                              backgroundColor: scheme.primary.withOpacity(0.08),
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
                                            Expanded(child: Text(_t('terms'))),
                                          ],
                                        ),
                                        const SizedBox(height: 12),

                                        // Submit
                                        SizedBox(
                                          width: double.infinity,
                                          height: 52,
                                          child: ElevatedButton.icon(
                                            icon: const Icon(Icons.person_add_alt_1),
                                            onPressed: loading ? null : _submit,
                                            label: Text(
                                              _t('submit'),
                                              style: const TextStyle(fontWeight: FontWeight.w700),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 10),

                                        Text(
                                          _t('verify_hint'),
                                          textAlign: TextAlign.center,
                                          style: TextStyle(color: scheme.onSurfaceVariant),
                                        ),
                                        const SizedBox(height: 14),

                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(_t('to_login_q')),
                                            const SizedBox(width: 6),
                                            GestureDetector(
                                              onTap: () => Navigator.of(context).pushReplacementNamed('/login'),
                                              child: Text(
                                                _t('to_login'),
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
          backgroundColor: scheme.primary.withOpacity(0.12),
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

  const _Field({
    super.key,
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
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: scheme.primary),
        suffixIcon: suffix,
        filled: true,
        fillColor: isDark ? scheme.surfaceVariant.withOpacity(0.4) : Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      ),
    );
  }
}