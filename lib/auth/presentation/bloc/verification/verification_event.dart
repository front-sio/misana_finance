import 'package:equatable/equatable.dart';
import '../../../domain/repositories/auth_repository.dart';

class VerificationEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class SendVerificationCode extends VerificationEvent {
  final VerifyChannel channel;
  final String usernameOrEmail;
  SendVerificationCode(this.channel, this.usernameOrEmail);

  @override
  List<Object?> get props => [channel, usernameOrEmail];
}

class ConfirmVerificationCode extends VerificationEvent {
  final VerifyChannel channel;
  final String usernameOrEmail;
  final String code;
  ConfirmVerificationCode(this.channel, this.usernameOrEmail, this.code);

  @override
  List<Object?> get props => [channel, usernameOrEmail, code];
}