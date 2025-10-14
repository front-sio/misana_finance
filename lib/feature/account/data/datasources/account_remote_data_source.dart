import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';

class AccountRemoteDataSource {
  final ApiClient client;
  AccountRemoteDataSource(this.client);

  Future<Map<String, dynamic>> ensure() async {
    final Response res = await client.post('/account/ensure');
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>?> getByUser(String userId) async {
    final Response res = await client.get('/account/$userId');
    if (res.data == null) return null;
    return res.data as Map<String, dynamic>;
  }
}