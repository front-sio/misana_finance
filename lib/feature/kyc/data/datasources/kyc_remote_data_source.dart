import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';

class KycRemoteDataSource {
  final ApiClient client;
  KycRemoteDataSource(this.client);

  Future<List<Map<String, dynamic>>> getStatus(String accountId) async {
    final Response res = await client.get('/kyc/status/$accountId');
    final data = res.data;
    if (data is List) return data.cast<Map<String, dynamic>>();
    return const <Map<String, dynamic>>[];
  }

  Future<Map<String, dynamic>> submit({
    required String accountId,
    required String documentType,
    required String documentNumber,
    required String fullName,
    required String dateOfBirth,
    String? address,
    String? documentImageBase64,
  }) async {
    final payload = <String, dynamic>{
      'account_id': accountId,
      'document_type': documentType,
      'document_number': documentNumber,
      'full_name': fullName,
      'date_of_birth': dateOfBirth,
      if (address != null && address.isNotEmpty) 'address': address,
      if (documentImageBase64 != null && documentImageBase64.isNotEmpty)
        'document_image_base64': documentImageBase64,
    };

    final Response res = await client.post('/kyc/submit', data: payload);
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> checkVerified(String accountId) async {
    final Response res = await client.get('/kyc/verify/$accountId');
    return res.data as Map<String, dynamic>;
  }
}