import 'package:equatable/equatable.dart';

class HomeState extends Equatable {
  final bool loading;
  final List<Map<String, dynamic>> accounts;
  final String? error;

  const HomeState({
    this.loading = false,
    this.accounts = const [],
    this.error,
  });

  HomeState copyWith({
    bool? loading,
    List<Map<String, dynamic>>? accounts,
    String? error,
  }) {
    return HomeState(
      loading: loading ?? this.loading,
      accounts: accounts ?? this.accounts,
      error: error,
    );
  }

  @override
  List<Object?> get props => [loading, accounts, error];
}