// lib/core/widgets/fee_calculator.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class FeeCalculation {
  final double amount;
  final double fee;
  final double total;
  final String feeRange;

  FeeCalculation({
    required this.amount,
    required this.fee,
    required this.total,
    required this.feeRange,
  });

  factory FeeCalculation.calculate(double amount) {
    double fee = 0.0;
    String range = '';

    // Tanzania Mobile Money Fee Structure (Similar to M-Pesa/Tigo Pesa/Airtel)
    if (amount >= 1 && amount <= 1000) {
      fee = 0;
      range = '1 - 1,000';
    } else if (amount <= 2500) {
      fee = 300;
      range = '1,001 - 2,500';
    } else if (amount <= 5000) {
      fee = 500;
      range = '2,501 - 5,000';
    } else if (amount <= 10000) {
      fee = 1000;
      range = '5,001 - 10,000';
    } else if (amount <= 20000) {
      fee = 1500;
      range = '10,001 - 20,000';
    } else if (amount <= 35000) {
      fee = 2000;
      range = '20,001 - 35,000';
    } else if (amount <= 50000) {
      fee = 2500;
      range = '35,001 - 50,000';
    } else if (amount <= 100000) {
      fee = 3000;
      range = '50,001 - 100,000';
    } else if (amount <= 200000) {
      fee = 4000;
      range = '100,001 - 200,000';
    } else if (amount <= 500000) {
      fee = 5000;
      range = '200,001 - 500,000';
    } else {
      fee = amount * 0.01; // 1% for very large amounts
      range = '500,001+';
    }

    return FeeCalculation(
      amount: amount,
      fee: fee,
      total: amount + fee,
      feeRange: range,
    );
  }

  String formatAmount(double value) {
    return NumberFormat.currency(
      locale: 'sw',
      symbol: 'TSh ',
      decimalDigits: 0,
    ).format(value);
  }
}

class FeePreviewCard extends StatelessWidget {
  final FeeCalculation calculation;
  final VoidCallback? onEdit;

  const FeePreviewCard({
    super.key,
    required this.calculation,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calculate_outlined, color: cs.primary, size: 22),
                const SizedBox(width: 8),
                Text(
                  'Muhtasari wa Malipo',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: cs.primary,
                  ),
                ),
                const Spacer(),
                if (onEdit != null)
                  IconButton(
                    icon: const Icon(Icons.edit, size: 18),
                    onPressed: onEdit,
                    tooltip: 'Badilisha',
                  ),
              ],
            ),
            const SizedBox(height: 12),
            
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: cs.outline.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                children: [
                  _DetailRow(
                    label: 'Kiasi cha Kuweka',
                    value: calculation.formatAmount(calculation.amount),
                    valueColor: cs.onSurface,
                  ),
                  const SizedBox(height: 8),
                  _DetailRow(
                    label: 'Ada ya Muamala',
                    value: calculation.formatAmount(calculation.fee),
                    valueColor: calculation.fee > 0 ? cs.error : Colors.green,
                    subtitle: 'Range: ${calculation.feeRange}',
                  ),
                  const Divider(height: 20),
                  _DetailRow(
                    label: 'Jumla ya Kulipa',
                    value: calculation.formatAmount(calculation.total),
                    valueColor: cs.primary,
                    isBold: true,
                    isLarge: true,
                  ),
                ],
              ),
            ),
            
            if (calculation.fee > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.amber.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.amber[800], size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Ada hiyo itatumwa kwa mtoa huduma wa malipo.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.amber[900],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final String? subtitle;
  final bool isBold;
  final bool isLarge;

  const _DetailRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.subtitle,
    this.isBold = false,
    this.isLarge = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: isLarge ? 15 : 14,
                  color: cs.onSurfaceVariant,
                  fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Flexible(
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: isLarge ? 18 : 15,
                  fontWeight: isBold ? FontWeight.w900 : FontWeight.w700,
                  color: valueColor ?? cs.onSurface,
                ),
              ),
            ),
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              subtitle!,
              style: TextStyle(
                fontSize: 11,
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
