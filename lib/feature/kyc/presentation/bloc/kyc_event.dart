import 'package:equatable/equatable.dart';

abstract class KycEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

// Load KYC status history for a specific account (UUID)
class KycLoadStatus extends KycEvent {
  final String accountId;
  KycLoadStatus({required this.accountId});

  @override
  List<Object?> get props => [accountId];
}

// Submit KYC details
class KycSubmit extends KycEvent {
  final String accountId;
  final String documentType; // "national_id" | "passport" | "driver_license"
  final String documentNumber;
  final String fullName;
  final String dateOfBirth;  // yyyy-MM-dd
  final String? address;
  final String? documentImageBase64; // data URI, e.g. "data:image/jpeg;base64,..."

  KycSubmit({
    required this.accountId,
    required this.documentType,
    required this.documentNumber,
    required this.fullName,
    required this.dateOfBirth,
    this.address,
    this.documentImageBase64,
  });

  @override
  List<Object?> get props =>
      [accountId, documentType, documentNumber, fullName, dateOfBirth, address, documentImageBase64];
}