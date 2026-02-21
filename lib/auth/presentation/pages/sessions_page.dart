import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:misana_finance_app/core/i18n/locale_cubit.dart';
import 'package:misana_finance_app/auth/session/auth_cubit.dart';
import 'package:misana_finance_app/auth/session/auth_state.dart';

class SessionsPage extends StatelessWidget {
  const SessionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isSw = context.watch<LocaleCubit>().state.languageCode == 'sw';
    final auth = context.watch<AuthCubit>().state;
    final sessions = _parseSessions(auth);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(isSw ? 'Vikao Hai' : 'Active Sessions'),
      ),
      body: sessions.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  isSw ? 'Hakuna vikao vinavyoendelea.' : 'No active sessions.',
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemBuilder: (ctx, i) {
                final s = sessions[i];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: scheme.primary.withValues(alpha: 0.12),
                      child: Icon(Icons.devices_other_rounded, color: scheme.primary),
                    ),
                    title: Text(s['device'] ?? 'Device'),
                    subtitle: Text(s['ip'] ?? ''),
                    trailing: Text(
                      s['time'] ?? '',
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    ),
                  ),
                );
              },
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemCount: sessions.length,
            ),
    );
  }

  List<Map<String, String>> _parseSessions(AuthState auth) {
    final raw = auth.user?['sessions'] ?? auth.user?['active_sessions'];
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((item) => item.map((key, value) => MapEntry('$key', '$value')))
          .toList();
    }
    return [];
  }
}
