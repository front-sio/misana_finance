import 'package:equatable/equatable.dart';
import '../../data/models.dart';

abstract class SlotsState extends Equatable {
  const SlotsState();

  @override
  List<Object?> get props => [];
}

class SlotsInitial extends SlotsState {
  const SlotsInitial();
}

class SlotsLoading extends SlotsState {
  const SlotsLoading();
}

class SlotsLoaded extends SlotsState {
  final String date;
  final List<AvailabilitySlot> slots;
  const SlotsLoaded({required this.date, required this.slots});

  @override
  List<Object?> get props => [date, slots];
}

class SlotsFailure extends SlotsState {
  final String message;
  const SlotsFailure(this.message);

  @override
  List<Object?> get props => [message];
}
