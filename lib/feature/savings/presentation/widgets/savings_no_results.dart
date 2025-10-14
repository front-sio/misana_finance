import 'package:flutter/material.dart';

class SavingsNoResultsView extends StatelessWidget {
  final String title;
  final String descPrefix;
  final String query;

  const SavingsNoResultsView({super.key, required this.title, required this.descPrefix, required this.query});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.search_off, size: 80, color: scheme.onSurfaceVariant.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: scheme.onSurface)),
          const SizedBox(height: 8),
          Text(
            '$descPrefix "$query"',
            textAlign: TextAlign.center,
            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 15),
          ),
        ]),
      ),
    );
  }
}