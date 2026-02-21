import 'dart:math';

class SavingsPlan {
  final double goalAmount;
  final int? durationMonths;
  final int? durationDays;
  final DateTime? startDate;
  final DateTime? endDate;

  static const double _daysPerMonth = 30.4375;
  static const double _weeksPerMonth = 4.3482142857;

  const SavingsPlan({
    required this.goalAmount,
    this.durationMonths,
    this.durationDays,
    this.startDate,
    this.endDate,
  });

  int get totalDays {
    // Use actual dates if available
    if (startDate != null && endDate != null) {
      return max(1, endDate!.difference(startDate!).inDays);
    }
    // Fallback to duration_days from API
    if (durationDays != null && durationDays! > 0) {
      return durationDays!;
    }
    // Last resort: calculate from months
    if (durationMonths != null && durationMonths! > 0) {
      return max(1, (durationMonths! * _daysPerMonth).round());
    }
    return 1;
  }

  int get totalWeeks => max(1, (totalDays / 7).ceil());
  
  int get totalMonths {
    if (durationMonths != null && durationMonths! > 0) {
      return max(1, durationMonths!);
    }
    return max(1, (totalDays / _daysPerMonth).round());
  }

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