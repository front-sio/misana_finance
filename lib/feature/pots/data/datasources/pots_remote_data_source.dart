import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';

class PotsRemoteDataSource {
  final ApiClient client;
  PotsRemoteDataSource(this.client);

  Future<Map<String, dynamic>> createPot({
    required String name,
    required double goalAmount,
    String? purpose,
    required String accountId,
    required String withdrawalCondition,
    required int durationMonths,
  }) async {
    final Response res = await client.post('/saving/pots', data: {
      'name': name,
      'goal_amount': goalAmount,
      'purpose': purpose,
      'account_id': accountId,
      'withdrawal_condition': withdrawalCondition,
      'duration_months': durationMonths,
    });
    return res.data as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> listPots(String userId) async {
    final Response res = await client.get('/saving/pots/$userId');
    final data = res.data;
    if (data is List) return data.cast<Map<String, dynamic>>();
    return const [];
  }

  Future<Map<String, dynamic>?> planByPot(String potId) async {
    final Response res = await client.get('/saving/plans/$potId');
    return res.data as Map<String, dynamic>?;
  }
}