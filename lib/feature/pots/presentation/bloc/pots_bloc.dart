// lib/feature/pots/presentation/bloc/pots_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/pots_repository.dart';
import 'pots_event.dart';
import 'pots_state.dart';

class PotsBloc extends Bloc<PotsEvent, PotsState> {
  final PotsRepository repo;
  
  PotsBloc(this.repo) : super(PotInitial()) {
    on<PotsLoad>(_onLoad);
    on<PotCreate>(_onCreate);
    on<PotDeposit>(_onDeposit);
    on<PotWithdraw>(_onWithdraw);
    on<PotProgressLoad>(_onProgressLoad);
  }

  Future<void> _onLoad(PotsLoad e, Emitter<PotsState> emit) async {
    emit(PotLoading());
    try {
      final list = await repo.listPots(e.userId);
      emit(PotsLoaded(list));
    } catch (err) {
      emit(PotError(err.toString()));
    }
  }

  Future<void> _onCreate(PotCreate e, Emitter<PotsState> emit) async {
    emit(PotLoading());
    try {
      await repo.createPot(
        name: e.name,
        goalAmount: e.goalAmount,
        purpose: e.purpose,
        accountId: e.accountId,
        withdrawalCondition: e.withdrawalCondition,
        durationMonths: e.durationMonths,
        startDate: e.startDate,
        endDate: e.endDate,
      );
      final list = await repo.listPots(e.userId);
      emit(PotsLoaded(list));
    } catch (err) {
      emit(PotError(err.toString()));
    }
  }

  Future<void> _onDeposit(PotDeposit e, Emitter<PotsState> emit) async {
    emit(PotLoading());
    try {
      await repo.deposit(
        potId: e.potId,
        amount: e.amount,
        note: e.note,
      );
      emit(const PotActionSuccess('Deposit successful'));
    } catch (err) {
      emit(PotError(err.toString()));
    }
  }

  Future<void> _onWithdraw(PotWithdraw e, Emitter<PotsState> emit) async {
    emit(PotLoading());
    try {
      await repo.withdraw(
        potId: e.potId,
        amount: e.amount,
        note: e.note,
      );
      emit(const PotActionSuccess('Withdrawal successful'));
    } catch (err) {
      emit(PotError(err.toString()));
    }
  }

  Future<void> _onProgressLoad(PotProgressLoad e, Emitter<PotsState> emit) async {
    emit(PotLoading());
    try {
      final progress = await repo.getDetailedProgress(e.potId);
      emit(PotProgressLoaded(progress));
    } catch (err) {
      emit(PotError(err.toString()));
    }
  }
}