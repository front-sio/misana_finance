import 'package:flutter/material.dart';

class RingProgress extends StatelessWidget {
  final double percent;
  final double size;
  final String label;

  const RingProgress({super.key, required this.percent, required this.size, required this.label});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: percent,
            backgroundColor: Colors.white.withOpacity(0.25),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            strokeWidth: 6,
          ),
          Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class InlineProgress extends StatelessWidget {
  final double percent;
  final String savedLabel;
  final String remainingLabel;
  final String saved;
  final String remaining;

  const InlineProgress({
    super.key,
    required this.percent,
    required this.savedLabel,
    required this.remainingLabel,
    required this.saved,
    required this.remaining,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(savedLabel, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
            Text('${(percent * 100).toInt()}%', style: TextStyle(color: cs.primary, fontWeight: FontWeight.w800)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: percent,
            minHeight: 10,
            backgroundColor: cs.surfaceVariant,
            valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(saved, style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w700)),
            Text(remaining, style: TextStyle(color: cs.onSurfaceVariant)),
          ],
        )
      ],
    );
  }
}

class PillStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const PillStat({super.key, required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: cs.onSurface),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: cs.onSurfaceVariant)),
          const SizedBox(width: 8),
          Text(value, style: TextStyle(fontWeight: FontWeight.w800, color: cs.onSurface)),
        ],
      ),
    );
  }
}

class InlineLoader extends StatelessWidget {
  const InlineLoader({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: SizedBox(
        width: 28,
        height: 28,
        child: CircularProgressIndicator(strokeWidth: 2, color: cs.primary),
      ),
    );
  }
}