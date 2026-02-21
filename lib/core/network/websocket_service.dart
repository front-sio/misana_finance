import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../storage/token_storage.dart';

/// Socket.IO WebSocket client tailored for the KYC service.
/// - Connects via API Gateway base URL using the Socket.IO path `/kyc/socket.io`
/// - Authenticates using JWT sent in `auth.token` (required by the server)
/// - Auto-joins user room on the server (based on JWT payload)
/// - Listens to KYC events: `kyc:processing`, `kyc:approved`, `kyc:rejected`, `kyc:error`
/// - Optional channels: `subscribe([...])` / `unsubscribe([...])`
///
/// Usage:
///   final ws = WebSocketService(baseUrl: Env.apiBaseUrl);
///   await ws.connect();
///   ws.verificationStream.listen(...);
class WebSocketService {
  final String baseUrl; // e.g., http://10.0.2.2:8081
  final String socketPath; // default: /kyc/socket.io
  final TokenStorage _storage;

  io.Socket? _socket;
  bool _isConnected = false;

  final _verificationController = StreamController<Map<String, dynamic>>.broadcast();
  final _accountStatusController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get verificationStream => _verificationController.stream;
  Stream<Map<String, dynamic>> get accountStatusStream => _accountStatusController.stream;
  bool get isConnected => _isConnected;

  WebSocketService({
    required this.baseUrl,
    this.socketPath = '/kyc/socket.io',
    TokenStorage? tokenStorage,
  }) : _storage = tokenStorage ?? TokenStorage();

  /// Connect to Socket.IO server (idempotent).
  Future<void> connect() async {
    if (_socket != null && _isConnected) return;

    try {
      final token = await _storage.getAccessToken();
      if (token == null || token.isEmpty) {
        if (kDebugMode) print('[WebSocket] No token found, skipping connection');
        return;
      }

      final httpUrl = _normalizeHttpBaseUrl(baseUrl);
      final options = io.OptionBuilder()
          .setTransports(['websocket']) // force WebSocket
          .setPath(_normalizeSocketPath(socketPath))
          .setAuth({'token': token}) // server expects token in auth
          .enableAutoConnect()
          .enableReconnection()
          .setReconnectionAttempts(10) // Reduced attempts
          .setReconnectionDelay(2000) // Increased delay
          .setTimeout(10000) // 10 second timeout
          .build();

      _socket = io.io(httpUrl, options);

      // Connection lifecycle
      _socket!.onConnect((_) {
        _isConnected = true;
        if (kDebugMode) print('[WebSocket] Connected to $httpUrl$socketPath');
      });

      _socket!.onReconnect((attempt) {
        if (kDebugMode) print('[WebSocket] Reconnected (attempt: $attempt)');
      });

      _socket!.onReconnectAttempt((attempt) {
        if (kDebugMode) print('[WebSocket] Reconnect attempt #$attempt');
      });

      _socket!.onReconnectError((err) {
        if (kDebugMode) print('[WebSocket] Reconnect error: $err');
      });

      _socket!.onReconnectFailed((_) {
        if (kDebugMode) print('[WebSocket] Reconnect failed');
      });

      _socket!.onConnectError((data) {
        if (kDebugMode) print('[WebSocket] Connection error: $data');
      });

      _socket!.onError((data) {
        if (kDebugMode) print('[WebSocket] Error: $data');
      });

      _socket!.onDisconnect((data) {
        _isConnected = false;
        if (kDebugMode) print('[WebSocket] Disconnected: $data');
      });

      // Server welcome
      _socket!.on('connected', (data) {
        if (kDebugMode) print('[WebSocket] Server acknowledged connection: $data');
      });

      // KYC events (pushed by server)
      _socket!.on('kyc:processing', (data) {
        final payload = _safeMap(data);
        if (payload != null) {
          if (kDebugMode) print('[WebSocket] KYC processing: $payload');
          _verificationController.add({'status': 'processing', ...payload});
        }
      });

      _socket!.on('kyc:approved', (data) {
        final payload = _safeMap(data);
        if (payload != null) {
          if (kDebugMode) print('[WebSocket] KYC approved: $payload');
          _verificationController.add({'status': 'verified', ...payload});
        }
      });

      _socket!.on('kyc:rejected', (data) {
        final payload = _safeMap(data);
        if (payload != null) {
          if (kDebugMode) print('[WebSocket] KYC rejected: $payload');
          _verificationController.add({'status': 'rejected', ...payload});
        }
      });

      _socket!.on('kyc:error', (data) {
        final payload = _safeMap(data);
        if (payload != null) {
          if (kDebugMode) print('[WebSocket] KYC error: $payload');
          _verificationController.add({'status': 'error', ...payload});
        }
      });

      // Optional account events if your backend emits them
      _socket!.on('account:status', (data) {
        final payload = _safeMap(data);
        if (payload != null) {
          if (kDebugMode) print('[WebSocket] Account status: $payload');
          _accountStatusController.add(payload);
        }
      });
    } catch (e) {
      if (kDebugMode) print('[WebSocket] Failed to connect: $e');
      _isConnected = false;
    }
  }

  /// Manually subscribe to additional channels (server supports a generic "subscribe" API).
  /// Example: subscribe(['account:updates', 'kyc:room'])
  void subscribe(List<String> channels) {
    if (_socket != null && _isConnected && channels.isNotEmpty) {
      _socket!.emit('subscribe', channels);
      if (kDebugMode) print('[WebSocket] Subscribed to: $channels');
    }
  }

  /// Unsubscribe from additional channels.
  void unsubscribe(List<String> channels) {
    if (_socket != null && _isConnected && channels.isNotEmpty) {
      _socket!.emit('unsubscribe', channels);
      if (kDebugMode) print('[WebSocket] Unsubscribed from: $channels');
    }
  }

  void disconnect() {
    try {
      _socket?.disconnect();
      _socket?.dispose();
    } catch (_) {}
    _socket = null;
    _isConnected = false;
  }

  void dispose() {
    disconnect();
    _verificationController.close();
    _accountStatusController.close();
  }

  // Socket.IO expects HTTP(S) base URL, not WS(S)
  String _normalizeHttpBaseUrl(String url) {
    var u = url.trim();
    if (u.endsWith('/')) u = u.substring(0, u.length - 1);

    // For Android emulator, redirect localhost to 10.0.2.2
    if (!kIsWeb && Platform.isAndroid && u.contains('localhost')) {
      u = u.replaceFirst('localhost', '10.0.2.2');
    }
    return u;
  }

  String _normalizeSocketPath(String path) {
    if (path.isEmpty) return '/socket.io';
    return path.startsWith('/') ? path : '/$path';
  }

  Map<String, dynamic>? _safeMap(dynamic data) {
    if (data is Map) {
      return Map<String, dynamic>.from(data as Map);
    }
    return null;
  }
}
