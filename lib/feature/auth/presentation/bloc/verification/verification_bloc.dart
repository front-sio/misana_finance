import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/auth_repository.dart';
import 'verification_event.dart';
import 'verification_state.dart';

class Ticker {
  const Ticker();

  // Emits: 60, 59, ..., 0 (one per second)
  Stream<int> tick({required int ticks}) async* {
    for (var i = ticks; i >= 0; i--) {
      yield i;
      if (i > 0) {
        await Future.delayed(const Duration(seconds: 1));
      }
    }
  }
}

class VerificationBloc extends Bloc<VerificationEvent, VerificationState> {
  final AuthRepository repo;
  final Ticker _ticker;

  VerificationBloc(this.repo, {Ticker? ticker})
      : _ticker = ticker ?? const Ticker(),
        super(const VerificationState()) {
    on<SendVerificationCode>(_onSend);
    on<ConfirmVerificationCode>(_onConfirm);
  }

  Future<void> _onSend(
    SendVerificationCode e,
    Emitter<VerificationState> emit,
  ) async {
    // Block resends during cooldown or while sending
    if (state.resendInSeconds > 0 || state.sending) return;

    emit(state.copyWith(sending: true, error: null));
    try {
      await repo.requestVerification(
        channel: e.channel,
        usernameOrEmail: e.usernameOrEmail,
      );

      // Mark sent and stop "sending"
      emit(state.copyWith(sending: false, sent: true));

      // Drive cooldown from a Stream; all emits stay within this handler
      await emit.forEach<int>(
        _ticker.tick(ticks: 60),
        onData: (secondsLeft) => state.copyWith(resendInSeconds: secondsLeft),
        onError: (err, _) => state.copyWith(error: err.toString()),
      );
      // After stream completes, resendInSeconds == 0 and user can resend again.
    } catch (err) {
      emit(state.copyWith(sending: false, error: err.toString()));
    }
  }

  Future<void> _onConfirm(
    ConfirmVerificationCode e,
    Emitter<VerificationState> emit,
  ) async {
    emit(state.copyWith(confirming: true, error: null));
    try {
      await repo.confirmVerification(
        channel: e.channel,
        usernameOrEmail: e.usernameOrEmail,
        code: e.code,
      );
      emit(state.copyWith(confirming: false, confirmed: true));
    } catch (err) {
      emit(state.copyWith(confirming: false, error: err.toString()));
    }
  }
}