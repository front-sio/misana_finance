import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SavingsTimeline extends StatelessWidget {
  final int months;
  final double currentProgress;

  const SavingsTimeline({super.key, required this.months, required this.currentProgress});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final endDate = DateTime(now.year, now.month + max(1, months), now.day);

    final formatter = DateFormat('MMM yyyy');
    final startDateStr = formatter.format(now);
    final endDateStr = formatter.format(endDate);

    final progressPoints = <int>[0, 25, 50, 75, 100];
    final currentProgressPoint = (currentProgress.clamp(0.0, 1.0) * 100).round();

    return Column(
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.0, end: currentProgress.clamp(0.0, 1.0)),
          duration: const Duration(milliseconds: 1200),
          curve: Curves.easeOutQuart,
          builder: (context, value, _) {
            return Container(
              height: 12,
              decoration: BoxDecoration(
                color: scheme.surfaceVariant.withOpacity(0.6),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Flexible(
                    flex: (value * 100).round(),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        gradient: LinearGradient(colors: [scheme.primary, scheme.secondary]),
                      ),
                    ),
                  ),
                  Flexible(flex: 100 - (value * 100).round(), child: const SizedBox.shrink()),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: progressPoints.map((point) {
            final reached = point <= currentProgressPoint;
            return Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: reached ? scheme.primary : scheme.surfaceVariant,
                    border: reached ? null : Border.all(color: scheme.outlineVariant),
                  ),
                  child: reached ? Icon(Icons.check, color: scheme.onPrimary, size: 12) : null,
                ),
                const SizedBox(height: 4),
                Text(
                  '$point%',
                  style: TextStyle(
                    fontSize: 11,
                    color: reached ? scheme.primary : scheme.onSurfaceVariant,
                    fontWeight: reached ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(startDateStr, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: scheme.onSurface)),
            Text(endDateStr, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: scheme.onSurface)),
          ],
        ),
      ],
    );
  }
}