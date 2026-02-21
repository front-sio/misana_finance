import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/kyc_repository.dart';
import 'kyc_event.dart';
import 'kyc_state.dart';

/// Bloc controlling KYC submission flow, status polling and WebSocket updates.
class KycBloc extends Bloc<KycEvent, KycState> {
  final KycRepository repo;
  Timer? _pollingTimer;
  StreamSubscription<Map<String, dynamic>>? _wsSub;

  // Base polling interval & backoff settings.
  static const Duration _basePolling = Duration(seconds: 3);
  static const int _maxBackoffSteps = 5;

  int _backoffStep = 0;

  KycBloc(this.repo) : super(const KycState()) {
    on<KycLoadStatus>(_onLoad);
    on<KycSubmit>(_onSubmit);
    on<KycCheckVerificationStatus>(_onCheckStatus);
    on<KycStartPolling>(_onStartPolling);
    on<KycStopPolling>(_onStopPolling);
    on<KycWebSocketUpdate>(_onWebSocketUpdate);
  }

  @override
  Future<void> close() {
    _pollingTimer?.cancel();
    _wsSub?.cancel();
    return super.close();
  }

  String _normalize(String? raw, {bool? isVerifiedFlag}) {
    final s = (raw ?? 'unknown').toLowerCase().trim();
    if (isVerifiedFlag == true) return 'verified';
    switch (s) {
      case 'approved':
      case 'verified':
      case 'success':
        return 'verified';
      case 'pending':
      case 'in_review':
        return 'pending';
      case 'processing':
        return 'processing';
      case 'rejected':
      case 'failed':
      case 'error':
        return 'rejected';
      default:
        return 'unknown';
    }
  }

  Future<void> _onLoad(KycLoadStatus e, Emitter<KycState> emit) async {
    emit(state.copyWith(loading: true, error: null));
    try {
      bool verifiedFlag = false;
      String fallbackStatus = 'unknown';
      try {
        final verify = await repo.checkVerifiedByUser(e.userId);
        final dynamic isVerifiedValue = verify['is_verified'];
        if (isVerifiedValue is bool) {
          verifiedFlag = isVerifiedValue;
        } else if (isVerifiedValue is String) {
          verifiedFlag = ['true', '1', 'yes'].contains(isVerifiedValue.toLowerCase());
        }
        final verStatus = verify['status']?.toString();
        if (verStatus != null && verStatus.isNotEmpty) {
          fallbackStatus = verStatus;
        }
      } catch (_) {}

      final history = await repo.getStatusByUser(e.userId);
      final latestRaw =
          history.isEmpty ? fallbackStatus : (history.first['status']?.toString() ?? fallbackStatus);

      final normalized = _normalize(latestRaw, isVerifiedFlag: verifiedFlag);
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
        nidaNumber: e.nidaNumber,
        fullName: e.fullName,
        dateOfBirth: e.dateOfBirth,
        placeOfBirth: e.placeOfBirth,
        address: e.address,
        documentImageBase64: e.documentImageBase64,
        filePath: e.filePath,
      );

      final statusRaw = res['status']?.toString();
      final normalized = _normalize(statusRaw);

      final history = await repo.getStatusByUser(e.userId);

      emit(state.copyWith(
        submitting: false,
        status: normalized,
        history: history,
        showSubmittedNotification: true,
      ));

      // Auto start polling if likely to transition (pending/processing) or user provided NIDA.
      final shouldPoll = normalized == 'pending' ||
          normalized == 'processing' ||
          (e.nidaNumber != null && e.nidaNumber!.isNotEmpty);
      if (shouldPoll) {
        add(KycStartPolling(userId: e.userId));
      }
    } catch (err) {
      emit(state.copyWith(submitting: false, error: err.toString()));
    }
  }

  Future<void> _onCheckStatus(KycCheckVerificationStatus e, Emitter<KycState> emit) async {
    try {
      final statusData = await repo.getVerificationStatus(e.userId);
      final raw = statusData['status']?.toString() ?? 'unknown';
      final normalized = _normalize(raw,
          isVerifiedFlag: statusData['verified'] == true ||
              statusData['is_verified'] == true);

      String? rejectionReason;
      if (normalized == 'rejected') {
        rejectionReason = statusData['reason']?.toString() ??
            statusData['error']?.toString() ??
            statusData['rejection_reason']?.toString();
      }

      final previousStatus = state.status;
      final changed = previousStatus != normalized;

      emit(state.copyWith(
        status: normalized,
        verificationData: statusData,
        rejectionReason: rejectionReason,
        showApprovedNotification: changed && normalized == 'verified',
        showRejectedNotification: changed && normalized == 'rejected',
      ));

      if (normalized == 'verified' || normalized == 'rejected') {
        add(const KycStopPolling());
      } else {
        // Increase backoff gradually for long-running processing
        if (normalized == 'processing' || normalized == 'pending') {
          _incrementBackoff();
        }
      }
    } catch (err) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('Verification status check error: $err');
      }
      _incrementBackoff();
    }
  }

  Future<void> _onStartPolling(KycStartPolling e, Emitter<KycState> emit) async {
    _pollingTimer?.cancel();
    _backoffStep = 0;
    emit(state.copyWith(polling: true));

    // Initial tick immediately
    add(KycCheckVerificationStatus(userId: e.userId));

    _pollingTimer = Timer.periodic(_currentInterval(e.interval), (timer) {
      if (!isClosed) {
        add(KycCheckVerificationStatus(userId: e.userId));
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _onStopPolling(KycStopPolling e, Emitter<KycState> emit) async {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _wsSub?.cancel();
    _wsSub = null;
    emit(state.copyWith(polling: false));
  }

  Future<void> _onWebSocketUpdate(KycWebSocketUpdate e, Emitter<KycState> emit) async {
    final status = e.data['status']?.toString() ?? 'unknown';
    final normalized = _normalize(status,
        isVerifiedFlag: e.data['verified'] == true || e.data['is_verified'] == true);

    String? rejectionReason;
    if (normalized == 'rejected') {
      rejectionReason = e.data['reason']?.toString() ??
          e.data['error']?.toString() ??
          e.data['rejection_reason']?.toString();
    }

    final previousStatus = state.status;
    final changed = previousStatus != normalized;

    emit(state.copyWith(
      status: normalized,
      verificationData: e.data,
      rejectionReason: rejectionReason,
      showApprovedNotification: changed && normalized == 'verified',
      showRejectedNotification: changed && normalized == 'rejected',
    ));

    if (normalized == 'verified' || normalized == 'rejected') {
      add(const KycStopPolling());
    }
  }

  /// Attach a WebSocket (Stream<Map>) subscription for KYC events.
  /// Provide a stream that yields raw event payloads having 'status' field.
  void bindWebSocketStream(Stream<Map<String, dynamic>> stream) {
    _wsSub?.cancel();
    _wsSub = stream.listen((event) {
      add(KycWebSocketUpdate(event));
    });
  }

  Duration _currentInterval(Duration? override) {
    if (override != null) return override;
    if (_backoffStep == 0) return _basePolling;
    final ms = _basePolling.inMilliseconds * (1 << (_backoffStep - 1));
    final capped = ms > 20000 ? 20000 : ms; // cap at 20s
    return Duration(milliseconds: capped);
  }

  void _incrementBackoff() {
    if (_pollingTimer == null) return;
    if (_backoffStep >= _maxBackoffSteps) return;
    _backoffStep++;

    // Restart timer with new interval.
    final userId = _extractCurrentUserId();
    if (userId == null) return;

    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(_currentInterval(null), (timer) {
      if (!isClosed) {
        add(KycCheckVerificationStatus(userId: userId));
      } else {
        timer.cancel();
      }
    });
  }

  /// Attempts to infer userId from latest history or verification data.
  String? _extractCurrentUserId() {
    if (state.verificationData != null) {
      final v = state.verificationData!['userId'] ?? state.verificationData!['user_id'];
      if (v is String && v.isNotEmpty) return v;
    }
    if (state.history.isNotEmpty) {
      final v = state.history.first['user_id'] ?? state.history.first['userId'];
      if (v is String && v.isNotEmpty) return v;
    }
    return null;
  }
}