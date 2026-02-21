// lib/feature/pots/presentation/bloc/pots_event.dart
import 'package:equatable/equatable.dart';

abstract class PotsEvent extends Equatable {
  const PotsEvent();
  
  @override
  List<Object?> get props => [];
}

class PotsLoad extends PotsEvent {
  final String userId;
  
  const PotsLoad(this.userId);
  
  @override
  List<Object?> get props => [userId];
}

class PotCreate extends PotsEvent {
  final String name;
  final double goalAmount;
  final String purpose;
  final String accountId;
  final String withdrawalCondition;
  final int durationMonths;
  final DateTime startDate;
  final DateTime endDate;
  final String userId;

  const PotCreate({
    required this.name,
    required this.goalAmount,
    required this.purpose,
    required this.accountId,
    required this.withdrawalCondition,
    required this.durationMonths,
    required this.startDate,
    required this.endDate,
    required this.userId,
  });

  @override
  List<Object?> get props => [
    name,
    goalAmount,
    purpose,
    accountId,
    withdrawalCondition,
    durationMonths,
    startDate,
    endDate,
    userId,
  ];
}

class PotDeposit extends PotsEvent {
  final String potId;
  final double amount;
  final String? note;

  const PotDeposit({
    required this.potId,
    required this.amount,
    this.note,
  });

  @override
  List<Object?> get props => [potId, amount, note];
}

class PotWithdraw extends PotsEvent {
  final String potId;
  final double amount;
  final String? note;

  const PotWithdraw({
    required this.potId,
    required this.amount,
    this.note,
  });

  @override
  List<Object?> get props => [potId, amount, note];
}

class PotProgressLoad extends PotsEvent {
  final String potId;

  const PotProgressLoad(this.potId);

  @override
  List<Object?> get props => [potId];
}