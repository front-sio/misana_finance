enum VerifyChannel { email, phone }

abstract class AuthRepository {
  Future<Map<String, dynamic>> register({
    required String username,
    required String password,
    required String email,
    required String phone,
    required String firstName,
    required String lastName,
    required String gender,
  });

  Future<void> requestVerification({
    required VerifyChannel channel,
    required String usernameOrEmail,
  });

  Future<Map<String, dynamic>> confirmVerification({
    required VerifyChannel channel,
    required String usernameOrEmail,
    required String code,
  });

  Future<Map<String, dynamic>> login({
    required String usernameOrEmail,
    required String password,
  });

  Future<Map<String, dynamic>> me();
}