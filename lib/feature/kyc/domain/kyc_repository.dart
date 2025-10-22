abstract class KycRepository {
  Future<List<Map<String, dynamic>>> getStatusByUser(String userId);
  Future<Map<String, dynamic>> submitByUser({
    required String userId,
    required String documentType,
    required String documentNumber,
    required String fullName,
    required String dateOfBirth,
    String? address,
    String? documentImageBase64,
  });
  Future<Map<String, dynamic>> checkVerifiedByUser(String userId);
}