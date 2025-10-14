import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/payments_repository.dart';
import 'payments_event.dart';
import 'payments_state.dart';

class PaymentsBloc extends Bloc<PaymentsEvent, PaymentsState> {
  final PaymentsRepository repo;

  PaymentsBloc(this.repo) : super(const PaymentsState()) {
    on<PaymentsLoadTx>(_onLoad);
    on<PaymentsLoadMore>(_onLoadMore);
    on<PaymentsSetFilters>(_onSetFilters);
    on<PaymentsCreateDeposit>(_onDeposit);
    on<PaymentsClearError>(_onClearError);
    on<PaymentsReset>(_onReset);
  }

  Future<void> _onLoad(PaymentsLoadTx e, Emitter<PaymentsState> emit) async {
    // Merge incoming overrides with current state
    final page = e.page ?? 1;
    final pageSize = e.pageSize ?? state.pageSize;
    final query = e.query ?? state.query;
    final type = e.type ?? state.type;
    final status = e.status ?? state.status;
    final from = e.from ?? state.from;
    final to = e.to ?? state.to;

    emit(state.copyWith(
      loading: true,
      error: null,
      // When not appending, reset list
      transactions: e.append ? state.transactions : const <Map<String, dynamic>>[],
      page: page,
      pageSize: pageSize,
      query: query,
      type: type,
      status: status,
      from: from,
      to: to,
    ));

    try {
      final data = await repo.listTransactions(
        userId: e.userId,
        page: page,
        pageSize: pageSize,
        query: query,
        type: type,
        status: status,
        from: from,
        to: to,
      );

      final items = ((data['items'] as List?) ?? const <dynamic>[])
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .toList();

      final total = (data['total'] as num?)?.toInt();
      final hasMore = total != null
          ? (page * pageSize) < total
          : (data['has_more'] == true || items.length >= pageSize);

      emit(state.copyWith(
        loading: false,
        error: null,
        transactions: e.append ? [...state.transactions, ...items] : items,
        hasMore: hasMore,
        total: total,
        // Move page pointer to next page if we successfully loaded
        page: hasMore ? page + 1 : page,
      ));
    } catch (err) {
      emit(state.copyWith(loading: false, error: err.toString()));
    }
  }

  Future<void> _onLoadMore(PaymentsLoadMore e, Emitter<PaymentsState> emit) async {
    if (state.loading || !state.hasMore) return;

    // Reuse _onLoad with append=true and current filters/state page
    add(PaymentsLoadTx(
      e.userId,
      page: state.page,
      pageSize: state.pageSize,
      query: state.query,
      type: state.type,
      status: state.status,
      from: state.from,
      to: state.to,
      append: true,
    ));
  }

  Future<void> _onSetFilters(PaymentsSetFilters e, Emitter<PaymentsState> emit) async {
    // Update filters then load first page
    final query = e.query ?? state.query;
    final type = e.type ?? state.type;
    final status = e.status ?? state.status;
    final from = e.from ?? state.from;
    final to = e.to ?? state.to;

    emit(state.copyWith(
      query: query,
      type: type,
      status: status,
      from: from,
      to: to,
      page: 1,
      hasMore: true,
      error: null,
    ));

    add(PaymentsLoadTx(
      e.userId,
      page: 1,
      pageSize: state.pageSize,
      query: query,
      type: type,
      status: status,
      from: from,
      to: to,
      append: false,
    ));
  }

  Future<void> _onDeposit(PaymentsCreateDeposit e, Emitter<PaymentsState> emit) async {
    emit(state.copyWith(submitting: true, error: null));
    try {
      await repo.createDeposit(
        accountId: e.accountId,
        potId: e.potId,
        amountTZS: e.amountTZS,
      );

      // Reload first page with current filters after a successful deposit
      add(PaymentsLoadTx(
        e.userId,
        page: 1,
        pageSize: state.pageSize,
        query: state.query,
        type: state.type,
        status: state.status,
        from: state.from,
        to: state.to,
        append: false,
      ));

      emit(state.copyWith(submitting: false));
    } catch (err) {
      emit(state.copyWith(submitting: false, error: err.toString()));
    }
  }

  void _onClearError(PaymentsClearError e, Emitter<PaymentsState> emit) {
    emit(state.copyWith(error: null));
  }

  void _onReset(PaymentsReset e, Emitter<PaymentsState> emit) {
    emit(const PaymentsState());
  }
}