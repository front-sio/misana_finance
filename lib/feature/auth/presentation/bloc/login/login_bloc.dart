import 'dart:developer' as developer;
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/utils/message_mapper.dart';
import '../../../domain/repositories/auth_repository.dart';
import 'login_event.dart';
import 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final AuthRepository repo;

  LoginBloc(this.repo) : super(const LoginState()) {
    on<SubmitLogin>(_onSubmit);
  }

  Future<void> _onSubmit(SubmitLogin e, Emitter<LoginState> emit) async {
    emit(state.copyWith(loading: true, error: null, inactive: false, userMessage: null));
    developer.log('Attempting login for: ${e.usernameOrEmail}', name: 'LoginBloc');
    
    try {
      final res = await repo.login(
        usernameOrEmail: e.usernameOrEmail,
        password: e.password,
      );
      
      final user = res['user'] as Map<String, dynamic>?;
      final userMessage = res['user_message'] as String?;
      final inactive = (user?['is_active'] == false);
      
      developer.log('Login successful, user active: ${!inactive}', name: 'LoginBloc');
      
      emit(state.copyWith(
        loading: false, 
        userPayload: res, 
        inactive: inactive,
        userMessage: userMessage ?? MessageMapper.getSuccessMessage('login_success'),
      ));
    } catch (err) {
      developer.log('Login failed: $err', name: 'LoginBloc', level: 1000);
      
      final userMessage = MessageMapper.getAuthErrorMessage(err);
      emit(state.copyWith(
        loading: false, 
        error: err.toString(),
        userMessage: userMessage,
      ));
    }
  }
}