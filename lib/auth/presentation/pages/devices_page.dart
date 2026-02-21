import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:misana_finance_app/core/i18n/locale_cubit.dart';
import 'package:misana_finance_app/auth/session/auth_cubit.dart';
import 'package:misana_finance_app/auth/session/auth_state.dart';

class DevicesPage extends StatelessWidget {
  const DevicesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isSw = context.watch<LocaleCubit>().state.languageCode == 'sw';
    final auth = context.watch<AuthCubit>().state;
    final devices = _parseDevices(auth);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(isSw ? 'Vifaa' : 'Devices'),
      ),
      body: devices.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  isSw ? 'Hakuna vifaa vilivyosajiliwa.' : 'No devices registered.',
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemBuilder: (ctx, i) {
                final d = devices[i];
                final isCurrent = d['current'] == 'true';
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: scheme.primary.withValues(alpha: 0.12),
                      child: Icon(Icons.phonelink_setup_rounded, color: scheme.primary),
                    ),
                    title: Text(d['name'] ?? 'Device'),
                    subtitle: Text(d['lastSeen'] ?? ''),
                    trailing: isCurrent
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: scheme.secondaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              isSw ? 'Hiki' : 'Current',
                              style: TextStyle(
                                color: scheme.onSecondaryContainer,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                        : TextButton(
                            onPressed: () => _showRemoveDialog(context, isSw, d['name'] ?? 'Device'),
                            child: Text(isSw ? 'Ondoa' : 'Remove'),
                          ),
                  ),
                );
              },
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemCount: devices.length,
            ),
    );
  }

  List<Map<String, String>> _parseDevices(AuthState auth) {
    final raw = auth.user?['devices'] ?? auth.user?['active_devices'];
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((item) => item.map((key, value) => MapEntry('$key', '$value')))
          .toList();
    }
    return [];
  }

  Future<void> _showRemoveDialog(BuildContext context, bool isSw, String name) async {
    final scheme = Theme.of(context).colorScheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isSw ? 'Ondoa kifaa' : 'Remove device'),
        content: Text(isSw
            ? 'Una uhakika unataka kuondoa $name kutoka kwenye akaunti hii?'
            : 'Are you sure you want to remove $name from this account?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(isSw ? 'Ghairi' : 'Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: Text(isSw ? 'Ondoa' : 'Remove')),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isSw
              ? 'Uondoaji wa kifaa unahitaji API. Tafadhali jaribu tena baadaye.'
              : 'Device removal requires an API endpoint. Please try again later.'),
          backgroundColor: scheme.inverseSurface,
        ),
      );
    }
  }
}
