import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/pots_repository.dart';
import 'pots_event.dart';
import 'pots_state.dart';

class PotsBloc extends Bloc<PotsEvent, PotsState> {
  final PotsRepository repo;
  PotsBloc(this.repo) : super(const PotsState()) {
    on<PotsLoad>(_onLoad);
    on<PotCreate>(_onCreate);
  }

  Future<void> _onLoad(PotsLoad e, Emitter<PotsState> emit) async {
    emit(state.copyWith(loading: true, error: null));
    try {
      final list = await repo.listPots(e.userId);
      emit(state.copyWith(loading: false, pots: list));
    } catch (err) {
      emit(state.copyWith(loading: false, error: err.toString()));
    }
  }

  Future<void> _onCreate(PotCreate e, Emitter<PotsState> emit) async {
    emit(state.copyWith(creating: true, error: null));
    try {
      await repo.createPot(
        name: e.name,
        goalAmount: e.goalAmount,
        purpose: e.purpose,
        accountId: e.accountId,
        withdrawalCondition: e.withdrawalCondition,
        durationMonths: e.durationMonths,
      );
      final list = await repo.listPots(e.userId);
      emit(state.copyWith(creating: false, pots: list));
    } catch (err) {
      emit(state.copyWith(creating: false, error: err.toString()));
    }
  }
}