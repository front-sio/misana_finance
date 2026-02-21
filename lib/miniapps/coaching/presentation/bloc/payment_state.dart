import 'package:equatable/equatable.dart';
import '../../data/models.dart';

abstract class PaymentState extends Equatable {
  const PaymentState();

  @override
  List<Object?> get props => [];
}

class PaymentInitial extends PaymentState {
  const PaymentInitial();
}

class PaymentInitiating extends PaymentState {
  const PaymentInitiating();
}

class PaymentPending extends PaymentState {
  final PaymentInfo payment;
  const PaymentPending(this.payment);

  @override
  List<Object?> get props => [payment];
}

class PaymentSuccess extends PaymentState {
  final Booking booking;
  const PaymentSuccess(this.booking);

  @override
  List<Object?> get props => [booking];
}

class PaymentFailed extends PaymentState {
  final String message;
  const PaymentFailed(this.message);

  @override
  List<Object?> get props => [message];
}
