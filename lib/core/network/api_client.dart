import 'dart:async';
import 'dart:math';
import 'dart:io' show Platform;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:misana_finance_app/core/ui/app_messanger.dart';

import '../navigation/nav.dart';
import '../storage/token_storage.dart';

class ApiClient {
  final String baseUrl;
  final Dio dio;
  final TokenStorage _storage;

  Future<String?>? _refreshing;
  late final Dio _authDio;

  static const int _maxTransientRetries = 2;
  static const Duration _baseBackoff = Duration(milliseconds: 300);

  ApiClient({
    required String baseUrl,
    TokenStorage? tokenStorage,
    Dio? client,
  })  : baseUrl = _normalizeBaseUrl(baseUrl),
        _storage = tokenStorage ?? TokenStorage(),
        dio = client ??
            Dio(
              BaseOptions(
                baseUrl: _normalizeBaseUrl(baseUrl),
                connectTimeout: const Duration(seconds: 10),
                receiveTimeout: const Duration(seconds: 15),
                sendTimeout: const Duration(seconds: 10),
                headers: {
                  'Content-Type': 'application/json',
                },
                responseType: ResponseType.json,
                followRedirects: true,
                receiveDataWhenStatusError: true,
              ),
            ) {
    _authDio = Dio(
      BaseOptions(
        baseUrl: this.baseUrl,
        connectTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 8),
        sendTimeout: const Duration(seconds: 8),
        headers: {
          'Content-Type': 'application/json',
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final skipAuth = options.extra['skipAuth'] == true;

          // Debug: log the final URL we’re about to hit
          if (kDebugMode) {
            // options.uri reflects baseUrl + path + query
            // ignore: avoid_print
            print('[HTTP] ${options.method} ${options.uri}');
          }

          if (!skipAuth) {
            final token = await _storage.getAccessToken();
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          handler.next(options);
        },
        onResponse: (response, handler) {
          final method = response.requestOptions.method.toUpperCase();
          final toastOnSuccess = response.requestOptions.extra['toastOnSuccess'] == true;
          final isMutating = method == 'POST' || method == 'PUT' || method == 'PATCH' || method == 'DELETE';

          if (!response.isRedirect &&
              response.statusCode != null &&
              response.statusCode! >= 200 &&
              response.statusCode! < 300) {
            final msg = _extractServerMessage(response);
            final suppressed = response.requestOptions.extra['suppressToast'] == true;
            if (!suppressed && msg != null && msg.isNotEmpty && (isMutating || toastOnSuccess)) {
              AppMessenger.success(msg);
            }
          }

          handler.next(response);
        },
        onError: (error, handler) async {
          if (CancelToken.isCancel(error)) {
            return handler.next(error);
          }

          final status = error.response?.statusCode ?? 0;
          final req = error.requestOptions;

          // Helpful 404 hint (commonly caused by empty IDs or wrong base URL)
          if (status == 404 && kDebugMode) {
            // ignore: avoid_print
            print(
              '[HTTP 404] ${req.method} ${req.uri}\n'
              'Check: userId/params present? baseUrl correct for device/emulator?',
            );
          }

          final path = req.path;
          final isLogin = path == '/auth/login';
          final isRefresh = path == '/auth/refresh';
          final skipRefresh = req.extra['skipRefresh'] == true;

          if (status == 401 && !isLogin && !isRefresh && !skipRefresh) {
            final retried = req.extra['_retried'] == true;

            try {
              final newToken = await _refreshAccessToken();
              if (newToken != null && newToken.isNotEmpty && !retried) {
                final Options opts = Options(
                  method: req.method,
                  headers: Map<String, dynamic>.from(req.headers)..['Authorization'] = 'Bearer $newToken',
                  responseType: req.responseType,
                  contentType: req.contentType,
                  followRedirects: req.followRedirects,
                  receiveDataWhenStatusError: req.receiveDataWhenStatusError,
                  validateStatus: req.validateStatus,
                );

                final newExtra = Map<String, dynamic>.from(req.extra)..['_retried'] = true;

                final response = await dio.request<dynamic>(
                  req.path,
                  data: req.data,
                  queryParameters: req.queryParameters,
                  options: opts.copyWith(extra: newExtra),
                  cancelToken: req.cancelToken,
                  onSendProgress: req.onSendProgress,
                  onReceiveProgress: req.onReceiveProgress,
                );

                return handler.resolve(response);
              }
            } catch (_) {
              // continue to logout
            }

            await _logoutToLogin();
            if (req.extra['suppressToast'] != true) {
              AppMessenger.warn('Session expired. Please log in again.');
            }
            return handler.next(error);
          }

          if (_shouldRetry(req, error)) {
            final attempt = (req.extra['retry_count'] as int?) ?? 0;
            if (attempt < _maxTransientRetries) {
              final delay = _backoffDelay(attempt);
              await Future<void>.delayed(delay);

              final newExtra = Map<String, dynamic>.from(req.extra);
              newExtra['retry_count'] = attempt + 1;

              try {
                final response = await dio.request<dynamic>(
                  req.path,
                  data: req.data,
                  queryParameters: req.queryParameters,
                  options: Options(
                    method: req.method,
                    headers: req.headers,
                    responseType: req.responseType,
                    contentType: req.contentType,
                    followRedirects: req.followRedirects,
                    receiveDataWhenStatusError: req.receiveDataWhenStatusError,
                    validateStatus: req.validateStatus,
                    extra: newExtra,
                  ),
                  cancelToken: req.cancelToken,
                  onSendProgress: req.onSendProgress,
                  onReceiveProgress: req.onReceiveProgress,
                );

                return handler.resolve(response);
              } catch (_) {
                // fallthrough
              }
            }
          }

          if (req.extra['suppressToast'] != true) {
            final msg = _humanizeDioError(error, includeUrl: kDebugMode ? req.uri.toString() : null);
            if (msg != null && msg.isNotEmpty) {
              final isNetwork = error.type == DioExceptionType.connectionError ||
                  error.type == DioExceptionType.connectionTimeout ||
                  error.type == DioExceptionType.receiveTimeout ||
                  error.type == DioExceptionType.sendTimeout;
              if (isNetwork) {
                AppMessenger.warn(msg);
              } else if (status >= 500) {
                AppMessenger.error(msg);
              } else {
                AppMessenger.info(msg);
              }
            }
          }

          handler.next(error);
        },
      ),
    );
  }

  // Convenience methods
  Future<Response<T>> post<T>(
    String path, {
    Map<String, dynamic>? data,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) {
    return dio.post<T>(
      path,
      data: data,
      options: Options(headers: headers, extra: extra),
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? params,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) {
    return dio.get<T>(
      path,
      queryParameters: params,
      options: Options(headers: headers, extra: extra),
      cancelToken: cancelToken,
      onReceiveProgress: onReceiveProgress,
    );
  }

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    CancelToken? cancelToken,
  }) {
    return dio.put<T>(
      path,
      data: data,
      options: Options(headers: headers, extra: extra),
      cancelToken: cancelToken,
    );
  }

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? params,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    CancelToken? cancelToken,
  }) {
    return dio.delete<T>(
      path,
      data: data,
      queryParameters: params,
      options: Options(headers: headers, extra: extra),
      cancelToken: cancelToken,
    );
  }

  // Shared refresh future
  Future<String?> _refreshAccessToken() async {
    if (_refreshing != null) return await _refreshing!;

    final completer = Completer<String?>();
    _refreshing = completer.future;

    try {
      final refresh = await _storage.getRefreshToken();
      if (refresh == null || refresh.isEmpty) {
        completer.complete(null);
        return await completer.future;
      }

      final res = await _authDio
          .post<Map<String, dynamic>>(
            '/auth/refresh',
            data: {'refresh_token': refresh},
            options: Options(
              headers: {
                'Authorization': null,
                'Content-Type': 'application/json',
              },
              extra: const {
                'skipAuth': true,
                'skipRefresh': true,
              },
            ),
          )
          .timeout(const Duration(seconds: 8));

      final data = res.data ?? {};
      final newAccess = data['access_token'] as String?;
      if (newAccess != null && newAccess.isNotEmpty) {
        await _storage.setAccessToken(newAccess);
        completer.complete(newAccess);
      } else {
        completer.complete(null);
      }
    } on TimeoutException {
      completer.complete(null);
    } catch (_) {
      completer.complete(null);
    } finally {
      _refreshing = null;
    }

    return await completer.future;
  }

  Future<void> _logoutToLogin() async {
    await _storage.clear();
    final nav = appNavigatorKey.currentState;
    if (nav != null) {
      nav.pushNamedAndRemoveUntil('/login', (_) => false);
    }
  }

  bool _shouldRetry(RequestOptions req, DioException err) {
    if (req.method.toUpperCase() != 'GET') return false;
    final status = err.response?.statusCode ?? 0;

    final isNetwork = err.type == DioExceptionType.connectionError ||
        err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.sendTimeout;

    final isServerTransient = status == 502 || status == 503 || status == 504;

    return isNetwork || isServerTransient;
  }

  Duration _backoffDelay(int attempt) {
    final int baseMs = _baseBackoff.inMilliseconds; // 300
    final int factor = 1 << attempt; // 1, 2, 4
    final int ms = baseMs * factor;
    final int jitter = Random().nextInt(120); // 0-119ms
    return Duration(milliseconds: ms + jitter);
  }

  // ----- Helpers -----

  static String _normalizeBaseUrl(String url) {
    var u = url.trim();
    if (u.endsWith('/')) u = u.substring(0, u.length - 1);

    // If someone accidentally ships localhost in a device build, at least try to make it work on emulators.
    if (u.contains('localhost')) {
      if (!kIsWeb && Platform.isAndroid) {
        // Android emulator's host loopback
        u = u.replaceFirst('localhost', '10.0.2.2');
      } else if (!kIsWeb && Platform.isIOS) {
        // iOS simulator supports localhost; leave as-is
      }
    }
    return u;
  }

  String? _extractServerMessage(Response<dynamic>? res) {
    if (res == null) return null;
    final xMsg = res.headers.map['x-message'];
    if (xMsg != null && xMsg.isNotEmpty && (xMsg.first ?? '').toString().trim().isNotEmpty) {
      return xMsg.first!.toString();
    }

    final data = res.data;
    if (data is Map) {
      final candidates = [
        data['message'],
        data['msg'],
        data['detail'],
        (data['error'] is Map ? data['error']['message'] : data['error']),
      ];
      for (final c in candidates) {
        final s = c?.toString().trim();
        if (s != null && s.isNotEmpty) return s;
      }
    }
    return null;
  }

  String? _humanizeDioError(DioException e, {String? includeUrl}) {
    final serverMsg = _extractServerMessage(e.response);
    if (serverMsg != null && serverMsg.isNotEmpty) {
      return includeUrl != null ? '$serverMsg\nURL: $includeUrl' : serverMsg;
    }

    String withUrl(String msg) => includeUrl != null ? '$msg\nURL: $includeUrl' : msg;

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return withUrl('Network timeout. Please check your connection.');
      case DioExceptionType.connectionError:
        return withUrl('Unable to connect. Please check your internet connection.');
      case DioExceptionType.badResponse:
        final code = e.response?.statusCode ?? 0;
        if (code >= 500) return withUrl('Server is temporarily unavailable. Please try again.');
        if (code == 400) return withUrl('Invalid request. Please review your input.');
        if (code == 403) return withUrl('You don’t have permission to perform this action.');
        if (code == 404) return withUrl('Requested resource was not found.');
        if (code == 409) return withUrl('Conflict detected. Please try again.');
        if (code == 422) return withUrl('Validation error. Please check the fields and try again.');
        return withUrl('Request failed (HTTP $code). Please try again.');
      case DioExceptionType.cancel:
        return null; // silent
      case DioExceptionType.unknown:
      default:
        return withUrl('Something went wrong. Please try again.');
    }
  }
}