import 'package:dio/dio.dart';
import 'package:misana_finance_app/core/network/api_client.dart';

class HomeRemoteDataSource {
  final ApiClient client;
  HomeRemoteDataSource(this.client);

  // Adjust to your real accounts endpoint (e.g., /accounts or /savings/accounts)
  Future<List<Map<String, dynamic>>> getAccounts() async {
    final Response res = await client.get('/accounts');
    final data = res.data;
    if (data is List) {
      return data.cast<Map<String, dynamic>>();
    }
    if (data is Map && data['accounts'] is List) {
      return (data['accounts'] as List).cast<Map<String, dynamic>>();
    }
    if (data is Map<String, dynamic>) {
      return [data];
    }
    return <Map<String, dynamic>>[];
  }
}
