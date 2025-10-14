import 'package:equatable/equatable.dart';

class AccountState extends Equatable {
  final bool loading;
  final String? error;
  final Map<String, dynamic>? account;

  const AccountState({
    this.loading = false,
    this.error,
    this.account,
  });

  AccountState copyWith({
    bool? loading,
    String? error,
    Map<String, dynamic>? account,
  }) {
    return AccountState(
      loading: loading ?? this.loading,
      error: error,
      account: account ?? this.account,
    );
  }

  @override
  List<Object?> get props => [loading, error, account];
}