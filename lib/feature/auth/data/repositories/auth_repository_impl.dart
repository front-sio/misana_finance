import 'dart:developer' as developer;
import '../../../../core/storage/token_storage.dart';
import '../../../../core/utils/message_mapper.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remote;
  final TokenStorage tokenStorage;

  AuthRepositoryImpl(this.remote, {TokenStorage? storage})
      : tokenStorage = storage ?? TokenStorage();

  @override
  Future<Map<String, dynamic>> register({
    required String username,
    required String password,
    required String email,
    required String phone,
    required String firstName,
    required String lastName,
    required String gender,
  }) async {
    try {
      developer.log('Attempting user registration', name: 'AuthRepo');
      
      final result = await remote.register({
        'username': username,
        'password': password,
        'email': email,
        'phone': phone,
        'first_name': firstName,
        'last_name': lastName,
        'gender': gender,
      });
      
      developer.log('Registration successful', name: 'AuthRepo');
      return {
        ...result,
        'user_message': MessageMapper.getSuccessMessage('registration_success'),
      };
    } catch (e) {
      developer.log('Registration failed: $e', name: 'AuthRepo', level: 1000);
      throw Exception(MessageMapper.getAuthErrorMessage(e));
    }
  }

  @override
  Future<void> requestVerification({
    required VerifyChannel channel,
    required String usernameOrEmail,
  }) async {
    try {
      developer.log('Requesting ${channel.name} verification for: $usernameOrEmail', name: 'AuthRepo');
      
      if (channel == VerifyChannel.email) {
        await remote.requestEmailCode(usernameOrEmail);
      } else {
        await remote.requestPhoneCode(usernameOrEmail);
      }
      
      developer.log('Verification request sent successfully', name: 'AuthRepo');
    } catch (e) {
      developer.log('Verification request failed: $e', name: 'AuthRepo', level: 1000);
      throw Exception(MessageMapper.getAuthErrorMessage(e));
    }
  }

  @override
  Future<Map<String, dynamic>> confirmVerification({
    required VerifyChannel channel,
    required String usernameOrEmail,
    required String code,
  }) async {
    try {
      developer.log('Confirming ${channel.name} verification', name: 'AuthRepo');
      
      final result = channel == VerifyChannel.email
          ? await remote.confirmEmailCode(usernameOrEmail, code)
          : await remote.confirmPhoneCode(usernameOrEmail, code);
      
      developer.log('Verification confirmed successfully', name: 'AuthRepo');
      return {
        ...result,
        'user_message': MessageMapper.getSuccessMessage('verification_success'),
      };
    } catch (e) {
      developer.log('Verification confirmation failed: $e', name: 'AuthRepo', level: 1000);
      throw Exception(MessageMapper.getAuthErrorMessage(e));
    }
  }

  @override
  Future<Map<String, dynamic>> login({
    required String usernameOrEmail,
    required String password,
  }) async {
    try {
      developer.log('Attempting login for: $usernameOrEmail', name: 'AuthRepo');
      
      final res = await remote.login(usernameOrEmail, password);
      final tokens = (res['tokens'] ?? {}) as Map;
      final access = tokens['access_token'] as String?;
      final refresh = tokens['refresh_token'] as String?;
      
      if (access != null && refresh != null) {
        await tokenStorage.saveTokens(access: access, refresh: refresh);
        developer.log('Tokens saved successfully', name: 'AuthRepo');
      }
      
      developer.log('Login successful', name: 'AuthRepo');
      return {
        ...res,
        'user_message': MessageMapper.getSuccessMessage('login_success'),
      };
    } catch (e) {
      developer.log('Login failed: $e', name: 'AuthRepo', level: 1000);
      throw Exception(MessageMapper.getAuthErrorMessage(e));
    }
  }

  @override
  Future<Map<String, dynamic>> me() async {
    try {
      developer.log('Fetching user profile', name: 'AuthRepo');
      
      final result = await remote.me();
      
      developer.log('User profile fetched successfully', name: 'AuthRepo');
      return {
        ...result,
        'user_message': MessageMapper.getSuccessMessage('session_verified'),
      };
    } catch (e) {
      developer.log('Failed to fetch user profile: $e', name: 'AuthRepo', level: 1000);
      throw Exception(MessageMapper.getAuthErrorMessage(e));
    }
  }
}