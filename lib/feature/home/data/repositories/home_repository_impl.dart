
import 'package:misana_finance_app/feature/home/domain/home_repository.dart';

import '../datasources/home_remote_data_source.dart';

class HomeRepositoryImpl implements HomeRepository {
  final HomeRemoteDataSource remote;
  HomeRepositoryImpl(this.remote);

  @override
  Future<List<Map<String, dynamic>>> getAccounts() {
    return remote.getAccounts();
  }
}