abstract class PotsRepository {
  Future<Map<String, dynamic>> createPot({
    required String name,
    required double goalAmount,
    String? purpose,
    required String accountId,
    required String withdrawalCondition, // amount|time|both
    required int durationMonths,
  });

  Future<List<Map<String, dynamic>>> listPots(String userId);

  Future<Map<String, dynamic>?> getPlanByPot(String potId);
}