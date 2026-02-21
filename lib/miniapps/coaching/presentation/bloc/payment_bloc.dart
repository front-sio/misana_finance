import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/coaching_repository.dart';
import 'payment_event.dart';
import 'payment_state.dart';

class PaymentBloc extends Bloc<PaymentEvent, PaymentState> {
  final CoachingRepository repo;
  Timer? _pollTimer;
  int _pollCount = 0;

  PaymentBloc(this.repo) : super(const PaymentInitial()) {
    on<StartPayment>(_onStartPayment);
    on<PollPaymentStatus>(_onPoll);
    on<StopPaymentPolling>(_onStop);
  }

  Future<void> _onStartPayment(StartPayment event, Emitter<PaymentState> emit) async {
    emit(const PaymentInitiating());
    try {
      final payment = await repo.initPayment(
        bookingId: event.bookingId,
        phoneNumber: event.phoneNumber,
      );
      emit(PaymentPending(payment));
      _startPolling(event.bookingId);
    } catch (e) {
      emit(PaymentFailed(e.toString()));
    }
  }

  Future<void> _onPoll(PollPaymentStatus event, Emitter<PaymentState> emit) async {
    try {
      final booking = await repo.getBooking(event.bookingId);
      if (booking.status == 'PAID') {
        _stopPolling();
        emit(PaymentSuccess(booking));
        return;
      }
      if (booking.status == 'CANCELLED') {
        _stopPolling();
        emit(const PaymentFailed('Payment failed or cancelled.'));
        return;
      }
    } catch (e) {
      // keep polling unless max attempts hit
    }

    _pollCount += 1;
    if (_pollCount >= 25) {
      _stopPolling();
      emit(const PaymentFailed('Payment timeout. Please try again.'));
    }
  }

  void _startPolling(String bookingId) {
    _stopPolling();
    _pollCount = 0;
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      add(PollPaymentStatus(bookingId));
    });
  }

  void _onStop(StopPaymentPolling event, Emitter<PaymentState> emit) {
    _stopPolling();
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  @override
  Future<void> close() {
    _stopPolling();
    return super.close();
  }
}
