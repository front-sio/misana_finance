import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/i18n/locale_cubit.dart';
import '../../../session/auth_cubit.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  String _normalizeKycFromUser(Map<String, dynamic>? user) {
    if (user == null) return 'unknown';
    final anyTrue = [
      user['is_verified'],
      user['kyc_verified'],
      user['kycApproved'],
      (user['profile'] is Map ? user['profile']['kyc_verified'] : null),
    ].any((v) {
      if (v is bool) return v;
      if (v is String) {
        final s = v.toLowerCase();
        return s == 'true' || s == '1' || s == 'yes' || s == 'approved' || s == 'verified' || s == 'success';
      }
      return false;
    });
    if (anyTrue) return 'verified';
    final raw = (user['kyc_status'] ??
            user['kyc_verification'] ??
            (user['profile'] is Map ? user['profile']['kyc_status'] : '') ??
            '')
        .toString()
        .toLowerCase()
        .trim();
    if (raw == 'approved' || raw == 'verified' || raw == 'success') return 'verified';
    if (raw == 'pending' || raw == 'in_review' || raw == 'processing') return 'pending';
    if (raw == 'rejected' || raw == 'failed') return 'rejected';
    return 'unknown';
  }

  Color _kycColor(String status, Brightness b) {
    final s = status.toLowerCase();
    final dark = b == Brightness.dark;
    if (s == 'verified') return dark ? Colors.greenAccent : Colors.green;
    if (s == 'pending') return dark ? Colors.amberAccent : Colors.amber;
    if (s == 'rejected') return dark ? Colors.redAccent : Colors.red;
    return dark ? Colors.blueGrey.shade200 : Colors.blueGrey;
  }

  IconData _kycIcon(String status) {
    final s = status.toLowerCase();
    if (s == 'verified') return Icons.verified;
    if (s == 'pending') return Icons.hourglass_top;
    if (s == 'rejected') return Icons.error_outline;
    return Icons.info_outline;
  }

  @override
  Widget build(BuildContext context) {
    final localeCubit = context.watch<LocaleCubit>();
    final isSw = localeCubit.state.languageCode == 'sw';
    final scheme = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;
    final user = context.watch<AuthCubit>().state.user ?? {};

    final firstName = (user['first_name'] ?? '').toString();
    final lastName = (user['last_name'] ?? '').toString();
    final username = (user['username'] ?? '').toString();
    final email = (user['email'] ?? '').toString();
    final phone = (user['phone'] ?? '').toString();
    final externalId = (user['external_account_id'] ??
            (user['account'] is Map ? user['account']['external_account_id'] : ''))
        .toString();

    final kycNorm = _normalizeKycFromUser(user);
    final kycColor = _kycColor(kycNorm, brightness);
    final kycIcon = _kycIcon(kycNorm);

    String kycText() {
      if (isSw) {
        return {
              'verified': 'Imethibitishwa (Taarifa kamili)',
              'pending': 'Inasubiri uthibitisho',
              'rejected': 'Imekataliwa',
              'unknown': 'Haijulikani'
            }[kycNorm] ??
            'Haijulikani';
      } else {
        return {
              'verified': 'Verified (Full Information)',
              'pending': 'Pending verification',
              'rejected': 'Rejected',
              'unknown': 'Unknown'
            }[kycNorm] ??
            'Unknown';
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isSw ? 'Akaunti Yangu' : 'My Profile'),
        actions: [
          PopupMenuButton<String>(
            tooltip: isSw ? 'Badili Lugha' : 'Change Language',
            onSelected: localeCubit.setFromCode,
            icon: const Icon(Icons.language),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'sw', child: Text('🇹🇿 Kiswahili')),
              PopupMenuItem(value: 'en', child: Text('🇬🇧 English')),
            ],
          ),
          IconButton(
            tooltip: isSw ? 'Toka' : 'Logout',
            icon: const Icon(Icons.logout_rounded),
            onPressed: () {
              context.read<AuthCubit>().logout();
              Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 26, 20, 40),
        children: [
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 44,
                  backgroundColor: scheme.primary.withOpacity(0.15),
                  child: Icon(Icons.person, color: scheme.primary, size: 50),
                ),
                const SizedBox(height: 14),
                Text(
                  (('$firstName $lastName').trim().isEmpty
                          ? username
                          : '$firstName $lastName')
                      .trim(),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: scheme.onBackground,
                  ),
                ),
                if (email.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(email,
                        style: TextStyle(
                            color: scheme.onSurfaceVariant, fontSize: 14)),
                  ),
                if (phone.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(phone,
                        style: TextStyle(
                            color: scheme.onSurfaceVariant, fontSize: 14)),
                  ),
                if (externalId.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: scheme.secondary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.link, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            externalId,
                            style: TextStyle(
                                color: scheme.secondary,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 28),
            Card(
              elevation: 1.5,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: kycColor.withOpacity(0.16),
                  child: Icon(kycIcon, color: kycColor),
                ),
                title: Text(isSw ? 'Hali ya Mtumiaji' : 'User Status'),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    kycText(),
                    style: TextStyle(
                        color: kycColor, fontWeight: FontWeight.w700),
                  ),
                ),
                trailing: (kycNorm == 'verified')
                    ? null
                    : TextButton.icon(
                        onPressed: () =>
                            Navigator.of(context).pushNamed('/kyc'),
                        icon: const Icon(Icons.verified_outlined),
                        label:
                            Text(isSw ? 'Thibitisha sasa' : 'Verify now'),
                      ),
              ),
            ),
          const SizedBox(height: 16),
          Card(
            elevation: 1.5,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: ListTile(
              leading:
                  const Icon(Icons.color_lens_outlined, color: Colors.orange),
              title: Text(isSw ? 'Badili Mandhari' : 'Theme (Change)'),
              subtitle: Text(isSw
                  ? 'Chaguo la theme halijatekelezwa'
                  : 'Theme selection not implemented'),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(isSw
                        ? 'Feature ya kubadili theme haijatekelezwa.'
                        : 'Theme change feature not implemented.')));
              },
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 1.5,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: ListTile(
              leading:
                  const Icon(Icons.language_outlined, color: Colors.orange),
              title: Text(isSw ? 'Lugha ya Programu' : 'App Language'),
              subtitle: Text(isSw
                  ? 'Badili kati ya Kiswahili na Kiingereza'
                  : 'Switch between Swahili and English'),
              trailing: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: localeCubit.state.languageCode,
                  items: const [
                    DropdownMenuItem(
                        value: 'sw', child: Text('🇹🇿 Kiswahili')),
                    DropdownMenuItem(
                        value: 'en', child: Text('🇬🇧 English')),
                  ],
                  onChanged: (v) {
                    if (v != null) localeCubit.setFromCode(v);
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () {
              context.read<AuthCubit>().logout();
              Navigator.of(context)
                  .pushNamedAndRemoveUntil('/login', (_) => false);
            },
            icon: const Icon(Icons.logout_rounded),
            label: Text(isSw ? 'Toka (Logout)' : 'Logout'),
          ),
        ],
      ),
    );
  }
}