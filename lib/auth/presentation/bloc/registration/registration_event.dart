import 'package:equatable/equatable.dart';

class RegistrationEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class SubmitRegistration extends RegistrationEvent {
  final String username;
  final String password;
  final String email;
  final String phone;
  final String firstName;
  final String lastName;
  final String gender;

  SubmitRegistration({
    required this.username,
    required this.password,
    required this.email,
    required this.phone,
    required this.firstName,
    required this.lastName,
    required this.gender,
  });

  @override
  List<Object?> get props => [username, email, phone, firstName, lastName, gender];
}