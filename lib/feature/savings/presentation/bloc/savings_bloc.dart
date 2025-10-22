import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/savings_repository.dart';
import 'savings_event.dart';
import 'savings_state.dart';

class SavingsBloc extends Bloc<SavingsEvent, SavingsState> {
  final SavingsRepository repo;

  SavingsBloc(this.repo) : super(SavingsState.initial()) {
    on<SavingsLoad>(_onLoad);
    on<SavingsCreate>(_onCreate);
  }

  Future<void> _onLoad(SavingsLoad e, Emitter<SavingsState> emit) async {
    emit(state.copyWith(loading: true, error: null));
    try {
      final list = await repo.listPots(e.userId);
      emit(state.copyWith(loading: false, accounts: list, error: null));
    } catch (err) {
      emit(state.copyWith(loading: false, error: err.toString(), accounts: const []));
    }
  }

  Future<void> _onCreate(SavingsCreate e, Emitter<SavingsState> emit) async {
    emit(state.copyWith(creating: true, error: null));
    try {
      final created = await repo.createPot(
        name: e.name,
        goalAmount: e.goalAmount,
        accountId: e.accountId,
        durationMonths: e.durationMonths,
        purpose: e.purpose ?? '', // normalize to string
        withdrawalCondition: e.withdrawalCondition,
      );

      // Option A: add the newly created plan at the top
      final updated = [created, ...state.accounts];
      emit(state.copyWith(creating: false, accounts: updated, error: null));

      // Option B (if you prefer): re-fetch to reflect server-calculated fields
      // final list = await repo.listPots(e.userId);
      // emit(state.copyWith(creating: false, accounts: list, error: null));
    } catch (err) {
      emit(state.copyWith(creating: false, error: err.toString()));
    }
  }
}