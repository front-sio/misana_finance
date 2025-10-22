import 'package:equatable/equatable.dart';

class SavingsState extends Equatable {
  final bool loading;   // for list
  final bool creating;  // for create
  final String? error;
  final List<Map<String, dynamic>> accounts;

  const SavingsState({
    required this.loading,
    required this.creating,
    required this.error,
    required this.accounts,
  });

  factory SavingsState.initial() =>
      const SavingsState(loading: false, creating: false, error: null, accounts: <Map<String, dynamic>>[]);

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