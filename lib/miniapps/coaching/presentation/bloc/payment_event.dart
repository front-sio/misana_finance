import 'package:equatable/equatable.dart';

abstract class PaymentEvent extends Equatable {
  const PaymentEvent();

  @override
  List<Object?> get props => [];
}

class StartPayment extends PaymentEvent {
  final String bookingId;
  final String phoneNumber;

  const StartPayment({required this.bookingId, required this.phoneNumber});

  @override
  List<Object?> get props => [bookingId, phoneNumber];
}

class PollPaymentStatus extends PaymentEvent {
  final String bookingId;
  const PollPaymentStatus(this.bookingId);

  @override
  List<Object?> get props => [bookingId];
}

class StopPaymentPolling extends PaymentEvent {
  const StopPaymentPolling();
}
