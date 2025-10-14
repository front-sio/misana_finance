import 'package:misana_finance_app/feature/kyc/domain/kyc_repository.dart';
import '../datasources/kyc_remote_data_source.dart';

class KycRepositoryImpl implements KycRepository {
  final KycRemoteDataSource remote;
  KycRepositoryImpl(this.remote);

  @override
  Future<List<Map<String, dynamic>>> getStatus(String accountId) {
    return remote.getStatus(accountId);
  }

  @override
  Future<Map<String, dynamic>> submit({
    required String accountId,
    required String documentType,
    required String documentNumber,
    required String fullName,
    required String dateOfBirth,
    String? address,
    String? documentImageBase64,
  }) {
    return remote.submit(
      accountId: accountId,
      documentType: documentType,
      documentNumber: documentNumber,
      fullName: fullName,
      dateOfBirth: dateOfBirth,
      address: address,
      documentImageBase64: documentImageBase64,
    );
  }

  @override
  Future<Map<String, dynamic>> checkVerified(String accountId) {
    return remote.checkVerified(accountId);
  }
}