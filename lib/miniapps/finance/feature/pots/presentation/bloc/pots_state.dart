import 'package:equatable/equatable.dart';

abstract class PotsState extends Equatable {
  const PotsState();
  
  @override
  List<Object?> get props => [];
}

class PotInitial extends PotsState {}

class PotLoading extends PotsState {}

class PotsLoaded extends PotsState {
  final List<Map<String, dynamic>> pots;

  const PotsLoaded(this.pots);

  @override
  List<Object?> get props => [pots];
}

class PotActionSuccess extends PotsState {
  final String message;

  const PotActionSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class PotError extends PotsState {
  final String error;

  const PotError(this.error);

  @override
  List<Object?> get props => [error];
}

class PotProgressLoaded extends PotsState {
  final Map<String, dynamic> progress;

  const PotProgressLoaded(this.progress);

  @override
  List<Object?> get props => [progress];
}