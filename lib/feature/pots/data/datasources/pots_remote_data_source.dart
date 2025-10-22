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
    // Backend expects a string for purpose (not null)
    final String safePurpose = (purpose ?? '').trim();

    final Response res = await client.post('/saving/pots', data: {
      'name': name.trim(),
      'goal_amount': goalAmount,
      'account_id': accountId,                 // MUST be internal UUID
      'purpose': safePurpose,                  // always string
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