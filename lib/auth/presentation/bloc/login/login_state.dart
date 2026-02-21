import 'package:equatable/equatable.dart';

class LoginState extends Equatable {
  final bool loading;
  final String? error;
  final String? userMessage;
  final Map<String, dynamic>? userPayload;
  final bool inactive;

  const LoginState({
    this.loading = false,
    this.error,
    this.userMessage,
    this.userPayload,
    this.inactive = false,
  });

  LoginState copyWith({
    bool? loading,
    String? error,
    String? userMessage,
    Map<String, dynamic>? userPayload,
    bool? inactive,
  }) {
    return LoginState(
      loading: loading ?? this.loading,
      error: error,
      userMessage: userMessage,
      userPayload: userPayload ?? this.userPayload,
      inactive: inactive ?? this.inactive,
    );
  }

  @override
  List<Object?> get props => [loading, error, userMessage, userPayload, inactive];
}