import 'package:equatable/equatable.dart';

class PaymentsState extends Equatable {
  final bool loading;
  final bool submitting;
  final String? error;

  // Transaction data
  final List<Map<String, dynamic>> transactions;

  // Paging
  final int page; // next page pointer
  final int pageSize;
  final bool hasMore;
  final int? total;

  // Filters
  final String query;
  final String type;   // all|deposit|withdrawal|transfer
  final String status; // all|success|pending|failed|reversed
  final DateTime? from;
  final DateTime? to;

  const PaymentsState({
    this.loading = false,
    this.submitting = false,
    this.error,
    this.transactions = const [],
    this.page = 1,
    this.pageSize = 20,
    this.hasMore = true,
    this.total,
    this.query = '',
    this.type = 'all',
    this.status = 'all',
    this.from,
    this.to,
  });

  PaymentsState copyWith({
    bool? loading,
    bool? submitting,
    String? error,
    List<Map<String, dynamic>>? transactions,
    int? page,
    int? pageSize,
    bool? hasMore,
    int? total,
    String? query,
    String? type,
    String? status,
    DateTime? from,
    DateTime? to,
  }) {
    return PaymentsState(
      loading: loading ?? this.loading,
      submitting: submitting ?? this.submitting,
      // If error param is provided (even null), take it; else keep existing
      error: error != null ? error : this.error,
      transactions: transactions ?? this.transactions,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      hasMore: hasMore ?? this.hasMore,
      total: total ?? this.total,
      query: query ?? this.query,
      type: type ?? this.type,
      status: status ?? this.status,
      from: from ?? this.from,
      to: to ?? this.to,
    );
  }

  @override
  List<Object?> get props => [
        loading,
        submitting,
        error,
        transactions,
        page,
        pageSize,
        hasMore,
        total,
        query,
        type,
        status,
        from,
        to,
      ];
}