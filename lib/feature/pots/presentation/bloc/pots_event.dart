import 'package:equatable/equatable.dart';

abstract class PotsEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class PotsLoad extends PotsEvent {
  final String userId;
  PotsLoad(this.userId);
  @override
  List<Object?> get props => [userId];
}

class PotCreate extends PotsEvent {
  final String name;
  final double goalAmount;
  final String? purpose;
  final String accountId;
  final String withdrawalCondition;
  final int durationMonths;
  final String userId; // reload after create

  PotCreate({
    required this.name,
    required this.goalAmount,
    this.purpose,
    required this.accountId,
    required this.withdrawalCondition,
    required this.durationMonths,
    required this.userId,
  });

  @override
  List<Object?> get props =>
      [name, goalAmount, purpose, accountId, withdrawalCondition, durationMonths, userId];
}