abstract class KycRepository {
  // Returns history (latest first)
  Future<List<Map<String, dynamic>>> getStatus(String accountId);

  // Submit KYC payload (JSON). For multipart uploads, add a separate method.
  Future<Map<String, dynamic>> submit({
    required String accountId,
    required String documentType, // "national_id" | "passport" | "driver_license"
    required String documentNumber,
    required String fullName,
    required String dateOfBirth, // yyyy-MM-dd
    String? address,
    String? documentImageBase64, // data URI e.g. "data:image/jpeg;base64,..."
  });

  // { is_verified: bool }
  Future<Map<String, dynamic>> checkVerified(String accountId);
}