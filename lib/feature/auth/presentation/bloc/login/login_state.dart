import 'package:equatable/equatable.dart';

class LoginState extends Equatable {
  final bool loading;
  final String? error;
  final Map<String, dynamic>? userPayload;
  final bool inactive; // backend says is_active = false

  const LoginState({
    this.loading = false,
    this.error,
    this.userPayload,
    this.inactive = false,
  });

  LoginState copyWith({
    bool? loading,
    String? error,
    Map<String, dynamic>? userPayload,
    bool? inactive,
  }) {
    return LoginState(
      loading: loading ?? this.loading,
      error: error,
      userPayload: userPayload ?? this.userPayload,
      inactive: inactive ?? this.inactive,
    );
  }

  @override
  List<Object?> get props => [loading, error, userPayload, inactive];
}