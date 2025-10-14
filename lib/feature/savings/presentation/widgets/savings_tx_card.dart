import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TxCard extends StatelessWidget {
  final Map<String, dynamic> item;
  const TxCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final amount = (item['amount'] as num?)?.toDouble() ?? 0.0;
    final type = (item['type'] ?? '').toString().toLowerCase();
    final status = (item['status'] ?? item['provider_status'] ?? '').toString().toLowerCase();
    final created = (item['created_at'] ?? '').toString();

    final color = type == 'withdrawal' ? Colors.red : Colors.green;
    final sign = type == 'withdrawal' ? '-' : '+';
    final fmt = NumberFormat.currency(locale: 'sw', symbol: 'TSh', decimalDigits: 0);

    IconData sIcon;
    Color sColor;
    switch (status) {
      case 'posted':
      case 'success':
      case 'completed':
        sIcon = Icons.check_circle;
        sColor = Colors.green;
        break;
      case 'pending':
      case 'initiated':
        sIcon = Icons.hourglass_top;
        sColor = Colors.amber;
        break;
      default:
        sIcon = Icons.info_outline;
        sColor = cs.onSurfaceVariant;
    }

    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.35)),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(type == 'withdrawal' ? Icons.arrow_upward : Icons.arrow_downward, color: color, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  (item['provider_ref'] ?? item['reference'] ?? '').toString(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.w700, color: cs.onSurface),
                ),
              ),
              const SizedBox(width: 6),
              Icon(sIcon, color: sColor, size: 16),
            ],
          ),
          const SizedBox(height: 8),
          Text('$sign${fmt.format(amount)}', style: TextStyle(fontWeight: FontWeight.w900, color: color)),
          const SizedBox(height: 6),
          Text(
            created.replaceAll('T', ' ').split('.').first,
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}