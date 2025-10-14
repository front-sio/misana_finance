import 'package:flutter/material.dart';
import 'package:misana_finance_app/feature/savings/presentation/widgets/savings_buttons.dart';

class SavingsEmptyView extends StatelessWidget {
  final String title;
  final String desc;
  final String cta;
  final VoidCallback onCreate;

  const SavingsEmptyView({super.key, required this.title, required this.desc, required this.cta, required this.onCreate});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            SizedBox(
              height: 200,
              child: Image.network(
                'https://img.freepik.com/free-vector/savings-concept-illustration_114360-8767.jpg',
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 20),
            Text(title, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: scheme.onSurface)),
            const SizedBox(height: 12),
            Text(
              desc,
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 15),
            ),
            const SizedBox(height: 24),
            GradientButton(onPressed: onCreate, icon: Icons.add_circle_outline, label: cta),
          ]),
        ),
      ),
    );
  }
}