import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/kyc_repository.dart';
import 'kyc_event.dart';
import 'kyc_state.dart';

class KycBloc extends Bloc<KycEvent, KycState> {
  final KycRepository repo;

  KycBloc(this.repo) : super(const KycState()) {
    on<KycLoadStatus>(_onLoad);
    on<KycSubmit>(_onSubmit);
  }

  String _normalize(String? raw, {bool? isVerifiedFlag}) {
    final s = (raw ?? 'unknown').toString().toLowerCase().trim();
    if (isVerifiedFlag == true) return 'verified';
    if (s == 'verified' || s == 'approved' || s == 'success' || s == 'ok') return 'verified';
    if (s == 'pending' || s == 'in_review' || s == 'processing') return 'pending';
    if (s == 'rejected' || s == 'failed' || s == 'error') return 'rejected';
    return 'unknown';
  }

  Future<void> _onLoad(KycLoadStatus e, Emitter<KycState> emit) async {
    emit(state.copyWith(loading: true, error: null));
    try {
      final history = await repo.getStatusByUser(e.userId);
      final latestRaw = history.isEmpty ? 'unknown' : (history.first['status']?.toString() ?? 'unknown');

      bool isVerifiedFlag = false;
      try {
        final verify = await repo.checkVerifiedByUser(e.userId);
        final dynamic boolVal = verify['is_verified'];
        if (boolVal is bool) isVerifiedFlag = boolVal;
        if (boolVal is String) {
          final s = boolVal.toLowerCase();
          isVerifiedFlag = (s == 'true' || s == '1' || s == 'yes');
        }
      } catch (_) {}

      final normalized = _normalize(latestRaw, isVerifiedFlag: isVerifiedFlag);
      emit(state.copyWith(loading: false, history: history, status: normalized));
    } catch (err) {
      emit(state.copyWith(loading: false, error: err.toString(), status: 'unknown'));
    }
  }

  Future<void> _onSubmit(KycSubmit e, Emitter<KycState> emit) async {
    emit(state.copyWith(submitting: true, error: null));
    try {
      final res = await repo.submitByUser(
        userId: e.userId,
        documentType: e.documentType,
        documentNumber: e.documentNumber,
        fullName: e.fullName,
        dateOfBirth: e.dateOfBirth,
        address: e.address,
        documentImageBase64: e.documentImageBase64,
      );

      bool isVerifiedFlag = false;
      try {
        final verify = await repo.checkVerifiedByUser(e.userId);
        final dynamic boolVal = verify['is_verified'];
        if (boolVal is bool) isVerifiedFlag = boolVal;
        if (boolVal is String) {
          final s = boolVal.toLowerCase();
          isVerifiedFlag = (s == 'true' || s == '1' || s == 'yes');
        }
      } catch (_) {}

      final statusRaw = res['status']?.toString();
      final normalized = _normalize(statusRaw, isVerifiedFlag: isVerifiedFlag);
      final history = await repo.getStatusByUser(e.userId);

      emit(state.copyWith(submitting: false, status: normalized, history: history));
    } catch (err) {
      emit(state.copyWith(submitting: false, error: err.toString()));
    }
  }
}