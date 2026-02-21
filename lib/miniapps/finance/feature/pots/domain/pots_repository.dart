// lib/feature/pots/domain/pots_repository.dart
abstract class PotsRepository {
  Future<Map<String, dynamic>> createPot({
    required String name,
    required double goalAmount,
    required String purpose,
    required String accountId,
    required String withdrawalCondition,
    required int durationMonths,
    required DateTime startDate,
    required DateTime endDate,
  });

  Future<List<Map<String, dynamic>>> listPots(String userId);

  Future<Map<String, dynamic>?> getPlanByPot(String potId);

  // Progress tracking
  Future<Map<String, dynamic>> getDetailedProgress(String potId);
  Future<Map<String, dynamic>> getQuickProgress(String potId);
  Future<List<Map<String, dynamic>>> getAllPotsProgress();

  // Transactions
  Future<Map<String, dynamic>> deposit({
    required String potId,
    required double amount,
    String? note,
  });

  Future<Map<String, dynamic>> withdraw({
    required String potId,
    required double amount,
    String? note,
  });

  Future<List<Map<String, dynamic>>> getLedger(String potId);
}