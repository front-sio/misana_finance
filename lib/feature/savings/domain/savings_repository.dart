abstract class SavingsRepository {
  Future<Map<String, dynamic>> createPot({
    required String name,
    required String goalAmount, // decimal string
    required String accountId, // uuid (account-service id)
    required int durationMonths,
    String? purpose,
    required String withdrawalCondition, // "amount" | "time" | "both"
  });

  Future<List<Map<String, dynamic>>> listPots(String userId);
}