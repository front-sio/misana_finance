import 'package:equatable/equatable.dart';

class SavingsState extends Equatable {
  final bool loading;
  final bool creating;
  final String? error; // user-friendly message in UI
  final List<Map<String, dynamic>> accounts;

  const SavingsState({
    this.loading = false,
    this.creating = false,
    this.error,
    this.accounts = const [],
  });

  SavingsState copyWith({
    bool? loading,
    bool? creating,
    String? error,
    List<Map<String, dynamic>>? accounts,
  }) {
    return SavingsState(
      loading: loading ?? this.loading,
      creating: creating ?? this.creating,
      error: error,
      accounts: accounts ?? this.accounts,
    );
  }

  @override
  List<Object?> get props => [loading, creating, error, accounts];
}