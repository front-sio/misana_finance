import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/savings_repository.dart';
import 'savings_event.dart';
import 'savings_state.dart';

class SavingsBloc extends Bloc<SavingsEvent, SavingsState> {
  final SavingsRepository repo;

  SavingsBloc(this.repo) : super(const SavingsState()) {
    on<SavingsLoad>(_onLoad);
    on<SavingsCreate>(_onCreate);
  }

  String _humanizeError(Object err) {
    try {
      if (err is DioException) {
        if (err.type == DioExceptionType.connectionTimeout ||
            err.type == DioExceptionType.receiveTimeout ||
            err.type == DioExceptionType.sendTimeout ||
            err.type == DioExceptionType.connectionError) {
          return 'Inaonekana huna intaneti. Tafadhali angalia muunganisho wako kisha jaribu tena.';
        }
        final code = err.response?.statusCode ?? 0;
        switch (code) {
          case 400:
          case 422:
            return 'Ombi halijakamilika. Tafadhali kagua taarifa ulizoingiza na ujaribu tena.';
          case 401:
            return 'Kikao chako kimeisha. Tafadhali ingia tena.';
          case 403:
            return 'Huna ruhusa ya kufanya hatua hii.';
          case 404:
            return 'Hatukupata taarifa ulizoomba.';
          case 409:
            return 'Kuna mgongano wa maombi. Jaribu tena.';
          case 429:
            return 'Maombi mengi kwa sasa. Tafadhali jaribu tena baadaye.';
          default:
            if (code >= 500 && code <= 599) return 'Hitilafu ya mfumo. Tafadhali jaribu tena baadaye.';
        }
      }
    } catch (_) {}
    return 'Hitilafu imetokea. Tafadhali jaribu tena.';
  }

  Future<void> _onLoad(SavingsLoad e, Emitter<SavingsState> emit) async {
    emit(state.copyWith(loading: true, error: null));
    try {
      final list = await repo.listPots(e.userId);
      emit(state.copyWith(loading: false, accounts: list));
    } catch (err) {
      emit(state.copyWith(loading: false, error: _humanizeError(err)));
    }
  }

  Future<void> _onCreate(SavingsCreate e, Emitter<SavingsState> emit) async {
    emit(state.copyWith(creating: true, error: null));
    try {
      await repo.createPot(
        name: e.name,
        goalAmount: e.goalAmount,
        accountId: e.accountId,
        durationMonths: e.durationMonths,
        purpose: e.purpose,
        withdrawalCondition: e.withdrawalCondition,
      );
      final list = await repo.listPots(e.userId);
      emit(state.copyWith(creating: false, accounts: list));
    } catch (err) {
      emit(state.copyWith(creating: false, error: _humanizeError(err)));
    }
  }
}