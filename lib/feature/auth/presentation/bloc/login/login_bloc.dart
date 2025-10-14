import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/auth_repository.dart';
import 'login_event.dart';
import 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final AuthRepository repo;

  LoginBloc(this.repo) : super(const LoginState()) {
    on<SubmitLogin>(_onSubmit);
  }

  Future<void> _onSubmit(SubmitLogin e, Emitter<LoginState> emit) async {
    emit(state.copyWith(loading: true, error: null, inactive: false));
    try {
      final res = await repo.login(
        usernameOrEmail: e.usernameOrEmail,
        password: e.password,
      );
      final user = res['user'] as Map<String, dynamic>?;

      final inactive = (user?['is_active'] == false);
      emit(state.copyWith(loading: false, userPayload: res, inactive: inactive));
    } catch (err) {
      emit(state.copyWith(loading: false, error: err.toString()));
    }
  }
}