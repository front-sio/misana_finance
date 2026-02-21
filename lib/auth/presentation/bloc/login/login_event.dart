import 'package:equatable/equatable.dart';

class LoginEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class SubmitLogin extends LoginEvent {
  final String usernameOrEmail;
  final String password;

  SubmitLogin({required this.usernameOrEmail, required this.password});

  @override
  List<Object?> get props => [usernameOrEmail, password];
}