import 'package:dio/dio.dart';
import 'package:misana_finance_app/core/network/api_client.dart';

class KycRemoteDataSource {
  final ApiClient client;
  KycRemoteDataSource(this.client);

  Future<List<Map<String, dynamic>>> getStatusByUser(String userId) async {
    final Response res = await client.get('/kyc/status/$userId');
    final data = res.data;
    if (data is List) return data.cast<Map<String, dynamic>>();
    if (data is Map && data['items'] is List) {
      return (data['items'] as List).cast<Map<String, dynamic>>();
    }
    return const <Map<String, dynamic>>[];
  }

  Future<Map<String, dynamic>> checkVerifiedByUser(String userId) async {
    final Response res = await client.get('/kyc/verify/$userId');
    final data = res.data;
    if (data is Map<String, dynamic>) return data;
    return <String, dynamic>{};
  }

  Future<Map<String, dynamic>> submitByUser({
    required String userId,
    required String documentType,
    required String documentNumber,
    required String fullName,
    required String dateOfBirth,
    String? address,
    String? documentImageBase64,
  }) async {
    final payload = <String, dynamic>{
      'document_type': documentType,
      'document_number': documentNumber,
      'full_name': fullName,
      'date_of_birth': dateOfBirth,
      if (address != null && address.trim().isNotEmpty) 'address': address.trim(),
      if (documentImageBase64 != null && documentImageBase64.trim().isNotEmpty)
        'document_image_base64': documentImageBase64.trim(),
    };

    final Response res = await client.post('/kyc/submit/$userId', data: payload);
    final data = res.data;
    if (data is Map<String, dynamic>) return data;
    throw const FormatException('Unexpected response for KYC submit');
  }

  Future<Map<String, dynamic>> getVerificationStatus(String userId) async {
    final Response res = await client.get('/kyc/verification-status/$userId');
    final data = res.data;
    if (data is Map<String, dynamic>) return data;
    return <String, dynamic>{'status': 'unknown'};
  }
}