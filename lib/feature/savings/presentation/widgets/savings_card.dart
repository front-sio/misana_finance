import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SavingsCard extends StatelessWidget {
  final int index;
  final String name;
  final double goal;
  final int months;
  final double currentAmount;
  final double progressPercent;
  final String cadence;
  final double cadenceAmount;
  final String condition;
  final String status;
  final bool locked;
  final VoidCallback onTap;
  final String Function(String) t;

  const SavingsCard({
    super.key,
    required this.index,
    required this.name,
    required this.goal,
    required this.months,
    required this.currentAmount,
    required this.progressPercent,
    required this.cadence,
    required this.cadenceAmount,
    required this.condition,
    required this.status,
    required this.locked,
    required this.onTap,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final formatter = NumberFormat.currency(locale: 'sw', symbol: 'TSh', decimalDigits: 0);

    Color headerColor;
    Color accentColor;
    IconData statusIcon;

    switch (status.toLowerCase()) {
      case 'active':
        headerColor = Colors.green.withOpacity(0.15);
        accentColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'pending':
        headerColor = Colors.amber.withOpacity(0.15);
        accentColor = Colors.amber.shade800;
        statusIcon = Icons.pending_outlined;
        break;
      case 'closed':
        headerColor = Colors.red.withOpacity(0.15);
        accentColor = Colors.red;
        statusIcon = Icons.lock_outline;
        break;
      default:
        headerColor = scheme.surfaceVariant.withOpacity(0.15);
        accentColor = scheme.primary;
        statusIcon = Icons.info_outline;
    }

    final cadenceLabel = cadence == 'daily'
        ? t('day')
        : cadence == 'weekly'
            ? t('week')
            : t('month');

    final remaining = max(0.0, goal - currentAmount);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) =>
          Opacity(opacity: value, child: Transform.translate(offset: Offset(0, 20 * (1 - value)), child: child)),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Material(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(16),
          elevation: 2,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: headerColor,
                    borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
                    border: Border(bottom: BorderSide(color: scheme.outlineVariant.withOpacity(0.3))),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: accentColor.withOpacity(0.12),
                          shape: BoxShape.circle,
                          border: Border.all(color: accentColor.withOpacity(0.5), width: 2),
                        ),
                        child: Icon(locked ? Icons.lock_outline : Icons.savings_outlined, color: accentColor),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: scheme.onSurface),
                          ),
                          Text(
                            '${t('months')} $months • ${condition == 'both' ? 'Amount & Time' : condition == 'time' ? 'Time' : 'Amount'}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
                          ),
                        ]),
                      ),
                      const SizedBox(width: 6),
                      Icon(statusIcon, color: accentColor),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(t('goal'), style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
                            Text(
                              formatter.format(goal),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: scheme.onSurface),
                            ),
                          ]),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                            Text('${t('per')} $cadenceLabel',
                                style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
                            Text(
                              formatter.format(cadenceAmount),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: accentColor),
                            ),
                          ]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _MiniStat(
                            icon: Icons.savings_outlined,
                            label: t('saved'),
                            value: formatter.format(currentAmount),
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _MiniStat(
                            icon: Icons.timelapse_outlined,
                            label: t('remaining'),
                            value: formatter.format(remaining),
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(t('progress'), style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
                        Text(
                          '${(progressPercent * 100).toInt()}%',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: accentColor),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progressPercent,
                        backgroundColor: scheme.surfaceVariant,
                        valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                        minHeight: 8,
                      ),
                    ),
                  ]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _MiniStat({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surfaceVariant.withOpacity(0.4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
              Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)),
            ]),
          ),
        ],
      ),
    );
  }
}