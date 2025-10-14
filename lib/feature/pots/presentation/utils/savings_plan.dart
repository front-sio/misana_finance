import 'dart:math';

class SavingsPlan {
  final double goalAmount;
  final int durationMonths;

  static const double _daysPerMonth = 30.4375;
  static const double _weeksPerMonth = 4.3482142857;

  const SavingsPlan({
    required this.goalAmount,
    required this.durationMonths,
  });

  int get totalDays => max(1, (durationMonths * _daysPerMonth).round());
  int get totalWeeks => max(1, (durationMonths * _weeksPerMonth).round());
  int get totalMonths => max(1, durationMonths);

  double get perDay => goalAmount <= 0 ? 0 : goalAmount / totalDays;
  double get perWeek => goalAmount <= 0 ? 0 : goalAmount / totalWeeks;
  double get perMonth => goalAmount <= 0 ? 0 : goalAmount / totalMonths;

  ({double amount, int deposits}) forCadence(String cadence) {
    switch (cadence) {
      case 'daily':
        return (amount: perDay, deposits: totalDays);
      case 'weekly':
        return (amount: perWeek, deposits: totalWeeks);
      default:
        return (amount: perMonth, deposits: totalMonths);
    }
  }
}