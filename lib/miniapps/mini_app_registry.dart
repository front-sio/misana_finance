import 'package:flutter/material.dart';

import 'mini_app_contract.dart';
import 'finance/finance_app.dart';
import 'coaching/coaching_app.dart';

class MiniAppRegistry {
  static List<MiniAppContract> all() {
    return [
      MiniAppContract(
        id: 'finance',
        title: 'Finance',
        description: 'Payments, savings, and smart money tools.',
        icon: Icons.payments,
        accentColor: const Color(0xFFED702E),
        comingSoon: false,
        buildEntry: () => const FinanceApp.embedded(),
      ),
      MiniAppContract(
        id: 'coaching',
        title: 'Coaching / Sessions',
        description: 'Guided programs, mentors, and 1:1 sessions.',
        icon: Icons.school,
        accentColor: const Color(0xFF1A936F),
        comingSoon: false,
        buildEntry: () => const CoachingApp.embedded(),
      ),
    ];
  }
}
