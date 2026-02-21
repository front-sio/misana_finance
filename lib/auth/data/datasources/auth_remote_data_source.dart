import 'dart:developer' as developer;
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:misana_finance_app/core/network/api_client.dart';

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

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    try {
      developer.log('PATCH /auth/me/profile', name: 'AuthDataSource');
      final res = await client.patch('/auth/me/profile', data: data);
      developer.log('Update profile response: ${res.statusCode}', name: 'AuthDataSource');
      return res.data as Map<String, dynamic>;
    } catch (e) {
      developer.log('Update profile API error: $e', name: 'AuthDataSource', level: 1000);
      rethrow;
    }
  }

  Future<void> changePassword(String oldPassword, String newPassword) async {
    try {
      developer.log('POST /auth/me/password', name: 'AuthDataSource');
      await client.post('/auth/me/password', data: {
        'oldPassword': oldPassword,
        'newPassword': newPassword,
      });
      developer.log('Change password success', name: 'AuthDataSource');
    } catch (e) {
      developer.log('Change password API error: $e', name: 'AuthDataSource', level: 1000);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> uploadProfilePicture(File file) async {
    try {
      developer.log('POST /auth/me/profile-picture (multipart)', name: 'AuthDataSource');
      final fileName = file.uri.pathSegments.isNotEmpty ? file.uri.pathSegments.last : 'profile.jpg';
      final form = FormData.fromMap({
        'profile_picture': await MultipartFile.fromFile(
          file.path,
          filename: fileName,
        ),
      });

      final res = await client.post(
        '/auth/me/profile-picture',
        data: form,
        headers: {'Content-Type': 'multipart/form-data'},
      );
      developer.log('Upload profile picture response: ${res.statusCode}', name: 'AuthDataSource');
      return res.data as Map<String, dynamic>;
    } catch (e) {
      developer.log('Upload profile picture API error: $e', name: 'AuthDataSource', level: 1000);
      rethrow;
    }
  }
}
