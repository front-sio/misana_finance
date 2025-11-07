// lib/feature/pots/data/datasources/pots_remote_data_source.dart
import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';

class PotsRemoteDataSource {
  final ApiClient client;
  
  PotsRemoteDataSource(this.client);

  Future<Map<String, dynamic>> createPot({
    required String name,
    required double goalAmount,
    required String purpose,
    required String accountId,
    required String withdrawalCondition,
    required int durationMonths,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final Response res = await client.post('/saving/pots', data: {
      'name': name.trim(),
      'goal_amount': goalAmount,
      'account_id': accountId,
      'purpose': purpose.trim(),
      'withdrawal_condition': withdrawalCondition,
      'duration_months': durationMonths,
      'start_date': _formatDate(startDate),
      'end_date': _formatDate(endDate),
    });

    return res.data as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> listPots(String userId) async {
    final Response res = await client.get('/saving/pots/user/$userId');
    final data = res.data;

    if (data is List) {
      return data.cast<Map<String, dynamic>>();
    }
    return const [];
  }

  Future<Map<String, dynamic>?> getPotDetail(String potId) async {
    final Response res = await client.get('/saving/pots/$potId');
    return res.data as Map<String, dynamic>?;
  }

  Future<Map<String, dynamic>?> planByPot(String potId) async {
    final Response res = await client.get('/saving/plans/$potId');
    return res.data as Map<String, dynamic>?;
  }

  // Progress tracking
  Future<Map<String, dynamic>> getDetailedProgress(String potId) async {
    final Response res = await client.get('/saving/progress/detailed/$potId');
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getQuickProgress(String potId) async {
    final Response res = await client.get('/saving/progress/quick/$potId');
    return res.data as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> getAllPotsProgress() async {
    final Response res = await client.get('/saving/progress/all');
    final data = res.data;
    
    if (data is List) {
      return data.cast<Map<String, dynamic>>();
    }
    return const [];
  }

  // Transactions
  Future<Map<String, dynamic>> deposit({
    required String potId,
    required double amount,
    String? note,
  }) async {
    final Response res = await client.post('/saving/$potId/deposit', data: {
      'amount': amount,
      if (note != null) 'note': note,
    });
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> withdraw({
    required String potId,
    required double amount,
    String? note,
  }) async {
    final Response res = await client.post('/saving/$potId/withdraw', data: {
      'amount': amount,
      if (note != null) 'note': note,
    });
    return res.data as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> getLedger(String potId) async {
    final Response res = await client.get('/saving/ledger/$potId');
    final data = res.data;
    
    if (data is List) {
      return data.cast<Map<String, dynamic>>();
    }
    return const [];
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}