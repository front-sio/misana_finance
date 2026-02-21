import 'dart:io';
import 'package:dio/dio.dart';
import 'package:misana_finance_app/core/network/api_client.dart';

/// Remote data source for KYC service.
class KycRemoteDataSource {
  final ApiClient client;
  KycRemoteDataSource(this.client);

  /// Returns full submission history for a user (latest first expected).
  Future<List<Map<String, dynamic>>> getStatusByUser(String userId) async {
    final Response res = await client.get('/kyc/status/$userId');
    final data = res.data;
    if (data is List) return data.cast<Map<String, dynamic>>();
    if (data is Map && data['items'] is List) {
      return (data['items'] as List).cast<Map<String, dynamic>>();
    }
    return const <Map<String, dynamic>>[];
  }

  /// Lightweight endpoint - returns is_verified plus optional message/status.
  Future<Map<String, dynamic>> checkVerifiedByUser(String userId) async {
    final Response res = await client.get('/kyc/verify/$userId');
    final data = res.data;
    if (data is Map<String, dynamic>) return data;
    return <String, dynamic>{};
  }

  /// Realtime consolidated status (cached or DB fallback).
  Future<Map<String, dynamic>> getVerificationStatus(String userId) async {
    final Response res = await client.get('/kyc/verification-status/$userId');
    final data = res.data;
    if (data is Map<String, dynamic>) return data;
    return <String, dynamic>{'status': 'unknown'};
  }

  /// Submit KYC. Supports sending base64 image OR multipart file path.
  /// If [filePath] is provided, overrides base64 field.
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
  }) async {
    late Response res;

    final payload = <String, dynamic>{
      'document_type': documentType,
      'document_number': documentNumber,
      if (nidaNumber != null && nidaNumber.trim().isNotEmpty) 'nida_number': nidaNumber.trim(),
      'full_name': fullName,
      'date_of_birth': dateOfBirth,
      if (placeOfBirth != null && placeOfBirth.trim().isNotEmpty) 'place_of_birth': placeOfBirth.trim(),
      if (address != null && address.trim().isNotEmpty) 'address': address.trim(),
      if (documentImageBase64 != null &&
          documentImageBase64.trim().isNotEmpty &&
          (filePath == null || filePath.isEmpty))
        'document_image_base64': documentImageBase64.trim(),
    };

    if (filePath != null && filePath.isNotEmpty && File(filePath).existsSync()) {
      final form = FormData.fromMap({
        ...payload,
        'document_image': await MultipartFile.fromFile(filePath),
      });
      res = await client.post('/kyc/submit/$userId',
          data: form,
          headers: {
            // Let Dio set multipart boundary
            'Content-Type': 'multipart/form-data',
          },
          extra: const {'toastOnSuccess': true});
    } else {
      res = await client.post('/kyc/submit/$userId',
          data: payload, extra: const {'toastOnSuccess': true});
    }

    final data = res.data;
    if (data is Map<String, dynamic>) return data;
    throw const FormatException('Unexpected response for KYC submit');
  }
}