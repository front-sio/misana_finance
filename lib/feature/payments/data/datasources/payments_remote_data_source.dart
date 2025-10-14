import 'dart:async';

import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

import '../../../../core/network/api_client.dart';

class PaymentsRemoteDataSource {
  final ApiClient api;

  PaymentsRemoteDataSource(this.api);

  Future<Map<String, dynamic>> createDeposit({
    required String accountId,
    required int amountTZS,
    String? potId,
  }) async {
    final payload = <String, dynamic>{
      'account_id': accountId,
      'amount': amountTZS,
      if (potId != null) 'pot_id': potId,
    };

    try {
      final res = await api.post<Map<String, dynamic>>(
        '/payments/deposit',
        data: payload,
        extra: const {'toastOnSuccess': true},
      );
      return _toMap(res.data);
    } on DioException {
      final res = await api.post<Map<String, dynamic>>(
        '/deposits',
        data: payload,
        extra: const {'toastOnSuccess': true},
      );
      return _toMap(res.data);
    }
  }

  // Note: accountId is optional in case your backend supports filtering by account later.
  // Your current backend filters by user_id (path param), so we always send userId in the URL.
  Future<Map<String, dynamic>> listTransactions({
    required String userId,
    String? accountId,
    required int page,
    required int pageSize,
    required String query,
    required String type,
    required String status,
    DateTime? from,
    DateTime? to,
  }) async {
    final df = DateFormat('yyyy-MM-dd');

    // We still build filters, but your current controller ignores them. Keeping them future-proof.
    final filters = <String, dynamic>{
      // offset-based fallbacks for services that use them
      'limit': pageSize,
      'offset': (page - 1) * pageSize,
      if (query.isNotEmpty) 'query': query,
      if (type != 'all') 'type': type,
      if (status != 'all') 'status': status,
      if (from != null) 'from': df.format(from),
      if (to != null) 'to': df.format(to),
      if (accountId != null && accountId.isNotEmpty) 'account_id': accountId,
    };

    dynamic result;

    // Primary path: GET /payments/transactions/:user_id (matches your controller)
    try {
      final res = await api.get<dynamic>(
        '/payments/transactions/$userId',
        params: filters, // harmless if backend ignores
        extra: const {'suppressToast': true},
      );
      result = res.data;
    } on DioException {
      // Fallbacks for other possible route shapes
      try {
        final res = await api.get<dynamic>(
          '/transactions/$userId',
          params: filters,
          extra: const {'suppressToast': true},
        );
        result = res.data;
      } on DioException {
        try {
          final res = await api.get<dynamic>(
            '/payments/transactions',
            params: {'user_id': userId, ...filters},
            extra: const {'suppressToast': true},
          );
          result = res.data;
        } on DioException {
          final res = await api.get<dynamic>(
            '/transactions',
            params: {'user_id': userId, ...filters},
            extra: const {'suppressToast': true},
          );
          result = res.data;
        }
      }
    }

    return _normalizeListResult(result, page, pageSize);
  }

  Future<Map<String, dynamic>> getTransaction(String id) async {
    try {
      final res = await api.get<Map<String, dynamic>>(
        '/payments/transactions/$id',
        extra: const {'suppressToast': true},
      );
      return _toMap(res.data);
    } on DioException {
      final res = await api.get<Map<String, dynamic>>(
        '/transactions/$id',
        extra: const {'suppressToast': true},
      );
      return _toMap(res.data);
    }
  }

  Map<String, dynamic> _toMap(dynamic v) {
    if (v is Map) return Map<String, dynamic>.from(v as Map);
    return <String, dynamic>{};
  }

  List<Map<String, dynamic>> _toListOfMaps(dynamic v) {
    if (v is List) {
      return v.where((e) => e is Map).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    return const <Map<String, dynamic>>[];
  }

  Map<String, dynamic> _normalizeListResult(dynamic result, int page, int pageSize) {
    // Your backend currently returns a plain List<tx>. Handle that and many other shapes too.
    if (result is List) {
      final items = _toListOfMaps(result);
      final hasMore = items.length >= pageSize; // naive; backend doesn’t paginate yet
      return {'items': items, 'page': page, 'has_more': hasMore};
    }

    if (result is Map) {
      final map = _toMap(result);

      List<Map<String, dynamic>> items = const [];
      if (map['items'] is List) {
        items = _toListOfMaps(map['items']);
      } else if (map['data'] is List) {
        items = _toListOfMaps(map['data']);
      } else if (map['transactions'] is List) {
        items = _toListOfMaps(map['transactions']);
      } else if (map['results'] is List) {
        items = _toListOfMaps(map['results']);
      } else if (map['payload'] is Map) {
        final p = _toMap(map['payload']);
        for (final k in ['items', 'data', 'transactions', 'results']) {
          if (p[k] is List) {
            items = _toListOfMaps(p[k]);
            break;
          }
        }
      }

      final total = (map['total'] as num?)?.toInt() ??
          (map['count'] as num?)?.toInt() ??
          (map['payload'] is Map ? (map['payload']['total'] as num?)?.toInt() : null);

      bool hasMore;
      if (total != null) {
        hasMore = (page * pageSize) < total;
      } else if (map['has_more'] is bool) {
        hasMore = map['has_more'] == true;
      } else if (map['next'] != null) {
        hasMore = true;
      } else {
        hasMore = items.length >= pageSize;
      }

      return {
        'items': items,
        'total': total,
        'page': map['page'] ?? page,
        'has_more': hasMore,
      };
    }

    return {'items': const <Map<String, dynamic>>[], 'page': page, 'has_more': false};
  }
}