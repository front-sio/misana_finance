import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:misana_finance_app/feature/home/domain/home_repository.dart';
import 'home_event.dart';
import 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final HomeRepository repo;

  HomeBloc(this.repo) : super(const HomeState()) {
    on<LoadAccounts>(_onLoad);
  }

  Future<void> _onLoad(LoadAccounts e, Emitter<HomeState> emit) async {
    emit(state.copyWith(loading: true, error: null));
    try {
      final accs = await repo.getAccounts();
      emit(state.copyWith(loading: false, accounts: accs));
    } catch (err) {
      emit(state.copyWith(loading: false, error: err.toString()));
    }
  }
}