import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:misana_finance_app/core/i18n/locale_cubit.dart';
import 'package:misana_finance_app/core/theme/app_theme.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  bool _pushNotifications = true;
  bool _emailNotifications = true;
  bool _smsNotifications = false;
  bool _transactionAlerts = true;
  bool _promotionAlerts = false;
  bool _securityAlerts = true;

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

  String _t(String key) {
    final isSw = context.watch<LocaleCubit>().state.languageCode == 'sw';
    final translations = {
      'title': isSw ? 'Arifa' : 'Notifications',
      'subtitle': isSw ? 'Dhibiti aina za arifa unazopokea' : 'Control the types of notifications you receive',
      'push_notifications': isSw ? 'Arifa za Push' : 'Push Notifications',
      'push_desc': isSw ? 'Pokea arifa moja kwa moja kwenye simu yako' : 'Receive instant notifications on your phone',
      'email_notifications': isSw ? 'Arifa za Barua pepe' : 'Email Notifications',
      'email_desc': isSw ? 'Pokea arifa kwenye barua pepe yako' : 'Receive notifications via email',
      'sms_notifications': isSw ? 'Arifa za SMS' : 'SMS Notifications',
      'sms_desc': isSw ? 'Pokea arifa kupitia meseji ya maandishi' : 'Receive notifications via text message',
      'transaction_alerts': isSw ? 'Arifa za Muamala' : 'Transaction Alerts',
      'transaction_desc': isSw ? 'Pokea arifa kwa kila muamala' : 'Get notified for every transaction',
      'promotion_alerts': isSw ? 'Arifa za Matangazo' : 'Promotional Alerts',
      'promotion_desc': isSw ? 'Pokea arifa kuhusu ofa na matangazo' : 'Receive offers and promotional updates',
      'security_alerts': isSw ? 'Arifa za Usalama' : 'Security Alerts',
      'security_desc': isSw ? 'Pokea arifa kuhusu shughuli za akaunti' : 'Get notified about account security activities',
      'save_settings': isSw ? 'Hifadhi Mipangilio' : 'Save Settings',
      'saved_successfully': isSw ? 'Mipangilio imehifadhiwa kikamilifu!' : 'Settings saved successfully!',
    };
    return translations[key] ?? key;
  }

  void _saveSettings() {
    // TODO: Implement actual settings save functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _t('saved_successfully'),
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

    return Scaffold(
      appBar: AppBar(
        title: Text(_t('title')),
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
                    Icon(Icons.info_rounded, color: BrandColors.orange, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _t('subtitle'),
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

              // Notification Settings
              _buildSection(
                title: _t('push_notifications'),
                description: _t('push_desc'),
                icon: Icons.notifications_rounded,
                value: _pushNotifications,
                onChanged: (value) => setState(() => _pushNotifications = value),
              ),
              const SizedBox(height: 16),

              _buildSection(
                title: _t('email_notifications'),
                description: _t('email_desc'),
                icon: Icons.email_rounded,
                value: _emailNotifications,
                onChanged: (value) => setState(() => _emailNotifications = value),
              ),
              const SizedBox(height: 16),

              _buildSection(
                title: _t('sms_notifications'),
                description: _t('sms_desc'),
                icon: Icons.sms_rounded,
                value: _smsNotifications,
                onChanged: (value) => setState(() => _smsNotifications = value),
              ),

              const SizedBox(height: 32),

              // Alert Types
              Text(
                'Alert Types',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),

              _buildSection(
                title: _t('transaction_alerts'),
                description: _t('transaction_desc'),
                icon: Icons.account_balance_wallet_rounded,
                value: _transactionAlerts,
                onChanged: (value) => setState(() => _transactionAlerts = value),
              ),
              const SizedBox(height: 16),

              _buildSection(
                title: _t('promotion_alerts'),
                description: _t('promotion_desc'),
                icon: Icons.local_offer_rounded,
                value: _promotionAlerts,
                onChanged: (value) => setState(() => _promotionAlerts = value),
              ),
              const SizedBox(height: 16),

              _buildSection(
                title: _t('security_alerts'),
                description: _t('security_desc'),
                icon: Icons.security_rounded,
                value: _securityAlerts,
                onChanged: (value) => setState(() => _securityAlerts = value),
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
                    _t('save_settings'),
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
}
