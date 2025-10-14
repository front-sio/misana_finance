import '../../../../core/storage/token_storage.dart';
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
  }) {
    return remote.register({
      'username': username,
      'password': password,
      'email': email,
      'phone': phone,
      'first_name': firstName,
      'last_name': lastName,
      'gender': gender,
    });
  }

  @override
  Future<void> requestVerification({required VerifyChannel channel, required String usernameOrEmail}) {
    return channel == VerifyChannel.email
        ? remote.requestEmailCode(usernameOrEmail)
        : remote.requestPhoneCode(usernameOrEmail);
  }

  @override
  Future<Map<String, dynamic>> confirmVerification({
    required VerifyChannel channel,
    required String usernameOrEmail,
    required String code,
  }) {
    return channel == VerifyChannel.email
        ? remote.confirmEmailCode(usernameOrEmail, code)
        : remote.confirmPhoneCode(usernameOrEmail, code);
  }

  @override
  Future<Map<String, dynamic>> login({
    required String usernameOrEmail,
    required String password,
  }) async {
    final res = await remote.login(usernameOrEmail, password);
    final tokens = (res['tokens'] ?? {}) as Map;
    final access = tokens['access_token'] as String?;
    final refresh = tokens['refresh_token'] as String?;
    if (access != null && refresh != null) {
      await tokenStorage.saveTokens(access: access, refresh: refresh);
    }
    return res;
  }

  @override
  Future<Map<String, dynamic>> me() {
    return remote.me();
  }
}