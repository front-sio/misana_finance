import 'package:equatable/equatable.dart';

class KycState extends Equatable {
  final bool loading;
  final bool submitting;
  final String? error;
  final String status; // verified | pending | rejected | unknown
  final String? message;
  final List<Map<String, dynamic>> history;

  const KycState({
    this.loading = false,
    this.submitting = false,
    this.error,
    this.status = 'unknown',
    this.message,
    this.history = const [],
  });

  bool get isVerified => status == 'approved' || status == 'verified';
  bool get isPending => status == 'pending';
  bool get isRejected => status == 'rejected';

  KycState copyWith({
    bool? loading,
    bool? submitting,
    String? error,
    String? status,
    String? message,
    List<Map<String, dynamic>>? history,
  }) {
    return KycState(
      loading: loading ?? this.loading,
      submitting: submitting ?? this.submitting,
      error: error,
      status: status ?? this.status,
      message: message ?? this.message,
      history: history ?? this.history,
    );
  }

  @override
  List<Object?> get props => [loading, submitting, error, status, message, history];
}