import 'package:equatable/equatable.dart';

abstract class SavingsEvent extends Equatable {
  const SavingsEvent();
  @override
  List<Object?> get props => [];
}

class SavingsLoad extends SavingsEvent {
  final String userId;
  const SavingsLoad(this.userId);

  @override
  List<Object?> get props => [userId];
}

class SavingsCreate extends SavingsEvent {
  final String name;
  final String goalAmount; // decimal string
  final String accountId;  // internal UUID (account-service)
  final int durationMonths;
  final String? purpose;   // will be normalized by data layer
  final String withdrawalCondition; // "amount" | "time" | "both"
  final String userId;

  const SavingsCreate({
    required this.name,
    required this.goalAmount,
    required this.accountId,
    required this.durationMonths,
    required this.purpose,
    required this.withdrawalCondition,
    required this.userId,
  });

  @override
  List<Object?> get props =>
      [name, goalAmount, accountId, durationMonths, purpose, withdrawalCondition, userId];
}