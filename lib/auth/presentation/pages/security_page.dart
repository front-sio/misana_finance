import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:misana_finance_app/core/i18n/locale_cubit.dart';
import 'package:misana_finance_app/core/theme/app_theme.dart';
import 'package:misana_finance_app/auth/session/auth_cubit.dart';

class SecurityPage extends StatefulWidget {
  const SecurityPage({super.key});

  @override
  State<SecurityPage> createState() => _SecurityPageState();
}

class _SecurityPageState extends State<SecurityPage> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  bool _twoFactorAuth = false;
  bool _loginAlerts = true;
  bool _sessionTimeout = true;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic),
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  static const _strings = {
    'title': {'sw': 'Usalama', 'en': 'Security'},
    'subtitle': {'sw': 'Dhibiti usalama wa akaunti yako', 'en': 'Manage your account security'},
    'two_factor_auth': {'sw': 'Uthibitisho wa Mambo Mawili', 'en': 'Two-Factor Authentication'},
    'two_factor_desc': {'sw': 'Ongeza kiwango cha usalama kwa msimbo wa pili', 'en': 'Add an extra layer of security with a second code'},
    'login_alerts': {'sw': 'Arifa za Kuingia', 'en': 'Login Alerts'},
    'login_desc': {'sw': 'Pokea arifa kila unapojiunga na akaunti', 'en': 'Get notified when someone signs in to your account'},
    'session_timeout': {'sw': 'Muda wa Kukaa Kwenye Mfumo', 'en': 'Session Timeout'},
    'session_desc': {'sw': 'Toka moja kwa moja baada ya kipindi cha kutumia', 'en': 'Automatically sign out after period of inactivity'},
    'change_password': {'sw': 'Badili Nenosiri', 'en': 'Change Password'},
    'change_pin': {'sw': 'Badili PIN', 'en': 'Change PIN'},
    'active_sessions': {'sw': 'Viwango Hai vya Kuingia', 'en': 'Active Sessions'},
    'manage_devices': {'sw': 'Dhibiti Vifaa', 'en': 'Manage Devices'},
    'save_settings': {'sw': 'Hifadhi Mipangilio', 'en': 'Save Settings'},
    'saved_successfully': {'sw': 'Mipangilio imehifadhiwa kikamilifu!', 'en': 'Settings saved successfully!'},
    'coming_soon': {'sw': 'Akuja Hivi Karibuni', 'en': 'Coming Soon'},
    'request_submitted': {'sw': 'Ombi limewasilishwa. Tafadhali angalia barua pepe yako.', 'en': 'Request submitted. Please check your email.'},
    'submitting': {'sw': 'Inatuma...', 'en': 'Submitting...'},
    'security_tips': {'sw': 'Mashauri ya Usalama', 'en': 'Security Tips'},
    'tip1': {'sw': 'Tumia nenosiri lenye herufi, namba, na alama maalum', 'en': 'Use passwords with letters, numbers, and special characters'},
    'tip2': {'sw': 'Usishiriki nenosiri lako na watu wengine', 'en': 'Never share your password with others'},
    'tip3': {'sw': 'Badili nenosiri mara kwa mara', 'en': 'Change your password regularly'},
    'current_password': {'sw': 'Nenosiri la Sasa', 'en': 'Current Password'},
    'new_password': {'sw': 'Nenosiri Jipya', 'en': 'New Password'},
    'confirm_password': {'sw': 'Thibitisha Nenosiri', 'en': 'Confirm Password'},
    'passwords_mismatch': {'sw': 'Nenosiri halifanani', 'en': 'Passwords do not match'},
    'cancel': {'sw': 'Ghairi', 'en': 'Cancel'},
    'change': {'sw': 'Badili', 'en': 'Change'},
  };

  String _translate(String key, String lang) {
    return _strings[key]?[lang] ?? key;
  }

  void _saveSettings() {
    // TODO: Implement actual settings save functionality
    final lang = context.read<LocaleCubit>().state.languageCode;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _translate('saved_successfully', lang),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final lang = context.watch<LocaleCubit>().state.languageCode;
    String t(String key) => _translate(key, lang);

    return Scaffold(
      appBar: AppBar(
        title: Text(t('title')),
        elevation: 0,
        scrolledUnderElevation: 2,
        shadowColor: scheme.scrim.withValues(alpha: 0.1),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Subtitle
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: BrandColors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: BrandColors.orange.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.security_rounded, color: BrandColors.orange, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        t('subtitle'),
                        style: TextStyle(
                          color: BrandColors.orange,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Authentication Methods
              _buildSection(
                title: t('two_factor_auth'),
                description: t('two_factor_desc'),
                icon: Icons.verified_user_rounded,
                value: _twoFactorAuth,
                onChanged: (value) => setState(() => _twoFactorAuth = value),
              ),

              const SizedBox(height: 24),

              // Security Alerts
              Text(
                'Security Alerts',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),

              _buildSection(
                title: t('login_alerts'),
                description: t('login_desc'),
                icon: Icons.notifications_active_rounded,
                value: _loginAlerts,
                onChanged: (value) => setState(() => _loginAlerts = value),
              ),
              const SizedBox(height: 16),

              _buildSection(
                title: t('session_timeout'),
                description: t('session_desc'),
                icon: Icons.timer_rounded,
                value: _sessionTimeout,
                onChanged: (value) => setState(() => _sessionTimeout = value),
              ),

              const SizedBox(height: 32),

              // Quick Actions
              Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),

              _buildActionCard(
                icon: Icons.lock_reset_rounded,
                title: t('change_password'),
                onTap: () => _showChangePasswordDialog(context),
              ),
              const SizedBox(height: 12),

              _buildActionCard(
                icon: Icons.pin_rounded,
                title: t('change_pin'),
                onTap: () => _showComingSoon(t('change_pin')),
              ),
              const SizedBox(height: 12),

              _buildActionCard(
                icon: Icons.devices_rounded,
                title: t('active_sessions'),
                onTap: () => Navigator.pushNamed(context, '/sessions'),
              ),
              const SizedBox(height: 12),

              _buildActionCard(
                icon: Icons.phone_android_rounded,
                title: t('manage_devices'),
                onTap: () => Navigator.pushNamed(context, '/devices'),
              ),

              const SizedBox(height: 24),

              // Security Tips
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lightbulb_rounded, color: Colors.blue, size: 20),
                        const SizedBox(width: 12),
                        Text(
                          t('security_tips'),
                          style: TextStyle(
                            color: Colors.blue,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildTip(t('tip1')),
                    const SizedBox(height: 8),
                    _buildTip(t('tip2')),
                    const SizedBox(height: 8),
                    _buildTip(t('tip3')),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _saveSettings,
                  icon: const Icon(Icons.save_rounded),
                  label: Text(
                    t('save_settings'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BrandColors.orange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required String description,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: BrandColors.orange.withValues(alpha: 0.1),
              child: Icon(
                icon,
                color: BrandColors.orange,
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeColor: BrandColors.orange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubSection({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: value,
            onChanged: (v) => onChanged(v ?? false),
            activeColor: BrandColors.orange,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: BrandColors.orange.withValues(alpha: 0.1),
                child: Icon(
                  icon,
                  color: BrandColors.orange,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: scheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTip(String tip) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.check_circle_outline_rounded,
          color: Colors.blue,
          size: 16,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            tip,
            style: TextStyle(
              color: Colors.blue.shade700,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  void _showComingSoon(String feature) {
    final lang = context.read<LocaleCubit>().state.languageCode;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '${_translate('coming_soon', lang)}: $feature',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }
  void _showChangePasswordDialog(BuildContext context) {
    final oldPassController = TextEditingController();
    final newPassController = TextEditingController();
    final confirmPassController = TextEditingController();
    final lang = context.read<LocaleCubit>().state.languageCode;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final bottom = MediaQuery.of(ctx).viewInsets.bottom;
        final scheme = Theme.of(ctx).colorScheme;
        bool isSubmitting = false;

        Future<void> submit() async {
          if (isSubmitting) return;
          if (newPassController.text != confirmPassController.text) {
            ScaffoldMessenger.of(ctx).showSnackBar(
              SnackBar(content: Text(_translate('passwords_mismatch', lang))),
            );
            return;
          }
          isSubmitting = true;
          (ctx as Element).markNeedsBuild();
          try {
            await context.read<AuthCubit>().changePassword(
                  oldPassController.text,
                  newPassController.text,
                );
            if (ctx.mounted) {
              Navigator.pop(ctx);
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: Text(_translate('change_password', lang)),
                  content: Text(_translate('request_submitted', lang)),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(_translate('ok', lang)),
                    ),
                  ],
                ),
              );
            }
          } catch (e) {
            ScaffoldMessenger.of(ctx).showSnackBar(
              SnackBar(content: Text(e.toString())),
            );
          } finally {
            isSubmitting = false;
            if (ctx.mounted) (ctx as Element).markNeedsBuild();
          }
        }

        return Padding(
          padding: EdgeInsets.fromLTRB(16, 12, 16, bottom + 16),
          child: StatefulBuilder(
            builder: (ctx, setState) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _translate('change_password', lang),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: oldPassController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: _translate('current_password', lang),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: newPassController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: _translate('new_password', lang),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: confirmPassController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: _translate('confirm_password', lang),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: isSubmitting ? null : () async {
                      setState(() => isSubmitting = true);
                      try {
                        if (newPassController.text != confirmPassController.text) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(content: Text(_translate('passwords_mismatch', lang))),
                          );
                          return;
                        }
                        await context.read<AuthCubit>().changePassword(
                              oldPassController.text,
                              newPassController.text,
                            );
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                          showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: Text(_translate('change_password', lang)),
                              content: Text(_translate('request_submitted', lang)),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text(_translate('ok', lang)),
                                ),
                              ],
                            ),
                          );
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(content: Text(e.toString())),
                        );
                      } finally {
                        setState(() => isSubmitting = false);
                      }
                    },
                    icon: isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.lock_reset_rounded),
                    label: Text(isSubmitting ? _translate('submitting', lang) : _translate('change', lang)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
