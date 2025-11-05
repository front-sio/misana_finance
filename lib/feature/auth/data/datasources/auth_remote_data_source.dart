import 'dart:developer' as developer;
import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';

class AuthRemoteDataSource {
  final ApiClient client;
  AuthRemoteDataSource(this.client);

  Future<Map<String, dynamic>> register(Map<String, dynamic> payload) async {
    try {
      developer.log('POST /auth/register', name: 'AuthDataSource');
      final Response res = await client.post('/auth/register', data: payload);
      developer.log('Registration response: ${res.statusCode}', name: 'AuthDataSource');
      return res.data as Map<String, dynamic>;
    } catch (e) {
      developer.log('Registration API error: $e', name: 'AuthDataSource', level: 1000);
      rethrow;
    }
  }

  Future<void> requestEmailCode(String usernameOrEmail) async {
    try {
      developer.log('POST /auth/verify/email/request', name: 'AuthDataSource');
      await client.post('/auth/verify/email/request', data: {'usernameOrEmail': usernameOrEmail});
      developer.log('Email verification request sent', name: 'AuthDataSource');
    } catch (e) {
      developer.log('Email verification request error: $e', name: 'AuthDataSource', level: 1000);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> confirmEmailCode(String usernameOrEmail, String code) async {
    try {
      developer.log('POST /auth/verify/email/confirm', name: 'AuthDataSource');
      final res = await client.post('/auth/verify/email/confirm', data: {
        'usernameOrEmail': usernameOrEmail, 
        'code': code
      });
      developer.log('Email verification confirmed: ${res.statusCode}', name: 'AuthDataSource');
      return res.data as Map<String, dynamic>;
    } catch (e) {
      developer.log('Email verification confirm error: $e', name: 'AuthDataSource', level: 1000);
      rethrow;
    }
  }

  Future<void> requestPhoneCode(String usernameOrEmail) async {
    try {
      developer.log('POST /auth/verify/phone/request', name: 'AuthDataSource');
      await client.post('/auth/verify/phone/request', data: {'usernameOrEmail': usernameOrEmail});
      developer.log('Phone verification request sent', name: 'AuthDataSource');
    } catch (e) {
      developer.log('Phone verification request error: $e', name: 'AuthDataSource', level: 1000);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> confirmPhoneCode(String usernameOrEmail, String code) async {
    try {
      developer.log('POST /auth/verify/phone/confirm', name: 'AuthDataSource');
      final res = await client.post('/auth/verify/phone/confirm', data: {
        'usernameOrEmail': usernameOrEmail, 
        'code': code
      });
      developer.log('Phone verification confirmed: ${res.statusCode}', name: 'AuthDataSource');
      return res.data as Map<String, dynamic>;
    } catch (e) {
      developer.log('Phone verification confirm error: $e', name: 'AuthDataSource', level: 1000);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> login(String usernameOrEmail, String password) async {
    try {
      developer.log('POST /auth/login for: $usernameOrEmail', name: 'AuthDataSource');
      final res = await client.post('/auth/login', data: {
        'usernameOrEmail': usernameOrEmail,
        'password': password,
      });
      developer.log('Login response: ${res.statusCode}', name: 'AuthDataSource');
      return res.data as Map<String, dynamic>;
    } catch (e) {
      developer.log('Login API error: $e', name: 'AuthDataSource', level: 1000);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> me() async {
    try {
      developer.log('GET /auth/me', name: 'AuthDataSource');
      final res = await client.get('/auth/me');
      developer.log('Profile response: ${res.statusCode}', name: 'AuthDataSource');
      return res.data as Map<String, dynamic>;
    } catch (e) {
      developer.log('Profile API error: $e', name: 'AuthDataSource', level: 1000);
      rethrow;
    }
  }
}