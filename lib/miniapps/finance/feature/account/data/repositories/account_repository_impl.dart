import '../../domain/account_repository.dart';
import '../datasources/account_remote_data_source.dart';

class AccountRepositoryImpl implements AccountRepository {
  final AccountRemoteDataSource remote;
  AccountRepositoryImpl(this.remote);

  @override
  Future<Map<String, dynamic>> ensureAccount() => remote.ensure();

  @override
  Future<Map<String, dynamic>?> getByUser(String userId) => remote.getByUser(userId);
}