import 'package:equatable/equatable.dart';

abstract class SavingsEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class SavingsLoad extends SavingsEvent {
  final String userId;
  SavingsLoad(this.userId);

  @override
  List<Object?> get props => [userId];
}

class SavingsCreate extends SavingsEvent {
  final String name;
  final String goalAmount;
  final int durationMonths;
  final String? purpose;
  final String withdrawalCondition;
  final String accountId; // required by backend
  final String userId; // reload after create

  SavingsCreate({
    required this.name,
    required this.goalAmount,
    required this.durationMonths,
    required this.withdrawalCondition,
    required this.accountId,
    this.purpose,
    required this.userId,
  });

  @override
  List<Object?> get props =>
      [name, goalAmount, durationMonths, purpose, withdrawalCondition, accountId, userId];
}