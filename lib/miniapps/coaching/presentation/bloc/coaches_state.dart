import 'package:equatable/equatable.dart';
import '../../data/models.dart';

abstract class CoachesState extends Equatable {
  const CoachesState();

  @override
  List<Object?> get props => [];
}

class CoachesInitial extends CoachesState {
  const CoachesInitial();
}

class CoachesLoading extends CoachesState {
  const CoachesLoading();
}

class CoachesLoaded extends CoachesState {
  final CoachProfile profile;
  const CoachesLoaded(this.profile);

  @override
  List<Object?> get props => [profile];
}

class CoachesFailure extends CoachesState {
  final String message;
  const CoachesFailure(this.message);

  @override
  List<Object?> get props => [message];
}
