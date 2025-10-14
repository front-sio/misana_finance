import '../../domain/pots_repository.dart';
import '../datasources/pots_remote_data_source.dart';

class PotsRepositoryImpl implements PotsRepository {
  final PotsRemoteDataSource remote;
  PotsRepositoryImpl(this.remote);

  @override
  Future<Map<String, dynamic>> createPot({
    required String name,
    required double goalAmount,
    String? purpose,
    required String accountId,
    required String withdrawalCondition,
    required int durationMonths,
  }) {
    return remote.createPot(
      name: name,
      goalAmount: goalAmount,
      purpose: purpose,
      accountId: accountId,
      withdrawalCondition: withdrawalCondition,
      durationMonths: durationMonths,
    );
  }

  @override
  Future<List<Map<String, dynamic>>> listPots(String userId) => remote.listPots(userId);

  @override
  Future<Map<String, dynamic>?> getPlanByPot(String potId) => remote.planByPot(potId);
}