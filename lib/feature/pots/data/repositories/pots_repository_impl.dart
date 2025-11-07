// lib/feature/pots/data/repositories/pots_repository_impl.dart
import '../../domain/pots_repository.dart';
import '../datasources/pots_remote_data_source.dart';

class PotsRepositoryImpl implements PotsRepository {
  final PotsRemoteDataSource remote;
  
  PotsRepositoryImpl(this.remote);

  @override
  Future<Map<String, dynamic>> createPot({
    required String name,
    required double goalAmount,
    required String purpose,
    required String accountId,
    required String withdrawalCondition,
    required int durationMonths,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return remote.createPot(
      name: name,
      goalAmount: goalAmount,
      purpose: purpose,
      accountId: accountId,
      withdrawalCondition: withdrawalCondition,
      durationMonths: durationMonths,
      startDate: startDate,
      endDate: endDate,
    );
  }

  @override
  Future<List<Map<String, dynamic>>> listPots(String userId) => remote.listPots(userId);

  @override
  Future<Map<String, dynamic>?> getPlanByPot(String potId) => remote.planByPot(potId);

  @override
  Future<Map<String, dynamic>> getDetailedProgress(String potId) => remote.getDetailedProgress(potId);

  @override
  Future<Map<String, dynamic>> getQuickProgress(String potId) => remote.getQuickProgress(potId);

  @override
  Future<List<Map<String, dynamic>>> getAllPotsProgress() => remote.getAllPotsProgress();

  @override
  Future<Map<String, dynamic>> deposit({
    required String potId,
    required double amount,
    String? note,
  }) => remote.deposit(potId: potId, amount: amount, note: note);

  @override
  Future<Map<String, dynamic>> withdraw({
    required String potId,
    required double amount,
    String? note,
  }) => remote.withdraw(potId: potId, amount: amount, note: note);

  @override
  Future<List<Map<String, dynamic>>> getLedger(String potId) => remote.getLedger(potId);
}