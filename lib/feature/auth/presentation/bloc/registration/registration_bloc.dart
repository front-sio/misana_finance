import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:misana_finance_app/feature/auth/domain/repositories/auth_repository.dart';
import 'registration_event.dart';
import 'registration_state.dart';

class RegistrationBloc extends Bloc<RegistrationEvent, RegistrationState> {
  final AuthRepository repo;

  RegistrationBloc(this.repo) : super(const RegistrationState()) {
    on<SubmitRegistration>(_onSubmit);
  }

  Future<void> _onSubmit(SubmitRegistration e, Emitter<RegistrationState> emit) async {
    emit(state.copyWith(loading: true, error: null));
    try {
      final res = await repo.register(
        username: e.username,
        password: e.password,
        email: e.email,
        phone: e.phone,
        firstName: e.firstName,
        lastName: e.lastName,
        gender: e.gender,
      );
      emit(state.copyWith(loading: false, userPayload: res));
    } catch (err) {
      emit(state.copyWith(loading: false, error: err.toString()));
    }
  }
}