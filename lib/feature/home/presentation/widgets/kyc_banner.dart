import 'package:flutter/material.dart';

class KycBanner extends StatelessWidget {
  final bool show;
  final VoidCallback onVerify;
  const KycBanner({super.key, required this.show, required this.onVerify});

  @override
  Widget build(BuildContext context) {
    if (!show) return const SizedBox.shrink();
    final color = Theme.of(context).colorScheme.primary;
    return Material(
      color: color.withOpacity(0.08),
      child: InkWell(
        onTap: onVerify,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(Icons.verified_outlined, color: color),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  "Complete KYC (NIDA) verification to unlock all features.",
                  style: TextStyle(fontSize: 14),
                ),
              ),
              Text("Verify", style: TextStyle(color: color, fontWeight: FontWeight.w600)),
              const SizedBox(width: 4),
              Icon(Icons.arrow_forward_ios, color: color, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}