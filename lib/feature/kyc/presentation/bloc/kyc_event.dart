import 'package:equatable/equatable.dart';

abstract class KycEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class KycLoadStatus extends KycEvent {
  final String userId;
  KycLoadStatus({required this.userId});
  @override
  List<Object?> get props => [userId];
}

class KycSubmit extends KycEvent {
  final String userId;
  final String documentType;
  final String documentNumber;
  final String fullName;
  final String dateOfBirth;
  final String? address;
  final String? documentImageBase64;

  KycSubmit({
    required this.userId,
    required this.documentType,
    required this.documentNumber,
    required this.fullName,
    required this.dateOfBirth,
    this.address,
    this.documentImageBase64,
  });

  @override
  List<Object?> get props =>
      [userId, documentType, documentNumber, fullName, dateOfBirth, address, documentImageBase64];
}