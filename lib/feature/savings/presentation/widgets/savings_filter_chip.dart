import 'package:flutter/material.dart';

class SavingsFilterChips extends StatelessWidget {
  final String selected;
  final void Function(String) onChanged;
  final String Function(String) t;

  const SavingsFilterChips({super.key, required this.selected, required this.onChanged, required this.t});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final filters = [
      (value: 'all', label: t('all'), icon: Icons.all_inclusive),
      (value: 'active', label: t('active'), icon: Icons.check_circle_outline),
      (value: 'pending', label: t('pending'), icon: Icons.pending_outlined),
      (value: 'closed', label: t('closed'), icon: Icons.lock_outline),
    ];

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final f = filters[index];
          final isSelected = selected == f.value;
          return AnimatedScale(
            scale: isSelected ? 1.05 : 1.0,
            duration: const Duration(milliseconds: 150),
            child: FilterChip(
              selected: isSelected,
              showCheckmark: false,
              avatar: Icon(f.icon, size: 18, color: isSelected ? scheme.onPrimary : scheme.onSurfaceVariant),
              label: Text(f.label),
              labelStyle: TextStyle(
                color: isSelected ? scheme.onPrimary : scheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
              backgroundColor: scheme.surfaceVariant.withOpacity(0.5),
              selectedColor: scheme.primary,
              onSelected: (_) => onChanged(f.value),
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
          );
        },
      ),
    );
  }
}