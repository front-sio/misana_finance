import 'package:equatable/equatable.dart';

class KycState extends Equatable {
  final bool loading;
  final bool submitting;
  final bool polling;
  final String status; // verified | pending | processing | rejected | error | unknown
  final List<Map<String, dynamic>> history;
  final Map<String, dynamic>? verificationData;
  final String? rejectionReason;
  final bool showSubmittedNotification;
  final bool showApprovedNotification;
  final bool showRejectedNotification;
  final String? error;

  const KycState({
    this.loading = false,
    this.submitting = false,
    this.polling = false,
    this.status = 'unknown',
    this.history = const [],
    this.verificationData,
    this.rejectionReason,
    this.showSubmittedNotification = false,
    this.showApprovedNotification = false,
    this.showRejectedNotification = false,
    this.error,
  });

  KycState copyWith({
    bool? loading,
    bool? submitting,
    bool? polling,
    String? status,
    List<Map<String, dynamic>>? history,
    Map<String, dynamic>? verificationData,
    String? rejectionReason,
    bool? showSubmittedNotification,
    bool? showApprovedNotification,
    bool? showRejectedNotification,
    String? error,
  }) {
    return KycState(
      loading: loading ?? this.loading,
      submitting: submitting ?? this.submitting,
      polling: polling ?? this.polling,
      status: status ?? this.status,
      history: history ?? this.history,
      verificationData: verificationData ?? this.verificationData,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      showSubmittedNotification:
          showSubmittedNotification ?? this.showSubmittedNotification,
      showApprovedNotification:
          showApprovedNotification ?? this.showApprovedNotification,
      showRejectedNotification:
          showRejectedNotification ?? this.showRejectedNotification,
      error: error,
    );
  }

  // Computed getters used across the app (fixes undefined_getter diagnostics)
  bool get isVerified => status == 'verified' || status == 'approved';
  bool get isPending => status == 'pending' || status == 'in_review';
  bool get isProcessing => status == 'processing';
  bool get isRejected => status == 'rejected' || status == 'failed' || status == 'error';
  bool get isUnknown => status == 'unknown';

  @override
  List<Object?> get props => [
        loading,
        submitting,
        polling,
        status,
        history,
        verificationData,
        rejectionReason,
        showSubmittedNotification,
        showApprovedNotification,
        showRejectedNotification,
        error,
      ];
}