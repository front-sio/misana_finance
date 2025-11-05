import 'dart:async';

abstract class PaymentsRepository {
  Future<Map<String, dynamic>> createDeposit({
    required String accountId,
    required int amountTZS,
    String? potId,
  });

  // NEW: accountId optional so the UI can pass it when the backend filters by account
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
});

  Future<Map<String, dynamic>> getTransaction({required String id});
}