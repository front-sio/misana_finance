import 'package:equatable/equatable.dart';

abstract class PaymentsEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

/// Load transactions (initial or with overrides). Set append=true to load more.
class PaymentsLoadTx extends PaymentsEvent {
  final String userId;
  final int? page;
  final int? pageSize;
  final String? query;
  final String? type;   // all|deposit|withdrawal|transfer
  final String? status; // all|success|pending|failed|reversed
  final DateTime? from;
  final DateTime? to;
  final bool append;

  PaymentsLoadTx(
    this.userId, {
    this.page,
    this.pageSize,
    this.query,
    this.type,
    this.status,
    this.from,
    this.to,
    this.append = false,
  });

  @override
  List<Object?> get props => [userId, page, pageSize, query, type, status, from, to, append];
}

/// Load next page with current filters (uses state.page/state.pageSize)
class PaymentsLoadMore extends PaymentsEvent {
  final String userId;
  PaymentsLoadMore(this.userId);

  @override
  List<Object?> get props => [userId];
}

/// Update filters then reload from page 1.
class PaymentsSetFilters extends PaymentsEvent {
  final String userId;
  final String? query;
  final String? type;   // all|deposit|withdrawal|transfer
  final String? status; // all|success|pending|failed|reversed
  final DateTime? from;
  final DateTime? to;

  PaymentsSetFilters({
    required this.userId,
    this.query,
    this.type,
    this.status,
    this.from,
    this.to,
  });

  @override
  List<Object?> get props => [userId, query, type, status, from, to];
}

/// Create a deposit, then reload transactions (page 1).
class PaymentsCreateDeposit extends PaymentsEvent {
  final String accountId;   // INTERNAL account UUID required by backend
  final String? potId;      // optional
  final int amountTZS;      // integer amount
  final String userId;      // used to reload

  PaymentsCreateDeposit({
    required this.accountId,
    required this.amountTZS,
    required this.userId,
    this.potId,
  });

  @override
  List<Object?> get props => [
        accountId,
        potId,
        amountTZS,
        userId,
      ];
}

/// Clear the current error in state (useful for dismissing banners/dialogs)
class PaymentsClearError extends PaymentsEvent {}

/// Reset bloc to initial state
class PaymentsReset extends PaymentsEvent {}