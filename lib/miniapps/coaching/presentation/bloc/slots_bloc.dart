import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/coaching_repository.dart';
import 'slots_event.dart';
import 'slots_state.dart';

class SlotsBloc extends Bloc<SlotsEvent, SlotsState> {
  final CoachingRepository repo;

  SlotsBloc(this.repo) : super(const SlotsInitial()) {
    on<LoadSlots>(_onLoadSlots);
  }

  Future<void> _onLoadSlots(LoadSlots event, Emitter<SlotsState> emit) async {
    emit(const SlotsLoading());
    try {
      final slots = await repo.getSlots(event.date);
      emit(SlotsLoaded(date: event.date, slots: slots));
    } catch (e) {
      emit(SlotsFailure(e.toString()));
    }
  }
}
