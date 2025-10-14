import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PlanMetricCard extends StatelessWidget {
  final String label;
  final double amount;
  final int deposits;
  final String cadence; // daily | weekly | monthly
  final bool highlight;
  final VoidCallback? onTap;

  const PlanMetricCard({
    super.key,
    required this.label,
    required this.amount,
    required this.deposits,
    required this.cadence,
    this.highlight = false,
    this.onTap,
  });

  String _fmt(num v) {
    final f = NumberFormat.decimalPattern();
    // TZS doesn’t typically show decimals in UI amounts
    return "TZS ${f.format(v.round())}";
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = highlight
        ? scheme.primary.withOpacity(0.10)
        : scheme.surface;
    final border = highlight
        ? scheme.primary.withOpacity(0.25)
        : scheme.outlineVariant;

    return AnimatedScale(
      duration: const Duration(milliseconds: 200),
      scale: highlight ? 1.03 : 1.0,
      curve: Curves.easeOut,
      child: Card(
        elevation: highlight ? 2 : 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: border, width: 1),
        ),
        color: bg,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                _Leading(cadence: cadence, color: scheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: scheme.onSurface,
                          )),
                      const SizedBox(height: 6),
                      Text(
                        "${_fmt(amount)} • $deposits deposits",
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.black45),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Leading extends StatelessWidget {
  final String cadence;
  final Color color;
  const _Leading({required this.cadence, required this.color});

  @override
  Widget build(BuildContext context) {
    final icon = cadence == 'daily'
        ? Icons.calendar_view_day
        : cadence == 'weekly'
            ? Icons.date_range
            : Icons.calendar_month;
    return CircleAvatar(
      radius: 20,
      backgroundColor: color,
      child: Icon(icon, color: Colors.white),
    );
  }
}