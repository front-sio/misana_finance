import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/storage/token_storage.dart';
import '../auth/domain/repositories/auth_repository.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final TokenStorage storage;
  final AuthRepository authRepo;

  AuthCubit({required this.storage, required this.authRepo})
      : super(const AuthState());

  Future<void> checkSession() async {
    emit(state.copyWith(checking: true, error: null));
    try {
      final token = await storage.getAccessToken();
      if (token == null || token.isEmpty) {
        emit(state.copyWith(checking: false, authenticated: false, user: null));
        return;
      }

      final me = await authRepo.me();
      // Accept both shapes:
      // - { user: {...} }  (login format)
      // - { id: ..., username: ... } (current /auth/me format)
      final Map<String, dynamic>? user =
          (me['user'] as Map<String, dynamic>?) ??
          (me is Map<String, dynamic> ? me : null);

      if (user == null) {
        emit(state.copyWith(checking: false, authenticated: false, user: null));
        return;
      }

      emit(state.copyWith(checking: false, authenticated: true, user: user));
    } catch (e) {
      emit(state.copyWith(
        checking: false,
        authenticated: false,
        user: null,
        error: e.toString(),
      ));
    }
  }

  Future<void> refreshProfile() async {
    if (!state.authenticated) return;
    try {
      final me = await authRepo.me();
      final Map<String, dynamic>? user =
          (me['user'] as Map<String, dynamic>?) ??
          (me is Map<String, dynamic> ? me : null);
      emit(state.copyWith(user: user));
    } catch (_) {
      // ignore failures silently
    }
  }

  // Existing sign out implementation
  Future<void> signOut() async {
    await storage.clear();
    emit(state.copyWith(authenticated: false, user: null));
  }

  // New: logout alias for clarity across UI
  Future<void> logout() async {
    // If your AuthRepository exposes a server-side logout, you can call it here safely.
    // try { await authRepo.logout(); } catch (_) {}
    await signOut();
  }

  Future<void> onLoginSuccess() async {
    await checkSession();
  }
}