import 'package:equatable/equatable.dart';

class RegistrationState extends Equatable {
  final bool loading;
  final String? error;
  final Map<String, dynamic>? userPayload;

  const RegistrationState({
    this.loading = false,
    this.error,
    this.userPayload,
  });

  RegistrationState copyWith({
    bool? loading,
    String? error,
    Map<String, dynamic>? userPayload,
  }) {
    return RegistrationState(
      loading: loading ?? this.loading,
      error: error,
      userPayload: userPayload ?? this.userPayload,
    );
  }

  @override
  List<Object?> get props => [loading, error, userPayload];
}