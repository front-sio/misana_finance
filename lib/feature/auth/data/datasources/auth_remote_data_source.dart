import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';

class AuthRemoteDataSource {
  final ApiClient client;
  AuthRemoteDataSource(this.client);

  Future<Map<String, dynamic>> register(Map<String, dynamic> payload) async {
    final Response res = await client.post('/auth/register', data: payload);
    return res.data as Map<String, dynamic>;
  }

  Future<void> requestEmailCode(String usernameOrEmail) async {
    await client.post('/auth/verify/email/request', data: {'usernameOrEmail': usernameOrEmail});
  }

  Future<Map<String, dynamic>> confirmEmailCode(String usernameOrEmail, String code) async {
    final res = await client.post('/auth/verify/email/confirm', data: {'usernameOrEmail': usernameOrEmail, 'code': code});
    return res.data as Map<String, dynamic>;
  }

  Future<void> requestPhoneCode(String usernameOrEmail) async {
    await client.post('/auth/verify/phone/request', data: {'usernameOrEmail': usernameOrEmail});
  }

  Future<Map<String, dynamic>> confirmPhoneCode(String usernameOrEmail, String code) async {
    final res = await client.post('/auth/verify/phone/confirm', data: {'usernameOrEmail': usernameOrEmail, 'code': code});
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> login(String usernameOrEmail, String password) async {
    final res = await client.post('/auth/login', data: {
      'usernameOrEmail': usernameOrEmail,
      'password': password,
    });
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> me() async {
    final res = await client.get('/auth/me');
    return res.data as Map<String, dynamic>;
  }
}