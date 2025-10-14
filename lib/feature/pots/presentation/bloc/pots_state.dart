import 'package:equatable/equatable.dart';

class PotsState extends Equatable {
  final bool loading;
  final bool creating;
  final String? error;
  final List<Map<String, dynamic>> pots;

  const PotsState({
    this.loading = false,
    this.creating = false,
    this.error,
    this.pots = const [],
  });

  PotsState copyWith({
    bool? loading,
    bool? creating,
    String? error,
    List<Map<String, dynamic>>? pots,
  }) {
    return PotsState(
      loading: loading ?? this.loading,
      creating: creating ?? this.creating,
      error: error,
      pots: pots ?? this.pots,
    );
  }

  @override
  List<Object?> get props => [loading, creating, error, pots];
}