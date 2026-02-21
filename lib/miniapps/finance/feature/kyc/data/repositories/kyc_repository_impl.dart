import '../../domain/kyc_repository.dart';
import '../datasources/kyc_remote_data_source.dart';

class KycRepositoryImpl implements KycRepository {
  final KycRemoteDataSource remote;
  KycRepositoryImpl(this.remote);

  @override
  Future<List<Map<String, dynamic>>> getStatusByUser(String userId) =>
      remote.getStatusByUser(userId);

  @override
  Future<Map<String, dynamic>> checkVerifiedByUser(String userId) =>
      remote.checkVerifiedByUser(userId);

  @override
  Future<Map<String, dynamic>> getVerificationStatus(String userId) =>
      remote.getVerificationStatus(userId);

  @override
  Future<Map<String, dynamic>> submitByUser({
    required String userId,
    required String documentType,
    required String documentNumber,
    String? nidaNumber,
    required String fullName,
    required String dateOfBirth,
    String? placeOfBirth,
    String? address,
    String? documentImageBase64,
    String? filePath,
  }) {
    return remote.submitByUser(
      userId: userId,
      documentType: documentType,
      documentNumber: documentNumber,
      nidaNumber: nidaNumber,
      fullName: fullName,
      dateOfBirth: dateOfBirth,
      placeOfBirth: placeOfBirth,
      address: address,
      documentImageBase64: documentImageBase64,
      filePath: filePath,
    );
  }
}