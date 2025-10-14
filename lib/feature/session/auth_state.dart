import 'package:equatable/equatable.dart';

class AuthState extends Equatable {
  final bool checking;      // splash checking session
  final bool authenticated; // has valid token + me ok
  final Map<String, dynamic>? user; // user payload from /auth/me
  final String? error;

  const AuthState({
    this.checking = true,
    this.authenticated = false,
    this.user,
    this.error,
  });

  bool get kycPending {
    final status = user?['kyc_verification'] as String?;
    return status == null || status == 'pending';
  }

  AuthState copyWith({
    bool? checking,
    bool? authenticated,
    Map<String, dynamic>? user,
    String? error,
  }) {
    return AuthState(
      checking: checking ?? this.checking,
      authenticated: authenticated ?? this.authenticated,
      user: user ?? this.user,
      error: error,
    );
  }

  @override
  List<Object?> get props => [checking, authenticated, user, error];
}