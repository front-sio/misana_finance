import 'package:equatable/equatable.dart';

class AuthState extends Equatable {
  final bool checking;
  final bool authenticated;
  final Map<String, dynamic>? user;
  final String? error;
  final String? userMessage;

  const AuthState({
    this.checking = false,
    this.authenticated = false,
    this.user,
    this.error,
    this.userMessage,
  });

  AuthState copyWith({
    bool? checking,
    bool? authenticated,
    Map<String, dynamic>? user,
    String? error,
    String? userMessage,
  }) {
    return AuthState(
      checking: checking ?? this.checking,
      authenticated: authenticated ?? this.authenticated,
      user: user ?? this.user,
      error: error,
      userMessage: userMessage,
    );
  }

  @override
  List<Object?> get props => [checking, authenticated, user, error, userMessage];
}