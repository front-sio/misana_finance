import 'package:equatable/equatable.dart';

abstract class AccountEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class AccountEnsure extends AccountEvent {}

class AccountLoadByUser extends AccountEvent {
  final String userId;
  AccountLoadByUser(this.userId);
  @override
  List<Object?> get props => [userId];
}