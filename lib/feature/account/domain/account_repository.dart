abstract class AccountRepository {
  Future<Map<String, dynamic>> ensureAccount(); // POST /account/ensure
  Future<Map<String, dynamic>?> getByUser(String userId); // GET /account/:userId
}