// lib/feature/pots/data/models/savings_progress.dart

enum ProgressStatus {
  completed,
  ahead,
  onTrack,
  behind,
  stalled,
}

extension ProgressStatusExtension on ProgressStatus {
  String get displayName {
    switch (this) {
      case ProgressStatus.completed:
        return '✅ Completed';
      case ProgressStatus.ahead:
        return '🚀 Ahead of Schedule';
      case ProgressStatus.onTrack:
        return '✔️ On Track';
      case ProgressStatus.behind:
        return '⚠️ Behind Schedule';
      case ProgressStatus.stalled:
        return '🛑 Stalled';
    }
  }
}

class SavingsProgress {
  final String potId;
  final String potName;
  final double goalAmount;
  final double currentAmount;
  final double remainingAmount;
  final double progressPercent;
  
  final DateTime startDate;
  final DateTime endDate;
  final int daysTotal;
  final int daysElapsed;
  final int daysRemaining;
  final double timeProgressPercent;
  
  final int depositCount;
  final double averageDepositAmount;
  final DateTime? lastDepositDate;
  final double lastDepositAmount;
  
  final double dailyRequiredAmount;
  final double weeklyRequiredAmount;
  final double monthlyRequiredAmount;
  
  final ProgressStatus status;
  final String statusMessage;
  final int daysAheadOrBehind;
  final bool isOnTrack;
  final DateTime? projectedCompletionDate;
  
  final List<String> recommendations;

  const SavingsProgress({
    required this.potId,
    required this.potName,
    required this.goalAmount,
    required this.currentAmount,
    required this.remainingAmount,
    required this.progressPercent,
    required this.startDate,
    required this.endDate,
    required this.daysTotal,
    required this.daysElapsed,
    required this.daysRemaining,
    required this.timeProgressPercent,
    required this.depositCount,
    required this.averageDepositAmount,
    this.lastDepositDate,
    required this.lastDepositAmount,
    required this.dailyRequiredAmount,
    required this.weeklyRequiredAmount,
    required this.monthlyRequiredAmount,
    required this.status,
    required this.statusMessage,
    required this.daysAheadOrBehind,
    required this.isOnTrack,
    this.projectedCompletionDate,
    required this.recommendations,
  });

  factory SavingsProgress.fromJson(Map<String, dynamic> json) {
    return SavingsProgress(
      potId: json['potId'] ?? '',
      potName: json['potName'] ?? '',
      goalAmount: (json['goalAmount'] ?? 0).toDouble(),
      currentAmount: (json['currentAmount'] ?? 0).toDouble(),
      remainingAmount: (json['remainingAmount'] ?? 0).toDouble(),
      progressPercent: (json['progressPercent'] ?? 0).toDouble(),
      
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      daysTotal: json['daysTotal'] ?? 0,
      daysElapsed: json['daysElapsed'] ?? 0,
      daysRemaining: json['daysRemaining'] ?? 0,
      timeProgressPercent: (json['timeProgressPercent'] ?? 0).toDouble(),
      
      depositCount: json['depositCount'] ?? 0,
      averageDepositAmount: (json['averageDepositAmount'] ?? 0).toDouble(),
      lastDepositDate: json['lastDepositDate'] != null 
          ? DateTime.parse(json['lastDepositDate']) 
          : null,
      lastDepositAmount: (json['lastDepositAmount'] ?? 0).toDouble(),
      
      dailyRequiredAmount: (json['dailyRequiredAmount'] ?? 0).toDouble(),
      weeklyRequiredAmount: (json['weeklyRequiredAmount'] ?? 0).toDouble(),
      monthlyRequiredAmount: (json['monthlyRequiredAmount'] ?? 0).toDouble(),
      
      status: _parseStatus(json['status']),
      statusMessage: json['statusMessage'] ?? '',
      daysAheadOrBehind: json['daysAheadOrBehind'] ?? 0,
      isOnTrack: json['isOnTrack'] ?? false,
      projectedCompletionDate: json['projectedCompletionDate'] != null
          ? DateTime.parse(json['projectedCompletionDate'])
          : null,
      
      recommendations: (json['recommendations'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  static ProgressStatus _parseStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'completed':
        return ProgressStatus.completed;
      case 'ahead':
        return ProgressStatus.ahead;
      case 'on_track':
      case 'ontrack':
        return ProgressStatus.onTrack;
      case 'behind':
        return ProgressStatus.behind;
      case 'stalled':
        return ProgressStatus.stalled;
      default:
        return ProgressStatus.onTrack;
    }
  }
}

class QuickProgress {
  final String potId;
  final String potName;
  final double goalAmount;
  final double currentAmount;
  final double progressPercent;
  final int daysRemaining;
  final double dailyRequiredAmount;
  final ProgressStatus status;

  const QuickProgress({
    required this.potId,
    required this.potName,
    required this.goalAmount,
    required this.currentAmount,
    required this.progressPercent,
    required this.daysRemaining,
    required this.dailyRequiredAmount,
    required this.status,
  });

  factory QuickProgress.fromJson(Map<String, dynamic> json) {
    return QuickProgress(
      potId: json['potId'] ?? '',
      potName: json['potName'] ?? '',
      goalAmount: (json['goalAmount'] ?? 0).toDouble(),
      currentAmount: (json['currentAmount'] ?? 0).toDouble(),
      progressPercent: (json['progressPercent'] ?? 0).toDouble(),
      daysRemaining: json['daysRemaining'] ?? 0,
      dailyRequiredAmount: (json['dailyRequiredAmount'] ?? 0).toDouble(),
      status: SavingsProgress._parseStatus(json['status']),
    );
  }
}

class FeeCalculation {
  final double amount;
  final double fee;
  final double netAmount;
  final double feePercentage;
  final double fixedFee;

  const FeeCalculation({
    required this.amount,
    required this.fee,
    required this.netAmount,
    required this.feePercentage,
    required this.fixedFee,
  });

  static FeeCalculation calculate(double grossAmount) {
    double percentage;
    double fixed;

    if (grossAmount <= 10000) {
      percentage = 0.5;
      fixed = 50;
    } else if (grossAmount <= 50000) {
      percentage = 0.3;
      fixed = 100;
    } else if (grossAmount <= 100000) {
      percentage = 0.25;
      fixed = 200;
    } else if (grossAmount <= 500000) {
      percentage = 0.2;
      fixed = 300;
    } else {
      percentage = 0.15;
      fixed = 500;
    }

    final fee = (grossAmount * percentage / 100) + fixed;
    final netAmount = grossAmount - fee;

    return FeeCalculation(
      amount: grossAmount,
      fee: fee,
      netAmount: netAmount,
      feePercentage: percentage,
      fixedFee: fixed,
    );
  }
}
