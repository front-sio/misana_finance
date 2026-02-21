import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/account_repository.dart';
import 'account_event.dart';
import 'account_state.dart';

class AccountBloc extends Bloc<AccountEvent, AccountState> {
  final AccountRepository repo;
  AccountBloc(this.repo) : super(const AccountState()) {
    on<AccountEnsure>(_onEnsure);
    on<AccountLoadByUser>(_onLoad);
  }

  Future<void> _onEnsure(AccountEnsure e, Emitter<AccountState> emit) async {
    emit(state.copyWith(loading: true, error: null));
    try {
      final acc = await repo.ensureAccount();
      emit(state.copyWith(loading: false, account: acc));
    } catch (err) {
      emit(state.copyWith(loading: false, error: err.toString()));
    }
  }

  Future<void> _onLoad(AccountLoadByUser e, Emitter<AccountState> emit) async {
    emit(state.copyWith(loading: true, error: null));
    try {
      final acc = await repo.getByUser(e.userId);
      emit(state.copyWith(loading: false, account: acc));
    } catch (err) {
      emit(state.copyWith(loading: false, error: err.toString()));
    }
  }
}