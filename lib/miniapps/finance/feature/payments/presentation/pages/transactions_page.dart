import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import 'package:misana_finance_app/miniapps/finance/feature/payments/domain/payments_repository.dart';
import 'package:misana_finance_app/auth/session/auth_cubit.dart';
import 'package:misana_finance_app/miniapps/finance/feature/account/domain/account_repository.dart';
import 'package:misana_finance_app/core/i18n/locale_cubit.dart';

class TransactionsPage extends StatefulWidget {
  final PaymentsRepository repo;

  const TransactionsPage({super.key, required this.repo});

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  final _scrollCtrl = ScrollController();
  final List<Map<String, dynamic>> _items = [];
  bool _initialLoading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  int _page = 1;
  final int _pageSize = 20;
  String? _error;

  final _searchCtrl = TextEditingController();
  String _query = '';
  String _type = 'all';
  String _status = 'all';
  DateTimeRange? _range;

  String? _accountId; // resolved once and reused

  String _t(String key, {bool isSwahili = false}) {
    final translations = {
      'title': isSwahili ? 'Miamala' : 'Transactions',
      'pick_date': isSwahili ? 'Chagua tarehe' : 'Pick date',
      'clear_date': isSwahili ? 'Futa tarehe' : 'Clear date',
      'search_hint': isSwahili ? 'Tafuta kwa jina/rujusa...' : 'Search by name/ref...',
      'all': isSwahili ? 'Zote' : 'All',
      'deposit': isSwahili ? 'Lipa' : 'Pay',
      'withdrawal': isSwahili ? 'Kutoa' : 'Withdrawal',
      'transfer': isSwahili ? 'Uhamisho' : 'Transfer',
      'status_all': isSwahili ? 'Hali: Zote' : 'Status: All',
      'success': isSwahili ? 'Imefanikiwa' : 'Success',
      'pending': isSwahili ? 'Inasubiri' : 'Pending',
      'failed': isSwahili ? 'Imeshindikana' : 'Failed',
      'reversed': isSwahili ? 'Imerejeshwa' : 'Reversed',
      'final_status': isSwahili ? 'Hali ya Mwisho' : 'Final Status',
      'provider_status': isSwahili ? 'Hali ya Mtoa Huduma' : 'Provider Status',
      'retry': isSwahili ? 'Jaribu tena' : 'Retry',
      'no_transactions': isSwahili ? 'Hakuna miamala ya kuonyesha.' : 'No transactions to show.',
      'error_network': isSwahili ? 'Tatizo la mtandao. Tafadhali angalia muunganisho wako.' : 'Network error. Please check your connection.',
      'error_server': isSwahili ? 'Hitilafu ya seva. Jaribu tena baadaye.' : 'Server error. Try again later.',
      'error_auth': isSwahili ? 'Muda wa kikao umeisha. Ingia tena.' : 'Session expired. Login again.',
      'error_permission': isSwahili ? 'Huna ruhusa ya kutazama hapa.' : 'Permission denied.',
      'error_not_found': isSwahili ? 'Hakuna rekodi zilizopatikana.' : 'No records found.',
      'error_invalid': isSwahili ? 'Kigezo cha utafutaji si sahihi.' : 'Invalid search criteria.',
      'error_unknown': isSwahili ? 'Hitilafu imetokea. Jaribu tena.' : 'An error occurred. Try again.',
      'apply': isSwahili ? 'Tumia' : 'Apply',
      'details_amount': isSwahili ? 'Maelezo ya Kiasi' : 'Amount Details',
      'total_amount': isSwahili ? 'Kiasi cha Jumla' : 'Total Amount',
      'fee': isSwahili ? 'Ada ya Muamala' : 'Transaction Fee',
      'net_amount': isSwahili ? 'Kiasi Halisi' : 'Net Amount',
      'details_tx': isSwahili ? 'Maelezo ya Muamala' : 'Transaction Details',
      'type': isSwahili ? 'Aina ya Muamala' : 'Transaction Type',
      'status': isSwahili ? 'Hali' : 'Status',
      'date': isSwahili ? 'Tarehe na Wakati' : 'Date & Time',
      'pot': isSwahili ? 'Mpango/Pochi' : 'Plan/Pot',
      'provider': isSwahili ? 'Mtoa Huduma' : 'Provider',
      'ref': isSwahili ? 'Namba ya Kumbukumbu' : 'Reference Number',
      'provider_ref': isSwahili ? 'Rujusa ya Mtoa' : 'Provider Ref',
      'tx_id': isSwahili ? 'Kitambulisho cha Muamala' : 'Transaction ID',
      'share_receipt': isSwahili ? 'Shiriki Risiti' : 'Share Receipt',
      'close': isSwahili ? 'Funga' : 'Close',
      'copied': isSwahili ? 'Risiti imenakiliwa kwenye clipboard' : 'Receipt copied to clipboard',
      'receipt_title': isSwahili ? 'Risiti ya Muamala' : 'Transaction Receipt',
    };
    return translations[key] ?? key;
  }

  @override
  void initState() {
    super.initState();
    _initAndLoad();
    _scrollCtrl.addListener(_onScroll);
    _searchCtrl.addListener(() {
      final q = _searchCtrl.text.trim();
      if (q != _query) {
        setState(() => _query = q);
        _reload();
      }
    });
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _initAndLoad() async {
    try {
      _accountId = await _resolveAccountId();
    } catch (_) {}
    await _loadInitial();
  }

  Future<String?> _resolveAccountId() async {
    final auth = context.read<AuthCubit>();
    final accountRepo = RepositoryProvider.of<AccountRepository>(context);

    try {
      await auth.refreshProfile();
    } catch (_) {}

    final userId = (auth.state.user?['id'] ?? '').toString();
    if (userId.isEmpty) return null;

    try {
      final acc = await accountRepo.getByUser(userId);

      if (acc is Map) {
        final m = Map<String, dynamic>.from(acc!);
        final id = (m['id'] ?? m['account_id'] ?? '').toString().trim();
        if (id.isNotEmpty) return id;
        for (final k in ['data', 'account']) {
          final n = m[k];
          if (n is Map) {
            final id2 = Map<String, dynamic>.from(n)['id']?.toString().trim() ?? '';
            if (id2.isNotEmpty) return id2;
          }
        }
      } else {
        final list = (acc as List?)?.whereType<Map>().toList() ?? const <Map>[];
        if (list.isNotEmpty) {
          final first = Map<String, dynamic>.from(list.first);
          final id = (first['id'] ?? '').toString().trim();
          if (id.isNotEmpty) return id;
        }
      }
    } catch (_) {}

    return null;
  }

  void _onScroll() {
    if (_loadingMore || !_hasMore || _initialLoading) return;
    if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 240) {
      _loadMore();
    }
  }

  Future<void> _reload() async {
    setState(() {
      _initialLoading = true;
      _loadingMore = false;
      _hasMore = true;
      _page = 1;
      _items.clear();
      _error = null;
    });
    await _loadInitial();
  }

  Future<void> _loadInitial() async {
    try {
      final pageData = await _fetchPage(page: 1);
      if (!mounted) return;
      setState(() {
        _items.addAll(pageData.items);
        _hasMore = pageData.hasMore;
        _page = 2;
        _initialLoading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _humanizeError(e);
        _initialLoading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    try {
      final pageData = await _fetchPage(page: _page);
      if (!mounted) return;
      setState(() {
        _items.addAll(pageData.items);
        _hasMore = pageData.hasMore;
        _page += 1;
        _loadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingMore = false;
        _hasMore = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_humanizeError(e))));
    }
  }

  Future<_PageResult> _fetchPage({required int page}) async {
    final userId = (context.read<AuthCubit>().state.user?['id'] ?? '').toString();
    final from = _range?.start;
    final to = _range?.end;

    final res = await widget.repo
        .listTransactions(
          userId: userId,
          accountId: _accountId, // pass resolved account for backends filtering by account
          page: page,
          pageSize: _pageSize,
          query: _query,
          type: _type,
          status: _status,
          from: from,
          to: to,
        )
        .timeout(const Duration(seconds: 25));

    List<Map<String, dynamic>> items = const <Map<String, dynamic>>[];
    if (res['items'] is List) {
      items = (res['items'] as List).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    } else if (res['data'] is List) {
      items = (res['data'] as List).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    } else if (res['transactions'] is List) {
      items = (res['transactions'] as List).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    } else if (res['results'] is List) {
      items = (res['results'] as List).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    } else if (res['payload'] is Map) {
      final p = Map<String, dynamic>.from(res['payload'] as Map);
      for (final k in ['items', 'data', 'transactions', 'results']) {
        if (p[k] is List) {
          items = (p[k] as List).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
          break;
        }
      }
    }

    final total = (res['total'] as num?)?.toInt() ??
        (res['count'] as num?)?.toInt() ??
        (res['payload'] is Map ? (Map<String, dynamic>.from(res['payload'] as Map)['total'] as num?)?.toInt() : null);

    bool hasMore;
    if (total != null) {
      hasMore = (page * _pageSize) < total;
    } else if (res['has_more'] is bool) {
      hasMore = res['has_more'] == true;
    } else if (res['next'] != null) {
      hasMore = true;
    } else {
      hasMore = items.length >= _pageSize;
    }

    return _PageResult(items: items, hasMore: hasMore);
  }

  String _humanizeError(Object? err) {
    try {
      if (err is TimeoutException) return _t('error_network');
      if (err is DioException) {
        final code = err.response?.statusCode ?? 0;
        if (err.type == DioExceptionType.connectionError ||
            err.type == DioExceptionType.connectionTimeout ||
            err.type == DioExceptionType.receiveTimeout ||
            err.type == DioExceptionType.sendTimeout) {
          return _t('error_network');
        }
        if (code >= 500) return _t('error_server');
        if (code == 401) return _t('error_auth');
        if (code == 403) return _t('error_permission');
        if (code == 404) return _t('error_not_found');
        if (code == 422) return _t('error_invalid');
        return '${_t('error_unknown')} (HTTP $code)';
      }
    } catch (_) {}
    return _t('error_unknown');
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final lastMonth = DateTime(now.year, now.month - 1, now.day);
    final initial = _range ?? DateTimeRange(start: lastMonth, end: now);
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
      initialDateRange: initial,
      helpText: _t('pick_date'),
      saveText: _t('apply'),
    );
    if (!mounted) return;
    if (picked != null) {
      setState(() => _range = picked);
      _reload();
    }
  }

  void _clearDateRange() {
    setState(() => _range = null);
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LocaleCubit, Locale>(
      builder: (context, locale) {
        final isSwahili = locale.languageCode == 'sw';
        final cs = Theme.of(context).colorScheme;

        return Scaffold(
          appBar: AppBar(
            title: Text(_t('title', isSwahili: isSwahili)),
            actions: [
              IconButton(
                tooltip: _t('pick_date', isSwahili: isSwahili),
                icon: const Icon(Icons.calendar_month),
                onPressed: _pickDateRange,
              ),
              if (_range != null)
                IconButton(
                  tooltip: _t('clear_date', isSwahili: isSwahili),
                  icon: const Icon(Icons.clear),
                  onPressed: _clearDateRange,
                ),
            ],
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: SizedBox(
                  height: 44,
                  child: TextField(
                    controller: _searchCtrl,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: _t('search_hint', isSwahili: isSwahili),
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _query.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                _searchCtrl.clear();
                              },
                            )
                          : null,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      isDense: true,
                    ),
                  ),
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    _FilterChipX(
                      label: _t('all', isSwahili: isSwahili), 
                      selected: _type == 'all', 
                      onTap: () => _setType('all'),
                    ),
                    _FilterChipX(
                      label: _t('deposit', isSwahili: isSwahili), 
                      selected: _type == 'deposit', 
                      onTap: () => _setType('deposit'),
                    ),
                    _FilterChipX(
                      label: _t('withdrawal', isSwahili: isSwahili), 
                      selected: _type == 'withdrawal', 
                      onTap: () => _setType('withdrawal'),
                    ),
                    _FilterChipX(
                      label: _t('transfer', isSwahili: isSwahili), 
                      selected: _type == 'transfer', 
                      onTap: () => _setType('transfer'),
                    ),
                    const SizedBox(width: 16),
                    _StatusChip(
                      cs: cs, 
                      label: _t('status_all', isSwahili: isSwahili), 
                      selected: _status == 'all', 
                      onTap: () => _setStatus('all'),
                    ),
                    _StatusChip(
                      cs: cs, 
                      label: _t('success', isSwahili: isSwahili), 
                      selected: _status == 'success', 
                      onTap: () => _setStatus('success'),
                    ),
                    _StatusChip(
                      cs: cs, 
                      label: _t('pending', isSwahili: isSwahili), 
                      selected: _status == 'pending', 
                      onTap: () => _setStatus('pending'),
                    ),
                    _StatusChip(
                      cs: cs, 
                      label: _t('failed', isSwahili: isSwahili), 
                      selected: _status == 'failed', 
                      onTap: () => _setStatus('failed'),
                    ),
                    _StatusChip(
                      cs: cs, 
                      label: _t('reversed', isSwahili: isSwahili), 
                      selected: _status == 'reversed', 
                      onTap: () => _setStatus('reversed'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Expanded(child: _buildBody(cs, isSwahili)),
            ],
          ),
        );
      },
    );
  }

  void _setType(String v) {
    setState(() => _type = v);
    _reload();
  }

  void _setStatus(String v) {
    setState(() => _status = v);
    _reload();
  }

  Widget _buildBody(ColorScheme cs, bool isSwahili) {
    if (_initialLoading) {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 8,
        itemBuilder: (_, __) => _ShimmerLine(color: cs.surfaceContainerHighest),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: cs.error, size: 48),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: cs.onSurface)),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _reload, 
                icon: const Icon(Icons.refresh), 
                label: Text(_t('retry', isSwahili: isSwahili))
              ),
            ],
          ),
        ),
      );
    }

    if (_items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.receipt_long_outlined, color: cs.primary, size: 56),
              const SizedBox(height: 12),
              Text(
                _t('no_transactions', isSwahili: isSwahili), 
                style: TextStyle(fontSize: 16, color: cs.onSurfaceVariant), 
                textAlign: TextAlign.center
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: cs.primary,
      onRefresh: _reload,
      child: ListView.separated(
        controller: _scrollCtrl,
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        itemCount: _items.length + (_loadingMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, index) {
          if (index >= _items.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 2))),
            );
          }
          final tx = _items[index];
          final view = _TxView.from(tx, isSwahili: isSwahili);
          return Material(
            color: cs.surface,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => _openDetails(tx, isSwahili),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    _TxAvatar(view: view),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            view.title, 
                            maxLines: 1, 
                            overflow: TextOverflow.ellipsis, 
                            style: TextStyle(fontWeight: FontWeight.w700, color: cs.onSurface)
                          ),
                          const SizedBox(height: 2),
                          Text(
                            view.subtitle, 
                            maxLines: 1, 
                            overflow: TextOverflow.ellipsis, 
                            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          view.amountFormatted, 
                          maxLines: 1, 
                          overflow: TextOverflow.ellipsis, 
                          style: TextStyle(fontWeight: FontWeight.w800, color: view.amountColor(cs), fontSize: 14)
                        ),
                        const SizedBox(height: 2),
                        _StatusPillSmall(status: view.finalStatus, isSwahili: isSwahili),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _openDetails(Map<String, dynamic> tx, bool isSwahili) {
    final view = _TxView.from(tx, isSwahili: isSwahili);
    final cs = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: _TxAvatar(view: view),
                      title: Text(view.title, style: const TextStyle(fontWeight: FontWeight.w800)),
                      subtitle: Text(view.subtitle),
                    ),
                    const Divider(height: 24),
                    
                    // Amount Breakdown Section
                    Text(
                      _t('details_amount', isSwahili: isSwahili),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: cs.primary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: cs.outline.withValues(alpha: 0.2)),
                      ),
                      child: Column(
                        children: [
                          _DetailRow(
                            label: _t('total_amount', isSwahili: isSwahili),
                            value: view.amountFormatted,
                            valueColor: cs.onSurface,
                          ),
                          if (view.fee > 0) ...[
                            const SizedBox(height: 8),
                            _DetailRow(
                              label: _t('fee', isSwahili: isSwahili),
                              value: view.feeFormatted,
                              valueColor: cs.error,
                            ),
                            const Divider(height: 20),
                            _DetailRow(
                              label: _t('net_amount', isSwahili: isSwahili),
                              value: view.netAmountFormatted,
                              valueColor: cs.primary,
                              isBold: true,
                            ),
                          ],
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    Text(
                      _t('details_tx', isSwahili: isSwahili),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: cs.primary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Transaction Details
                    _DetailRow(label: _t('type', isSwahili: isSwahili), value: view.typeLabel),
                    _DetailRow(
                      label: _t('final_status', isSwahili: isSwahili),
                      value: view.statusLabel,
                      valueWidget: _StatusPillSmall(status: view.finalStatus, isSwahili: isSwahili),
                    ),
                    if (view.providerStatus.isNotEmpty)
                      _DetailRow(
                        label: _t('provider_status', isSwahili: isSwahili),
                        value: view.providerStatusLabel,
                      ),
                    _DetailRow(label: _t('date', isSwahili: isSwahili), value: view.dateFormatted),
                    if (view.potName.isNotEmpty) 
                      _DetailRow(label: _t('pot', isSwahili: isSwahili), value: view.potName),
                    if (view.provider.isNotEmpty) 
                      _DetailRow(label: _t('provider', isSwahili: isSwahili), value: view.provider.toUpperCase()),
                    if (view.reference.isNotEmpty) 
                      _DetailRow(
                        label: _t('ref', isSwahili: isSwahili),
                        value: view.reference,
                        copyable: true,
                      ),
                    if (view.providerRef.isNotEmpty) 
                      _DetailRow(
                        label: _t('provider_ref', isSwahili: isSwahili),
                        value: view.providerRef,
                        copyable: true,
                      ),
                    _DetailRow(label: _t('tx_id', isSwahili: isSwahili), value: view.id, copyable: true),
                    
                    const SizedBox(height: 20),
                    
                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              final txt = view.shareText(_t('receipt_title', isSwahili: isSwahili));
                              Clipboard.setData(ClipboardData(text: txt));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(_t('copied', isSwahili: isSwahili)),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                            icon: const Icon(Icons.share_outlined),
                            label: Text(_t('share_receipt', isSwahili: isSwahili)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => Navigator.pop(ctx),
                            icon: const Icon(Icons.check_circle_outline),
                            label: Text(_t('close', isSwahili: isSwahili)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _PageResult {
  final List<Map<String, dynamic>> items;
  final bool hasMore;
  const _PageResult({required this.items, required this.hasMore});
}

class _TxView {
  final String id;
  final String type;
  final String finalStatus;
  final String providerStatus;
  final String typeLabel;
  final String statusLabel;
  final String providerStatusLabel;
  final double amount;
  final double fee;
  final double netAmount;
  final String currency;
  final String reference;
  final String provider;
  final String providerRef;
  final DateTime date;
  final String potName;
  final String title;
  final String subtitle;
  final Map<String, dynamic> metadata;

  _TxView({
    required this.id,
    required this.type,
    required this.finalStatus,
    required this.providerStatus,
    required this.typeLabel,
    required this.statusLabel,
    required this.providerStatusLabel,
    required this.amount,
    required this.fee,
    required this.netAmount,
    required this.currency,
    required this.reference,
    required this.provider,
    required this.providerRef,
    required this.date,
    required this.potName,
    required this.title,
    required this.subtitle,
    required this.metadata,
  });

  factory _TxView.from(Map<String, dynamic> m, {required bool isSwahili}) {
    String pickS(List<String> ks) {
      for (final k in ks) {
        final v = m[k];
        if (v == null) continue;
        final s = v.toString().trim();
        if (s.isNotEmpty) return s;
      }
      return '';
    }

    num pickN(List<String> ks) {
      for (final k in ks) {
        final v = m[k];
        if (v is num) return v;
        if (v is String) {
          final s = v.replaceAll(',', '').trim();
          final d = double.tryParse(s);
          if (d != null) return d;
        }
      }
      return 0;
    }

    Map<String, dynamic>? pickM(List<String> ks) {
      for (final k in ks) {
        final v = m[k];
        if (v is Map) return Map<String, dynamic>.from(v);
      }
      return null;
    }

    final id = pickS(['id', '_id', 'tx_id', 'transaction_id']);
    final type = pickS(['type', 'tx_type', 'kind']).toLowerCase();
    final providerStatus = pickS(['provider_status', 'providerStatus']).toLowerCase();
    final rawFinalStatus = pickS(['final_status', 'finalStatus']).toLowerCase();
    final rawStatus = pickS(['status', 'tx_status', 'state', 'provider_status']).toLowerCase();
    final normalizedStatus = _normalizeFinalStatus(
      rawFinalStatus.isNotEmpty ? rawFinalStatus : rawStatus,
      providerStatus.isNotEmpty ? providerStatus : rawStatus,
    );

    final currency = (() {
      final c = pickS(['currency', 'ccy', 'cur', 'currency_code']);
      return c.isEmpty ? 'TZS' : c;
    })();

    final amount = pickN(['amount', 'amount_tzs', 'amountTZS', 'value', 'amount_value']).toDouble();
    final fee = pickN(['fee', 'transaction_fee', 'charge', 'fees']).toDouble();
    final netAmount = pickN(['net_amount', 'netAmount', 'amount_after_fee', 'final_amount']).toDouble();
    
    final ref = pickS(['reference', 'ref', 'receipt', 'txn_reference', 'transaction_reference']);
    final provider = pickS(['provider', 'payment_provider', 'gateway']);
    final providerRef = pickS(['provider_ref', 'provider_reference', 'external_ref', 'gateway_ref']);

    DateTime d = DateTime.now();
    final dateStr = pickS(['created_at', 'createdAt', 'date', 'time', 'timestamp']);
    if (dateStr.isNotEmpty) {
      d = DateTime.tryParse(dateStr) ?? d;
    } else if (m['created_at'] is num) {
      final millis = (m['created_at'] as num).toInt();
      d = DateTime.fromMillisecondsSinceEpoch(millis);
    }

    String potName = pickS(['pot_name', 'name', 'title']);
    if (potName.isEmpty) {
      final pot = pickM(['pot', 'account', 'bucket']);
      if (pot != null) {
        potName = (pot['name'] ?? pot['title'] ?? '').toString();
      }
    }

    final metadata = pickM(['metadata', 'meta', 'extra_data']) ?? {};

    final typeLabel = _typeLabel(type, isSwahili: isSwahili);
    final statusLabel = _statusLabel(normalizedStatus, isSwahili: isSwahili);
    final providerStatusLabel = _statusLabel(
      providerStatus.isNotEmpty ? providerStatus : normalizedStatus,
      isSwahili: isSwahili,
    );
    final dateFmt = DateFormat('dd MMM yyyy, HH:mm').format(d);
    final title = potName.isNotEmpty ? '$typeLabel • $potName' : typeLabel;
    final subtitle = '$statusLabel • $dateFmt';

    return _TxView(
      id: id,
      type: type.isEmpty ? 'other' : type,
      finalStatus: normalizedStatus.isEmpty ? 'pending' : normalizedStatus,
      providerStatus: (providerStatus.isNotEmpty ? providerStatus : rawStatus).toLowerCase(),
      typeLabel: typeLabel,
      statusLabel: statusLabel,
      providerStatusLabel: providerStatusLabel,
      amount: amount,
      fee: fee,
      netAmount: netAmount > 0 ? netAmount : (amount - fee),
      currency: currency,
      reference: ref,
      provider: provider.isEmpty ? 'selcom' : provider,
      providerRef: providerRef,
      date: d,
      potName: potName,
      title: title,
      subtitle: subtitle,
      metadata: metadata,
    );
  }

  String get amountFormatted {
    final n = NumberFormat.currency(locale: 'sw', symbol: 'TSh', decimalDigits: 0).format(amount);
    final sign = type == 'withdrawal' ? '-' : '';
    return '$sign$n';
  }

  String get feeFormatted {
    return NumberFormat.currency(locale: 'sw', symbol: 'TSh', decimalDigits: 0).format(fee);
  }

  String get netAmountFormatted {
    final n = NumberFormat.currency(locale: 'sw', symbol: 'TSh', decimalDigits: 0).format(netAmount);
    final sign = type == 'withdrawal' ? '-' : '';
    return '$sign$n';
  }

  Color amountColor(ColorScheme cs) => type == 'withdrawal' ? cs.error : cs.primary;

  String get dateFormatted => DateFormat('dd MMM yyyy, HH:mm').format(date);

  String shareText(String title) {
    return '''
🧾 $title
━━━━━━━━━━━━━━━━━━━━━━
Aina: $typeLabel
Hali: $statusLabel

💰 Maelezo ya Kiasi:
Kiasi cha Jumla: $amountFormatted
Ada: $feeFormatted
Kiasi Halisi: $netAmountFormatted

📅 Tarehe: $dateFormatted
 ${potName.isNotEmpty ? '📦 Mpango: $potName\n' : ''}${reference.isNotEmpty ? '🔖 Rujusa: $reference\n' : ''}${provider.isNotEmpty ? '🏦 Mtoa Huduma: $provider\n' : ''}${providerRef.isNotEmpty ? '📋 Namba ya Mtoa: $providerRef' : ''}
━━━━━━━━━━━━━━━━━━━━━━
Misana App
''';
  }
}

class _FilterChipX extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChipX({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: cs.primary,
        labelStyle: TextStyle(color: selected ? cs.onPrimary : cs.onSurface),
        backgroundColor: cs.surfaceContainerHighest.withValues(alpha: 0.5),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final ColorScheme cs;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _StatusChip({required this.cs, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        showCheckmark: false,
        selectedColor: cs.secondary,
        labelStyle: TextStyle(color: selected ? cs.onSecondary : cs.onSurface),
        backgroundColor: cs.surfaceContainerHighest.withValues(alpha: 0.4),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}

class _TxAvatar extends StatelessWidget {
  final _TxView view;
  const _TxAvatar({required this.view});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    Color bg;
    IconData icon;
    switch (view.type) {
      case 'deposit':
        bg = Colors.green.withValues(alpha: 0.15);
        icon = Icons.arrow_downward_rounded;
        break;
      case 'withdrawal':
        bg = Colors.red.withValues(alpha: 0.15);
        icon = Icons.arrow_upward_rounded;
        break;
      case 'transfer':
        bg = Colors.blue.withValues(alpha: 0.15);
        icon = Icons.swap_horiz_rounded;
        break;
      default:
        bg = cs.surfaceContainerHighest;
        icon = Icons.receipt_long;
    }

    return CircleAvatar(
      radius: 22,
      backgroundColor: bg,
      child: Icon(icon, color: cs.onSurface),
    );
  }
}

class _StatusPillSmall extends StatelessWidget {
  final String status;
  final bool isSwahili;
  const _StatusPillSmall({required this.status, required this.isSwahili});

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;
    switch (status.toLowerCase()) {
      case 'success':
      case 'completed':
      case 'posted': // treat "posted" (provider_status) as success
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case 'pending':
      case 'initiated':
      case 'processing':
        color = Colors.amber;
        icon = Icons.hourglass_top;
        break;
      case 'failed':
        color = Colors.red;
        icon = Icons.error_outline;
        break;
      case 'reversed':
      case 'refunded':
        color = Colors.blueGrey;
        icon = Icons.undo;
        break;
      default:
        color = Theme.of(context).colorScheme.onSurfaceVariant;
        icon = Icons.info_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            _statusLabel(status, isSwahili: isSwahili),
            style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Widget? valueWidget;
  final Color? valueColor;
  final bool copyable;
  final bool isBold;

  const _DetailRow({
    required this.label,
    this.value = '',
    this.valueWidget,
    this.valueColor,
    this.copyable = false,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                color: cs.onSurfaceVariant,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (valueWidget != null)
                  valueWidget!
                else
                  Flexible(
                    child: Text(
                      value,
                      textAlign: TextAlign.right,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                      style: TextStyle(
                        fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
                        color: valueColor ?? cs.onSurface,
                        fontSize: isBold ? 16 : 14,
                      ),
                    ),
                  ),
                if (copyable)
                  IconButton(
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(),
                    icon: Icon(Icons.copy, size: 16, color: cs.primary),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: value));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Imenakiliwa'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ShimmerLine extends StatefulWidget {
  final Color color;
  const _ShimmerLine({required this.color});

  @override
  State<_ShimmerLine> createState() => _ShimmerLineState();
}

class _ShimmerLineState extends State<_ShimmerLine> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
  late final Animation<double> _a =
      Tween<double>(begin: 0.25, end: 0.75).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _a,
      child: Container(
        height: 68,
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(color: widget.color.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

String _typeLabel(String t, {required bool isSwahili}) {
  switch (t.toLowerCase()) {
    case 'deposit':
      return isSwahili ? 'Malipo' : 'Pay';
    case 'withdrawal':
      return isSwahili ? 'Kutoa' : 'Withdrawal';
    case 'transfer':
      return isSwahili ? 'Uhamisho' : 'Transfer';
    default:
      return isSwahili ? 'Muamala' : 'Transaction';
  }
}

String _normalizeFinalStatus(String status, String providerStatus) {
  final s = status.toLowerCase();
  final p = providerStatus.toLowerCase();

  bool inList(String value, List<String> options) => options.contains(value);

  if (inList(s, ['success', 'succeeded', 'posted', 'complete', 'completed'])) return 'success';
  if (inList(s, ['failed', 'declined', 'error'])) return 'failed';
  if (inList(s, ['pending', 'processing', 'initiated'])) return 'pending';

  if (inList(p, ['success', 'succeeded', 'posted', 'complete', 'completed'])) return 'success';
  if (inList(p, ['failed', 'declined', 'error'])) return 'failed';
  if (inList(p, ['pending', 'processing', 'initiated'])) return 'pending';

  if (s.isNotEmpty) return s;
  if (p.isNotEmpty) return p;
  return 'pending';
}

String _statusLabel(String s, {required bool isSwahili}) {
  switch (s.toLowerCase()) {
    case 'success':
    case 'completed':
    case 'posted':
      return isSwahili ? 'Imefanikiwa' : 'Success';
    case 'pending':
    case 'initiated':
    case 'processing':
      return isSwahili ? 'Inasubiri' : 'Pending';
    case 'failed':
      return isSwahili ? 'Imeshindikana' : 'Failed';
    case 'reversed':
    case 'refunded':
      return isSwahili ? 'Imerejeshwa' : 'Reversed';
    default:
      return isSwahili ? 'Haijulikani' : 'Unknown';
  }
}
