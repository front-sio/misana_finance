import 'package:equatable/equatable.dart';

abstract class KycEvent extends Equatable {
  const KycEvent();
  @override
  List<Object?> get props => [];
}

class KycLoadStatus extends KycEvent {
  final String userId;
  const KycLoadStatus({required this.userId});
  @override
  List<Object?> get props => [userId];
}

class KycSubmit extends KycEvent {
  final String userId;
  final String documentType;
  final String documentNumber;
  final String? nidaNumber;
  final String fullName;
  final String dateOfBirth;
  final String? placeOfBirth;
  final String? address;
  final String? documentImageBase64;
  final String? filePath;
  const KycSubmit({
    required this.userId,
    required this.documentType,
    required this.documentNumber,
    this.nidaNumber,
    required this.fullName,
    required this.dateOfBirth,
    this.placeOfBirth,
    this.address,
    this.documentImageBase64,
    this.filePath,
  });

  @override
  List<Object?> get props => [
        userId,
        documentType,
        documentNumber,
        nidaNumber,
        fullName,
        dateOfBirth,
        placeOfBirth,
        address,
        documentImageBase64,
        filePath,
      ];
}

class KycCheckVerificationStatus extends KycEvent {
  final String userId;
  const KycCheckVerificationStatus({required this.userId});
  @override
  List<Object?> get props => [userId];
}

class KycStartPolling extends KycEvent {
  final String userId;
  final Duration? interval;
  const KycStartPolling({required this.userId, this.interval});
  @override
  List<Object?> get props => [userId, interval];
}

class KycStopPolling extends KycEvent {
  const KycStopPolling();
}

class KycWebSocketUpdate extends KycEvent {
  final Map<String, dynamic> data;
  const KycWebSocketUpdate(this.data);
  @override
  List<Object?> get props => [data];
}