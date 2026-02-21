import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/coaching_repository.dart';
import 'coaches_event.dart';
import 'coaches_state.dart';

class CoachesBloc extends Bloc<CoachesEvent, CoachesState> {
  final CoachingRepository repo;

  CoachesBloc(this.repo) : super(const CoachesInitial()) {
    on<LoadCoaches>(_onLoadCoaches);
  }

  Future<void> _onLoadCoaches(LoadCoaches event, Emitter<CoachesState> emit) async {
    emit(const CoachesLoading());
    try {
      final profile = await repo.getCoachProfile();
      emit(CoachesLoaded(profile));
    } catch (e) {
      emit(CoachesFailure(e.toString()));
    }
  }
}
