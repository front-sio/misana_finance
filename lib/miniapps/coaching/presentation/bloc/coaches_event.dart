import 'package:equatable/equatable.dart';

abstract class CoachesEvent extends Equatable {
  const CoachesEvent();

  @override
  List<Object?> get props => [];
}

class LoadCoaches extends CoachesEvent {
  const LoadCoaches();
}
