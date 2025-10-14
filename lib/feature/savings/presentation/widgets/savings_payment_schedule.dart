import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:misana_finance_app/feature/savings/presentation/widgets/savings_progress_bits.dart';
import 'package:misana_finance_app/feature/savings/presentation/widgets/savings_timeline.dart';



class PaymentScheduleView extends StatelessWidget {
  final double amount;
  final int deposits;
  final IconData icon;
  final String title;
  final double goal;
  final double currentAmount;
  final int months;
  final String progressTitle;
  final String savedLabel;
  final String remainingLabel;
  final String tipsTitle;
  final String tipText;
  final String shareLabel;
  final VoidCallback onShare;

  const PaymentScheduleView({
    super.key,
    required this.amount,
    required this.deposits,
    required this.icon,
    required this.title,
    required this.goal,
    required this.currentAmount,
    required this.months,
    required this.progressTitle,
    required this.savedLabel,
    required this.remainingLabel,
    required this.tipsTitle,
    required this.tipText,
    required this.shareLabel,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final formatter = NumberFormat.currency(locale: 'sw', symbol: 'TSh', decimalDigits: 0);

    final remaining = max(0, goal - currentAmount);
    final remainingDeposits = goal <= 0 ? deposits : max(0, deposits - (deposits * (currentAmount / goal)).round());
    final percent = goal > 0 ? (currentAmount / goal).clamp(0.0, 1.0) : 0.0;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: scheme.outlineVariant.withOpacity(0.35)),
              boxShadow: [
                BoxShadow(color: scheme.shadow.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 6)),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(icon, color: scheme.primary, size: 24),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: scheme.onSurface)),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(formatter.format(amount),
                    style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: scheme.primary)),
                Text('$deposits', style: TextStyle(fontSize: 14, color: scheme.onSurfaceVariant)),
                const SizedBox(height: 16),
                InlineProgress(
                  percent: percent,
                  savedLabel: savedLabel,
                  remainingLabel: remainingLabel,
                  saved: formatter.format(currentAmount),
                  remaining: formatter.format(remaining),
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _InfoColumn(title: remainingLabel, value: formatter.format(remaining), color: scheme.tertiary),
                    _InfoColumn(title: 'Deposits left', value: '$remainingDeposits', color: scheme.tertiary),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(progressTitle, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: scheme.onSurface)),
          const SizedBox(height: 10),
          SavingsTimeline(months: months, currentProgress: goal > 0 ? (currentAmount / goal) : 0),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: scheme.secondaryContainer.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: scheme.secondary.withOpacity(0.3)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(
                children: [
                  Icon(Icons.lightbulb_outline, color: scheme.secondary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    tipsTitle,
                    style: TextStyle(fontWeight: FontWeight.bold, color: scheme.onSecondaryContainer, fontSize: 16),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(tipText, style: TextStyle(color: scheme.onSecondaryContainer, fontSize: 14)),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: onShare,
                icon: const Icon(Icons.share),
                label: Text(shareLabel),
                style: OutlinedButton.styleFrom(foregroundColor: scheme.secondary),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _InfoColumn extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _InfoColumn({required this.title, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}