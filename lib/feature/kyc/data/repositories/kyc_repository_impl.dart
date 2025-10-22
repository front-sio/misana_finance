import '../../domain/kyc_repository.dart';
import '../datasources/kyc_remote_data_source.dart';

class KycRepositoryImpl implements KycRepository {
  final KycRemoteDataSource remote;
  KycRepositoryImpl(this.remote);

  @override
  Future<List<Map<String, dynamic>>> getStatusByUser(String userId) {
    return remote.getStatusByUser(userId);
  }

  @override
  Future<Map<String, dynamic>> checkVerifiedByUser(String userId) {
    return remote.checkVerifiedByUser(userId);
  }

  @override
  Future<Map<String, dynamic>> submitByUser({
    required String userId,
    required String documentType,
    required String documentNumber,
    required String fullName,
    required String dateOfBirth,
    String? address,
    String? documentImageBase64,
  }) {
    return remote.submitByUser(
      userId: userId,
      documentType: documentType,
      documentNumber: documentNumber,
      fullName: fullName,
      dateOfBirth: dateOfBirth,
      address: address,
      documentImageBase64: documentImageBase64,
    );
    }
}