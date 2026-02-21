import 'dart:async';

/// Adapter to transform low-level WebSocket events to unified Map payloads
/// compatible with KycBloc's KycWebSocketUpdate.
///
/// Expected incoming events & mapping:
///   kyc:processing -> { status: 'processing', ... }
///   kyc:approved   -> { status: 'verified', ... }
///   kyc:rejected   -> { status: 'rejected', reason/error }
///   kyc:error      -> { status: 'error', error: ... }
///
/// Use with an existing WebSocket service:
///   final bridge = KycWebSocketBridge(wsService);
///   kycBloc.bindWebSocketStream(bridge.stream);
class KycWebSocketBridge {
  final _controller = StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get stream => _controller.stream;

  /// Call these from your actual WebSocket callbacks.
  void onProcessing(Map<String, dynamic> raw) {
    _controller.add({'status': 'processing', ...raw});
  }

  void onApproved(Map<String, dynamic> raw) {
    _controller.add({'status': 'verified', ...raw});
  }

  void onRejected(Map<String, dynamic> raw) {
    final reason = raw['reason'] ?? raw['error'] ?? raw['rejection_reason'];
    _controller.add({'status': 'rejected', 'reason': reason, ...raw});
  }

  void onError(Map<String, dynamic> raw) {
    final error = raw['error'] ?? raw['message'];
    _controller.add({'status': 'error', 'error': error, ...raw});
  }

  void dispose() {
    _controller.close();
  }
}