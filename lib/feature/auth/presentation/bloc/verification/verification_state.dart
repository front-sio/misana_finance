import 'package:equatable/equatable.dart';

class VerificationState extends Equatable {
  final bool sending;
  final bool sent;
  final bool confirming;
  final bool confirmed;
  final String? error;
  final int resendInSeconds;

  const VerificationState({
    this.sending = false,
    this.sent = false,
    this.confirming = false,
    this.confirmed = false,
    this.error,
    this.resendInSeconds = 0,
  });

  VerificationState copyWith({
    bool? sending,
    bool? sent,
    bool? confirming,
    bool? confirmed,
    String? error,
    int? resendInSeconds,
  }) {
    return VerificationState(
      sending: sending ?? this.sending,
      sent: sent ?? this.sent,
      confirming: confirming ?? this.confirming,
      confirmed: confirmed ?? this.confirmed,
      error: error,
      resendInSeconds: resendInSeconds ?? this.resendInSeconds,
    );
  }

  @override
  List<Object?> get props => [sending, sent, confirming, confirmed, error, resendInSeconds];
}