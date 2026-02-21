abstract class KycRepository {
  Future<List<Map<String, dynamic>>> getStatusByUser(String userId);

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
  });

  Future<Map<String, dynamic>> checkVerifiedByUser(String userId);

  Future<Map<String, dynamic>> getVerificationStatus(String userId);
}