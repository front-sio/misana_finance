import 'package:equatable/equatable.dart';

abstract class SlotsEvent extends Equatable {
  const SlotsEvent();

  @override
  List<Object?> get props => [];
}

class LoadSlots extends SlotsEvent {
  final String date;
  const LoadSlots(this.date);

  @override
  List<Object?> get props => [date];
}
