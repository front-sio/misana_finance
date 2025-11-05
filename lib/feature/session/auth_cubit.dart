import 'dart:developer' as developer;
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/storage/token_storage.dart';
import '../../core/utils/message_mapper.dart';
import '../auth/domain/repositories/auth_repository.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final TokenStorage storage;
  final AuthRepository authRepo;

  AuthCubit({required this.storage, required this.authRepo})
      : super(const AuthState());

  Future<void> checkSession() async {
    if (state.checking) return;
    
    emit(state.copyWith(checking: true, error: null, userMessage: null));
    developer.log('Starting session check', name: 'AuthCubit');

    try {
      final token = await storage.getAccessToken();
      developer.log('Token exists: ${token != null && token.isNotEmpty}', name: 'AuthCubit');
      
      if (token == null || token.isEmpty) {
        developer.log('No valid tokens found, user needs to login', name: 'AuthCubit');
        emit(state.copyWith(
          checking: false, 
          authenticated: false,
          user: null,
          userMessage: 'Please sign in to continue',
        ));
        return;
      }

      final me = await authRepo.me();
      final userMessage = me['user_message'] as String?;
      
      final Map<String, dynamic>? user =
          (me['user'] as Map<String, dynamic>?) ?? me;

      if (user == null || user.isEmpty) {
        developer.log('Invalid user data received', name: 'AuthCubit');
        await storage.clear();
        emit(state.copyWith(
          checking: false, 
          authenticated: false, 
          user: null,
          userMessage: 'Session invalid. Please sign in again.',
        ));
        return;
      }

      developer.log('Session verified successfully for user: ${user['username'] ?? user['id']}', name: 'AuthCubit');
      emit(state.copyWith(
        checking: false,
        authenticated: true,
        user: user,
        userMessage: userMessage ?? 'Welcome back! Taking you to your dashboard...',
      ));
      
    } catch (e) {
      developer.log('Session check failed: $e', name: 'AuthCubit', level: 1000);
      
      if (e.toString().contains('401') || e.toString().contains('unauthorized')) {
        await storage.clear();
        developer.log('Cleared invalid tokens', name: 'AuthCubit');
      }
      
      final userMessage = MessageMapper.getAuthErrorMessage(e);
      emit(state.copyWith(
        checking: false,
        authenticated: false,
        user: null,
        error: e.toString(),
        userMessage: userMessage,
      ));
    }
  }

  Future<void> refreshProfile() async {
    if (!state.authenticated) return;
    
    developer.log('Refreshing user profile', name: 'AuthCubit');
    
    try {
      final me = await authRepo.me();
      final Map<String, dynamic>? user =
          (me['user'] as Map<String, dynamic>?) ?? me;
      
      if (user != null && user.isNotEmpty) {
        developer.log('Profile refreshed successfully', name: 'AuthCubit');
        emit(state.copyWith(user: user));
      }
    } catch (e) {
      developer.log('Profile refresh failed: $e', name: 'AuthCubit');
    }
  }

  Future<void> login(String usernameOrEmail, String password) async {
    emit(state.copyWith(checking: true, error: null, userMessage: null));
    developer.log('Attempting login for: $usernameOrEmail', name: 'AuthCubit');

    try {
      final result = await authRepo.login(
        usernameOrEmail: usernameOrEmail,
        password: password,
      );
      
      final userMessage = result['user_message'] as String?;
      final Map<String, dynamic>? user =
          (result['user'] as Map<String, dynamic>?) ?? result;
      
      developer.log('Login successful', name: 'AuthCubit');
      
      emit(state.copyWith(
        checking: false,
        authenticated: true,
        user: user,
        userMessage: userMessage ?? 'Login successful! Redirecting...',
      ));
    } catch (e) {
      developer.log('Login failed: $e', name: 'AuthCubit', level: 1000);
      
      final userMessage = MessageMapper.getAuthErrorMessage(e);
      emit(state.copyWith(
        checking: false,
        authenticated: false,
        user: null,
        error: e.toString(),
        userMessage: userMessage,
      ));
    }
  }

  Future<void> signOut() async {
    developer.log('Signing out user', name: 'AuthCubit');
    
    try {
      await storage.clear();
      emit(state.copyWith(
        authenticated: false, 
        user: null,
        userMessage: 'Successfully signed out',
      ));
      developer.log('User signed out successfully', name: 'AuthCubit');
    } catch (e) {
      developer.log('Sign out error: $e', name: 'AuthCubit');
      emit(state.copyWith(
        authenticated: false, 
        user: null,
        error: e.toString(),
        userMessage: 'Signed out with issues',
      ));
    }
  }

  Future<void> logout() async {
    developer.log('Logging out user', name: 'AuthCubit');
    await signOut();
  }

  Future<void> onLoginSuccess() async {
    developer.log('Login success callback triggered', name: 'AuthCubit');
    await checkSession();
  }

  void clearMessages() {
    emit(state.copyWith(error: null, userMessage: null));
  }
}