import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';

/// Remote datasource that talks to saving-service.
/// NOTE: The correct endpoints are /saving/pots and NOT /saving/accounts.
class SavingsRemoteDataSource {
  final ApiClient client;
  SavingsRemoteDataSource(this.client);

  /// Create a new saving pot (plan) in saving-service.
  ///
  /// Backend expects:
  /// - name (String, 2..120)
  /// - goal_amount (number)
  /// - purpose (String?, <= 300)
  /// - account_id (uuid)
  /// - withdrawal_condition ("amount" | "time" | "both")
  /// - duration_months (int >= 1)
  Future<Map<String, dynamic>> createPot({
    required String name,
    required String goalAmount,
    required String accountId,
    required int durationMonths,
    String? purpose,
    required String withdrawalCondition,
  }) async {
    final payload = <String, dynamic>{
      'name': name.trim(),
      'goal_amount': double.parse(goalAmount),
      'account_id': accountId,
      if (purpose != null && purpose.isNotEmpty) 'purpose': purpose,
      'withdrawal_condition': withdrawalCondition,
      'duration_months': durationMonths,
    };
    final Response res = await client.post('/saving/pots', data: payload);
    final data = res.data;
    if (data is Map<String, dynamic>) return data;
    throw const FormatException('Unexpected response for createPot');
  }

  /// List pots for a user (maps to GET /saving/pots/:user_id).
  Future<List<Map<String, dynamic>>> listPots(String userId) async {
    final Response res = await client.get('/saving/pots/$userId');
    final data = res.data;
    if (data is List) return data.cast<Map<String, dynamic>>();
    return const <Map<String, dynamic>>[];
  }
}