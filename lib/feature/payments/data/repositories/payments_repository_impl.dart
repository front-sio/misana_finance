import 'dart:async';

import '../../domain/payments_repository.dart';
import '../datasources/payments_remote_data_source.dart';

class PaymentsRepositoryImpl implements PaymentsRepository {
  final PaymentsRemoteDataSource remote;

  PaymentsRepositoryImpl(this.remote);

  @override
  Future<Map<String, dynamic>> createDeposit({
    required String accountId,
    required int amountTZS,
    String? potId,
  }) {
    return remote
        .createDeposit(
          accountId: accountId,
          amountTZS: amountTZS,
          potId: potId,
        )
        .timeout(const Duration(seconds: 30));
  }

  @override
  Future<Map<String, dynamic>> listTransactions({
    required String userId,
    String? accountId,
    int page = 1,
    int pageSize = 20,
    String query = '',
    String type = 'all',
    String status = 'all',
    DateTime? from,
    DateTime? to,
  }) {
    return remote
        .listTransactions(
          userId: userId,
          accountId: accountId,
          page: page,
          pageSize: pageSize,
          query: query,
          type: type,
          status: status,
          from: from,
          to: to,
        )
        .timeout(const Duration(seconds: 30));
  }

  @override
  Future<Map<String, dynamic>> getTransaction({required String id}) {
    return remote.getTransaction(id).timeout(const Duration(seconds: 20));
  }
}