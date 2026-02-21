import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import 'package:misana_finance_app/core/extensions/sorted_copy.dart';
import 'package:misana_finance_app/miniapps/finance/feature/pots/domain/pots_repository.dart';
import 'package:misana_finance_app/miniapps/finance/feature/payments/domain/payments_repository.dart';
import 'package:misana_finance_app/auth/session/auth_cubit.dart';
import 'package:misana_finance_app/miniapps/finance/feature/account/domain/account_repository.dart';
import 'package:misana_finance_app/core/i18n/locale_cubit.dart';

enum PaymentFlow { deposit, withdraw }

class DepositPage extends StatefulWidget {
  final PaymentsRepository paymentsRepo;
  final PotsRepository potsRepo;
  final PaymentFlow flow;
  final String? initialPotId;
  final String? initialPotName;
  final Future<String> Function()? resolveAccountId;

  const DepositPage({
    super.key,
    required this.paymentsRepo,
    required this.potsRepo,
    this.flow = PaymentFlow.deposit,
    this.initialPotId,
    this.initialPotName,
    this.resolveAccountId,
  });

  @override
  State<DepositPage> createState() => _DepositPageState();
}

class _DepositPageState extends State<DepositPage> {
  late Future<List<Map<String, dynamic>>> _potsFuture;
  bool get _isWithdraw => widget.flow == PaymentFlow.withdraw;
  bool _openedInitial = false;

  @override
  void initState() {
    super.initState();
    _potsFuture = _loadPots();
    _openInitialDirectIfNeeded();
  }

  // -------------------------- Localization --------------------------
  String _lang(BuildContext context) {
    try {
      final c = context.read<LocaleCubit>().state.languageCode;
      if (c.isNotEmpty) return c;
    } catch (_) {}
    try {
      final loc = Localizations.localeOf(context).languageCode;
      if (loc.isNotEmpty) return loc;
    } catch (_) {}
    return 'en';
  }

  String t(BuildContext context, String key) {
    final l = _lang(context);
    final sw = <String, String>{
      'title': 'Lipa',
      'subtitle': 'Chagua mpango wa kulipia',
      'loading': 'Inapakia...',
      'try_again': 'Jaribu tena',
      'no_pots_title': 'Bado huna mpango wa kazi.',
      'create_pot': 'Unda Mpango',
      'goal': 'Lengo',
      'status': 'Hali',
      'deposit_to': 'Lipa kwa',
      'amount_label': 'Kiasi cha kulipa',
      'amount_hint': 'Mfano: 10,000',
      'currency': 'TZS',
      'notes_optional': 'Maelezo (hiari)',
      'submit': 'Lipa Sasa',
      'submitting': 'Inalipa...',
      'success': '✅ Malipo yamekamilika',
      'cannot_find_account': 'Hatukuweza kupata account_id. Fungua/unganisha akaunti yako kwanza (KYC lazima iwe verified).',
      'no_internet': 'Inaonekana huna intaneti. Tafadhali angalia muunganisho wako kisha jaribu tena.',
      'bad_request': 'Ombi halijakamilika. Tafadhali kagua taarifa ulizoingiza na ujaribu tena.',
      'session_expired': 'Kikao kimeisha. Tafadhali ingia tena.',
      'forbidden': 'Huna ruhusa ya kufanya hatua hii.',
      'not_found': 'Hatukupata taarifa ulizoomba.',
      'conflict': 'Kuna mgongano wa maombi. Jaribu tena.',
      'too_many': 'Maombi mengi kwa sasa. Tafadhali jaribu tena baadaye.',
      'server_error': 'Hitilafu ya mfumo. Tafadhali jaribu tena baadaye.',
      'generic_error': 'Hitilafu imetokea. Tafadhali jaribu tena.',
      'timeout': 'Ombi limechelewa. Tafadhali jaribu tena.',
      'invalid_amount': 'Weka kiasi sahihi',
      'select_pot': 'Gusa mpango kulipa',
      'quick': 'Haraka',
      'fee_breakdown': 'Muhtasari wa Gharama',
      'amount_deposit': 'Kiasi cha malipo',
      'mno_fee': 'Ada ya MNO',
      'selcom_fee': 'Ada ya Selcom (1%)',
      'total_amount': 'Jumla ya Malipo',
      'you_will_pay': 'Utalipa',
      'career_label': 'Kazi',
    };

    final en = <String, String>{
      'title': 'Pay',
      'subtitle': 'Choose a pot to pay into',
      'loading': 'Loading...',
      'try_again': 'Try again',
      'no_pots_title': 'You have no career plan yet.',
      'create_pot': 'Create Pot',
      'goal': 'Goal',
      'status': 'Status',
      'deposit_to': 'Pay to',
      'amount_label': 'Amount to pay',
      'amount_hint': 'e.g. 10,000',
      'currency': 'TZS',
      'notes_optional': 'Notes (optional)',
      'submit': 'Pay Now',
      'submitting': 'Paying...',
      'success': '✅ Payment completed successfully',
      'cannot_find_account': 'Could not find account_id. Please create/link your account first (KYC must be verified).',
      'no_internet': 'Looks like you are offline. Please check your connection and try again.',
      'bad_request': 'Request was incomplete. Please check your input and try again.',
      'session_expired': 'Session expired. Please sign in again.',
      'forbidden': 'You do not have permission to perform this action.',
      'not_found': 'We could not find what you requested.',
      'conflict': 'There was a conflict. Please try again.',
      'too_many': 'Too many requests. Please try again later.',
      'server_error': 'Server error. Please try again later.',
      'generic_error': 'An error occurred. Please try again.',
      'timeout': 'Request timed out. Please try again.',
      'invalid_amount': 'Enter a valid amount',
      'select_pot': 'Tap a pot to pay',
      'quick': 'Quick',
      'fee_breakdown': 'Fee Breakdown',
      'amount_deposit': 'Payment Amount',
      'mno_fee': 'MNO Fee',
      'selcom_fee': 'Selcom Fee (1%)',
      'total_amount': 'Total Payment',
      'you_will_pay': 'You will pay',
      'career_label': 'Career',
    };

    final swWithdraw = <String, String>{
      'title': 'Toa',
      'subtitle': 'Chagua mpango wa kutoa fedha',
      'select_pot': 'Gusa mpango kuchukua fedha',
      'deposit_to': 'Toa kutoka',
      'amount_label': 'Kiasi cha kutoa',
      'submit': 'Toa Sasa',
      'submitting': 'Inatuma...',
      'success': '✅ Utoaji umekamilika',
    };

    final enWithdraw = <String, String>{
      'title': 'Withdraw',
      'subtitle': 'Select a pot to withdraw from',
      'select_pot': 'Tap a pot to withdraw',
      'deposit_to': 'Withdraw from',
      'amount_label': 'Amount to withdraw',
      'submit': 'Withdraw Now',
      'submitting': 'Processing...',
      'success': '✅ Withdrawal completed successfully',
    };

    final dict = l.startsWith('sw') ? sw : en;
    final overrides = widget.flow == PaymentFlow.withdraw
        ? (l.startsWith('sw') ? swWithdraw : enWithdraw)
        : const <String, String>{};

    return overrides[key] ?? (dict[key] ?? (en[key] ?? key));
  }

  // -------------------------- Data loads --------------------------
  Future<List<Map<String, dynamic>>> _loadPots() async {
    // Capture cubit once (no BuildContext use after awaits)
    final auth = context.read<AuthCubit>();
    final userId = (auth.state.user?['id'] ?? '').toString();
    if (userId.isEmpty) return const <Map<String, dynamic>>[];

    final dynamic repo = widget.potsRepo;
    try {
      final result = await repo.listByUser(userId);
      if (result is List) return result.cast<Map<String, dynamic>>();
    } catch (_) {}
    try {
      final result = await repo.listPots(userId);
      if (result is List) return result.cast<Map<String, dynamic>>();
    } catch (_) {}
    try {
      final result = await repo.list(userId);
      if (result is List) return result.cast<Map<String, dynamic>>();
    } catch (_) {}
    try {
      final result = await repo.getByUser(userId);
      if (result is List) return result.cast<Map<String, dynamic>>();
    } catch (_) {}

    try {
      final result = await repo.list(userId);
      if (result is Map && result['items'] is List) {
        return (result['items'] as List).cast<Map<String, dynamic>>();
      }
    } catch (_) {}

    return const <Map<String, dynamic>>[];
  }

  void _reload() {
    setState(() => _potsFuture = _loadPots());
  }

  void _openInitialDirectIfNeeded() {
    final targetId = (widget.initialPotId ?? '').trim();
    if (targetId.isEmpty || _openedInitial) return;
    _openedInitial = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final name = (widget.initialPotName ?? 'Pot').toString();
      _openDepositSheet(context, targetId, name, '');
    });
  }

  void _tryOpenInitial(List<Map<String, dynamic>> pots) {
    if (_openedInitial) return;
    final targetId = (widget.initialPotId ?? '').trim();
    if (targetId.isEmpty) return;

    Map<String, dynamic>? target;
    for (final p in pots) {
      final pid = (p['id'] ?? p['pot_id'] ?? '').toString();
      if (pid == targetId) {
        target = p;
        break;
      }
    }

    if (target != null) {
      _openedInitial = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _openPotPayment(target!));
    }
  }

  Future<void> _openPotPayment(Map<String, dynamic> pot) async {
    final potId = (pot['id'] ?? pot['pot_id'] ?? '').toString();
    if (potId.isEmpty) return;

    final potName = (pot['name'] ?? widget.initialPotName ?? 'Pot').toString();
    _openDepositSheet(context, potId, potName, '');
  }

  String _humanizeError(BuildContext context, Object? err) {
    final l = _lang(context);
    String? messageFromResponse(DioException e) {
      final data = e.response?.data;
      if (data is String && data.trim().isNotEmpty) return data;
      if (data is Map) {
        for (final key in ['message', 'error', 'detail', 'title']) {
          final v = data[key];
          if (v is String && v.trim().isNotEmpty) return v;
        }
      }
      return null;
    }

    try {
      if (err is TimeoutException) return t(context, 'timeout');
      if (err is DioException) {
        final msg = messageFromResponse(err);
        if (msg != null && msg.trim().length > 2) return msg;
        if (err.type == DioExceptionType.connectionTimeout ||
            err.type == DioExceptionType.sendTimeout ||
            err.type == DioExceptionType.receiveTimeout ||
            err.type == DioExceptionType.connectionError) {
          return t(context, 'no_internet');
        }
        final code = err.response?.statusCode ?? 0;
        switch (code) {
          case 400:
          case 422:
            return t(context, 'bad_request');
          case 401:
            return t(context, 'session_expired');
          case 403:
            return t(context, 'forbidden');
          case 404:
            return t(context, 'not_found');
          case 409:
            return t(context, 'conflict');
          case 429:
            return t(context, 'too_many');
          default:
            if (code >= 500 && code <= 599) return t(context, 'server_error');
        }
      }
    } catch (_) {}
    return t(context, 'generic_error');
  }

  // Resolve INTERNAL account_id (UUID) required by backend
  Future<String> _resolveAccountId() async {
    // Capture dependencies BEFORE awaiting
    final auth = context.read<AuthCubit>();
    final accountRepo = RepositoryProvider.of<AccountRepository>(context);

    final fromUser = (auth.state.user?['account_id'] ??
            auth.state.user?['accountId'] ??
            auth.state.user?['accountNumber'])
        ?.toString()
        .trim();
    if (fromUser != null && fromUser.isNotEmpty) return fromUser;

    try {
      await auth.refreshProfile();
    } catch (_) {}

    final userId = (auth.state.user?['id'] ?? '').toString();
    if (userId.isEmpty) return '';

    try {
      final acc = await accountRepo.getByUser(userId);

      if (acc is Map) {
        final m = Map<String, dynamic>.from((acc as Map).cast<String, dynamic>());
        final id = (m['id'] ?? m['account_id'] ?? '').toString().trim();
        if (id.isNotEmpty) return id;

        for (final k in ['data', 'account']) {
          final n = m[k];
          if (n is Map) {
            final id2 = Map<String, dynamic>.from((n as Map).cast<String, dynamic>())['id']?.toString().trim() ?? '';
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

    return '';
  }

  // -------------------------- UI --------------------------
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(t(context, 'title')),
        centerTitle: true,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _potsFuture,
        builder: (context, snapshot) {
          // Header area — gradient and subtitle
          Widget header = _HeaderHero(
            title: t(context, 'subtitle'),
            caption: t(context, 'select_pot'),
          );

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Column(
              children: [
                header,
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: 6,
                    itemBuilder: (_, __) => const _ShimmerPotCard(),
                  ),
                ),
              ],
            );
          }

          if (snapshot.hasError) {
            final msg = _humanizeError(context, snapshot.error);
            return Column(
              children: [
                header,
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, color: scheme.error, size: 60),
                          const SizedBox(height: 12),
                          Text(
                            msg,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: scheme.onSurface, fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            onPressed: _reload,
                            icon: const Icon(Icons.refresh),
                            label: Text(t(context, 'try_again')),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          }

          final raw = snapshot.data ?? const <Map<String, dynamic>>[];
          final pots = raw.sorted((a, b) {
            final bCreated = (b['created_at'] ?? '').toString();
            final aCreated = (a['created_at'] ?? '').toString();
            final cmp = bCreated.compareTo(aCreated);
            if (cmp != 0) return cmp;
            final bName = (b['name'] ?? '').toString();
            final aName = (a['name'] ?? '').toString();
            return aName.toLowerCase().compareTo(bName.toLowerCase());
          });

          _tryOpenInitial(pots);

          if (pots.isEmpty) {
            return Column(
              children: [
                header,
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.savings_outlined, color: scheme.primary, size: 72),
                          const SizedBox(height: 12),
                          Text(
                            t(context, 'no_pots_title'),
                            style: TextStyle(fontSize: 16, color: scheme.onSurfaceVariant),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: () => Navigator.of(context).pushNamed('/pots/new').then((_) => _reload()),
                            icon: const Icon(Icons.add),
                            label: Text(t(context, 'create_pot')),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          }

          return Column(
            children: [
              header,
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  itemCount: pots.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (ctx, i) {
                    final p = pots[i];
                    final name = (p['name'] ?? 'Mpango').toString();
                    final goal = (p['goal_amount'] as num?)?.toDouble() ?? 0.0;
                    final status = (p['status'] ?? '').toString();

                    return _PotCard(
                      name: name,
                      subtitle: '${t(context, 'goal')}: ${NumberFormat('#,###').format(goal)} ${t(context, 'currency')}',
                      statusLabel: '${t(context, 'status')}: $status',
                      onTap: () => _openPotPayment(p),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _openDepositSheet(BuildContext context, String potId, String name, String accountId) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return _DepositSheet(
          paymentsRepo: widget.paymentsRepo,
          potsRepo: widget.potsRepo,
          potId: potId,
          potName: name,
          accountId: accountId,
          resolveAccountId: widget.resolveAccountId ?? _resolveAccountId,
          flow: widget.flow,
          onSuccess: () {
            if (mounted) {
              ScaffoldMessenger.of(context)
                ..clearSnackBars()
                ..showSnackBar(
                SnackBar(content: Text(t(context, 'success'))),
              );
              _reload();
            }
          },
          t: (k) => t(context, k),
          lang: _lang(context),
        );
      },
    );
  }
}

// -------------------------- Fancy Header --------------------------
class _HeaderHero extends StatelessWidget {
  final String title;
  final String caption;
  const _HeaderHero({required this.title, required this.caption});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [cs.primary.withValues(alpha: 0.18), cs.secondary.withValues(alpha: 0.18)]
              : [cs.primary.withValues(alpha: 0.12), cs.secondary.withValues(alpha: 0.10)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.all(10),
            child: Icon(Icons.account_balance_wallet_outlined, color: cs.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Column(
                key: ValueKey(title),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: cs.onSurface,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    caption,
                    style: TextStyle(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// -------------------------- Pot Card --------------------------
class _PotCard extends StatelessWidget {
  final String name;
  final String subtitle;
  final String statusLabel;
  final VoidCallback onTap;

  const _PotCard({
    required this.name,
    required this.subtitle,
    required this.statusLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: cs.shadow.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(10),
                child: Icon(Icons.savings_outlined, color: cs.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: cs.onSurface),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.info_outline, size: 16, color: cs.onSurfaceVariant),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              statusLabel,
                              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

// -------------------------- Shimmer (skeleton) --------------------------
class _ShimmerPotCard extends StatefulWidget {
  const _ShimmerPotCard({Key? key}) : super(key: key);

  @override
  State<_ShimmerPotCard> createState() => _ShimmerPotCardState();
}

class _ShimmerPotCardState extends State<_ShimmerPotCard> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
    ..repeat(reverse: true);
  late final Animation<double> _a = Tween<double>(begin: 0.4, end: 0.9).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return FadeTransition(
      opacity: _a,
      child: Container(
        height: 84,
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.only(bottom: 12),
      ),
    );
  }
}

// -------------------------- Deposit Sheet --------------------------
class _DepositSheet extends StatefulWidget {
  final PaymentsRepository paymentsRepo;
  final PotsRepository potsRepo;
  final String potId;
  final String potName;
  final String accountId;
  final Future<String> Function()? resolveAccountId;
  final PaymentFlow flow;
  final VoidCallback onSuccess;

  // Localization injection (so we don't re-detect inside sheet)
  final String Function(String key) t;
  final String lang;

  const _DepositSheet({
    required this.paymentsRepo,
    required this.potsRepo,
    required this.potId,
    required this.potName,
    required this.accountId,
    required this.resolveAccountId,
    required this.flow,
    required this.onSuccess,
    required this.t,
    required this.lang,
  });

  @override
  State<_DepositSheet> createState() => _DepositSheetState();
}

class _DepositSheetState extends State<_DepositSheet> {
  final _amountCtrl = TextEditingController();
  final _narrationCtrl = TextEditingController(); // reserved for future metadata
  final _formKey = GlobalKey<FormState>();
  bool _submitting = false;
  bool get _isWithdraw => widget.flow == PaymentFlow.withdraw;
  bool _resolvingAccount = false;
  String _accountId = '';

  final List<int> _quickAmounts = const [5000, 10000, 20000, 50000, 100000];

  @override
  void initState() {
    super.initState();
    _accountId = widget.accountId.trim();
    if (_accountId.isEmpty && widget.resolveAccountId != null) {
      _resolvingAccount = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        try {
          final id = await widget.resolveAccountId!.call();
          if (!mounted) return;
          setState(() {
            _accountId = id;
            _resolvingAccount = false;
          });
        } catch (_) {
          if (!mounted) return;
          setState(() => _resolvingAccount = false);
        }
      });
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _narrationCtrl.dispose();
    super.dispose();
  }

  String? _validateAmount(String? v) {
    final s = (v ?? '').trim();
    final cleaned = s.replaceAll(',', '').replaceAll(' ', '');
    final d = int.tryParse(cleaned);
    if (d == null || d <= 0) return widget.t('invalid_amount');
    return null;
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final form = _formKey.currentState;
    if (form == null) return;
    if (!form.validate()) return;

    if (!_isWithdraw && _accountId.isEmpty) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text(widget.t('cannot_find_account'))));
      return;
    }

    setState(() => _submitting = true);
    try {
      final cleaned = _amountCtrl.text.trim().replaceAll(',', '').replaceAll(' ', '');
      final amountInt = int.parse(cleaned); // backend expects integer
      final note = _narrationCtrl.text.trim();

      if (_isWithdraw) {
        await widget.paymentsRepo
            .createWithdraw(
              accountId: _accountId.isEmpty ? null : _accountId,
              potId: widget.potId.isEmpty ? null : widget.potId,
              amountTZS: amountInt,
            )
            .timeout(const Duration(seconds: 25));
      } else {
        await widget.paymentsRepo
            .createDeposit(
              accountId: _accountId,
              potId: widget.potId.isEmpty ? null : widget.potId,
              amountTZS: amountInt,
            )
            .timeout(const Duration(seconds: 25));
      }

      if (!mounted) return;
      Navigator.pop(context);
      widget.onSuccess();
    } on TimeoutException {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text(widget.t('timeout'))));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text(_humanizeError(e))));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _humanizeError(Object? err) {
    String? messageFromResponse(DioException e) {
      final data = e.response?.data;
      if (data is String && data.trim().isNotEmpty) return data;
      if (data is Map) {
        for (final key in ['message', 'error', 'detail', 'title']) {
          final v = data[key];
          if (v is String && v.trim().isNotEmpty) return v;
        }
      }
      return null;
    }

    try {
      if (err is TimeoutException) return widget.t('timeout');
      if (err is DioException) {
        final msg = messageFromResponse(err);
        if (msg != null && msg.trim().length > 2) return msg;
        if (err.type == DioExceptionType.connectionTimeout ||
            err.type == DioExceptionType.sendTimeout ||
            err.type == DioExceptionType.receiveTimeout ||
            err.type == DioExceptionType.connectionError) {
          return widget.t('no_internet');
        }
        final code = err.response?.statusCode ?? 0;
        switch (code) {
          case 400:
          case 422:
            return widget.t('bad_request');
          case 401:
            return widget.t('session_expired');
          case 403:
            return widget.t('forbidden');
          case 404:
            return widget.t('not_found');
          case 409:
            return widget.t('conflict');
          case 429:
            return widget.t('too_many');
          default:
            if (code >= 500 && code <= 599) return widget.t('server_error');
        }
      }
    } catch (_) {}
    return widget.t('generic_error');
  }

  void _applyQuick(int amount) {
    final formatted = NumberFormat('#,###').format(amount);
    _amountCtrl.text = formatted;
    _amountCtrl.selection = TextSelection.fromPosition(TextPosition(offset: _amountCtrl.text.length));
    HapticFeedback.selectionClick();
  }

  // Fee calculation methods
  int _getDepositAmount() {
    final cleaned = _amountCtrl.text.trim().replaceAll(',', '').replaceAll(' ', '');
    return int.tryParse(cleaned) ?? 0;
  }

  double _calculateSelcomFee(int amount) {
    return amount * 0.01; // 1% fee
  }

  int _calculateMNOFee(int amount) {
    // MNO fee structure (based on common Tanzanian MNO fees)
    if (amount <= 1000) return 0;
    if (amount <= 5000) return 100;
    if (amount <= 10000) return 200;
    if (amount <= 30000) return 300;
    if (amount <= 50000) return 500;
    if (amount <= 100000) return 1000;
    if (amount <= 500000) return 2000;
    return 5000; // Max fee
  }

  double _calculateTotalAmount(int depositAmount) {
    final selcomFee = _calculateSelcomFee(depositAmount);
    final mnoFee = _calculateMNOFee(depositAmount);
    return depositAmount + selcomFee + mnoFee;
  }

  Widget _buildFeeBreakdown(ColorScheme cs) {
    final depositAmount = _getDepositAmount();
    if (depositAmount <= 0) return const SizedBox.shrink();

    final selcomFee = _calculateSelcomFee(depositAmount);
    final mnoFee = _calculateMNOFee(depositAmount);
    final total = _calculateTotalAmount(depositAmount);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.receipt_long_outlined, color: cs.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                widget.t('fee_breakdown'),
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          
          // Deposit Amount
          _buildFeeRow(
            widget.t('amount_deposit'),
            NumberFormat('#,###').format(depositAmount),
            cs,
            isMain: true,
          ),
          const SizedBox(height: 8),
          
          // MNO Fee
          _buildFeeRow(
            widget.t('mno_fee'),
            NumberFormat('#,###').format(mnoFee),
            cs,
          ),
          const SizedBox(height: 8),
          
          // Selcom Fee (1%)
          _buildFeeRow(
            widget.t('selcom_fee'),
            NumberFormat('#,###.##').format(selcomFee),
            cs,
          ),
          
          const SizedBox(height: 12),
          Divider(color: cs.primary.withValues(alpha: 0.3), thickness: 1.5),
          const SizedBox(height: 12),
          
          // Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.t('total_amount'),
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: cs.primary,
                ),
              ),
              Text(
                '${NumberFormat('#,###.##').format(total)} ${widget.t('currency')}',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  color: cs.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeeRow(String label, String amount, ColorScheme cs, {bool isMain = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isMain ? 14 : 13,
            fontWeight: isMain ? FontWeight.w700 : FontWeight.w600,
            color: isMain ? cs.onSurface : cs.onSurfaceVariant,
          ),
        ),
        Text(
          '$amount ${widget.t('currency')}',
          style: TextStyle(
            fontSize: isMain ? 14 : 13,
            fontWeight: isMain ? FontWeight.w700 : FontWeight.w600,
            color: isMain ? cs.onSurface : cs.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      top: false,
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(left: 16, right: 16, top: 10, bottom: bottom + 16),
        child: Material(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Pot summary card
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: cs.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
                    ),
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                    child: Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: cs.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.all(8),
                          child: Icon(Icons.savings_outlined, color: cs.primary),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '${widget.t('deposit_to')}: ${widget.potName} · ${widget.t('career_label')}',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (_resolvingAccount && !_isWithdraw) ...[
                    Row(
                      children: [
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2.2),
                        ),
                        const SizedBox(width: 8),
                        Text(widget.t('loading')),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Amount input with big font
                  TextFormField(
                    controller: _amountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: false),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[\d\s,]')),
                    ],
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                    decoration: InputDecoration(
                      labelText: widget.t('amount_label'),
                      hintText: widget.t('amount_hint'),
                      prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
                      suffixText: widget.t('currency'),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: _validateAmount,
                    autofillHints: const [AutofillHints.transactionAmount],
                    onFieldSubmitted: (_) => _submit(),
                    onChanged: (_) => setState(() {}), // Rebuild to update fee breakdown
                  ),

                  // Quick amounts
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(widget.t('quick'), style: TextStyle(color: cs.onSurfaceVariant, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _quickAmounts
                        .map((v) => _QuickChip(
                              label: '${NumberFormat('#,###').format(v)} ${widget.t('currency')}',
                              onTap: () => _applyQuick(v),
                            ))
                        .toList(),
                  ),

                  const SizedBox(height: 12),

                  // Fee Breakdown
                  if (_getDepositAmount() > 0) ...[
                    _buildFeeBreakdown(cs),
                    const SizedBox(height: 14),
                  ],

                  // Optional notes (UI-only, logic unchanged)
                  TextFormField(
                    controller: _narrationCtrl,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      labelText: widget.t('notes_optional'),
                      prefixIcon: const Icon(Icons.edit_note_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    maxLines: 2,
                  ),

                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: (_submitting || (_resolvingAccount && !_isWithdraw)) ? null : _submit,
                      icon: _submitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.check_circle_outline),
                      label: Text(_submitting ? widget.t('submitting') : widget.t('submit')),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        textStyle: const TextStyle(fontWeight: FontWeight.w800),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _QuickChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: cs.secondary.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: cs.secondary.withValues(alpha: 0.22)),
        ),
        child: Text(
          label,
          style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w700, fontSize: 12),
        ),
      ),
    );
  }
}
