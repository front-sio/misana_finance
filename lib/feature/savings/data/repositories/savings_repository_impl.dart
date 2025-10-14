import '../../domain/savings_repository.dart' as domain;
import '../datasources/savings_remote_data_source.dart';

/// Concrete repository implementation for saving-service endpoints.
class SavingsRepositoryImpl implements domain.SavingsRepository {
  final SavingsRemoteDataSource remote;
  SavingsRepositoryImpl(this.remote);

  @override
  Future<Map<String, dynamic>> createPot({
    required String name,
    required String goalAmount,
    required String accountId,
    required int durationMonths,
    String? purpose,
    required String withdrawalCondition,
  }) {
    return remote.createPot(
      name: name,
      goalAmount: goalAmount,
      accountId: accountId,
      durationMonths: durationMonths,
      purpose: purpose,
      withdrawalCondition: withdrawalCondition,
    );
  }

  @override
  Future<List<Map<String, dynamic>>> listPots(String userId) {
    return remote.listPots(userId);
  }
}