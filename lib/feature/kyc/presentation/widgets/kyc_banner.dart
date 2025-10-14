import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/i18n/locale_cubit.dart';

class KycBanner extends StatelessWidget {
  final bool show;
  final VoidCallback onVerify;
  const KycBanner({super.key, required this.show, required this.onVerify});

  @override
  Widget build(BuildContext context) {
    if (!show) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    final lang = context.watch<LocaleCubit>().state.languageCode;

    final text = lang == 'sw'
        ? "Kamilisha uthibitisho wa KYC (NIDA) ili kufungua huduma zote."
        : "Complete KYC (NIDA) verification to unlock all features.";
    final cta = lang == 'sw' ? "Thibitisha" : "Verify";

    return Material(
      color: scheme.primary.withOpacity(0.08),
      child: InkWell(
        onTap: onVerify,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(Icons.verified_outlined, color: scheme.primary),
              const SizedBox(width: 12),
              Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
              Text(cta, style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w600)),
              const SizedBox(width: 4),
              Icon(Icons.arrow_forward_ios, color: scheme.primary, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}