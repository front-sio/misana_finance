import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import 'package:misana_finance_app/core/extensions/sorted_copy.dart';
import 'package:misana_finance_app/feature/pots/domain/pots_repository.dart';
import 'package:misana_finance_app/feature/payments/domain/payments_repository.dart';
import 'package:misana_finance_app/feature/session/auth_cubit.dart';
import 'package:misana_finance_app/feature/account/domain/account_repository.dart';

class DepositPage extends StatefulWidget {
  final PaymentsRepository paymentsRepo;
  final PotsRepository potsRepo;

  const DepositPage({
    super.key,
    required this.paymentsRepo,
    required this.potsRepo,
  });

  @override
  State<DepositPage> createState() => _DepositPageState();
}

class _DepositPageState extends State<DepositPage> {
  late Future<List<Map<String, dynamic>>> _potsFuture;

  @override
  void initState() {
    super.initState();
    _potsFuture = _loadPots();
  }

  // -------------------------- Localization --------------------------
  String _lang(BuildContext context) {
    try {
      return Localizations.localeOf(context).languageCode.toLowerCase();
    } catch (_) {
      return 'sw';
    }
  }

  String t(BuildContext context, String key) {
    final l = _lang(context);
    final sw = <String, String>{
      'title': 'Weka (Deposit)',
      'subtitle': 'Chagua mpango wa kuweka fedha',
      'loading': 'Inapakia...',
      'try_again': 'Jaribu tena',
      'no_pots_title': 'Bado huna mpango/akaunti ya akiba.',
      'create_pot': 'Unda Mpango',
      'goal': 'Lengo',
      'status': 'Hali',
      'deposit_to': 'Weka kwenye',
      'amount_label': 'Kiasi cha kuweka',
      'amount_hint': 'Mfano: 10,000',
      'currency': 'TZS',
      'notes_optional': 'Maelezo (hiari)',
      'submit': 'Weka Sasa',
      'submitting': 'Inatuma...',
      'success': '✅ Muamala wa kuweka umekamilika',
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
      'select_pot': 'Gusa kadi kuendelea',
      'quick': 'Haraka',
    };

    final en = <String, String>{
      'title': 'Deposit',
      'subtitle': 'Choose a savings pot to deposit into',
      'loading': 'Loading...',
      'try_again': 'Try again',
      'no_pots_title': 'You have no savings pot yet.',
      'create_pot': 'Create Pot',
      'goal': 'Goal',
      'status': 'Status',
      'deposit_to': 'Deposit to',
      'amount_label': 'Amount to deposit',
      'amount_hint': 'e.g. 10,000',
      'currency': 'TZS',
      'notes_optional': 'Notes (optional)',
      'submit': 'Deposit Now',
      'submitting': 'Sending...',
      'success': '✅ Deposit completed successfully',
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
      'select_pot': 'Tap a card to continue',
      'quick': 'Quick',
    };

    // Future-ready: add other locales here, fallback to EN
    final dict = l.startsWith('sw') ? sw : en;
    return dict[key] ?? (en[key] ?? key);
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

  String _humanizeError(BuildContext context, Object? err) {
    final l = _lang(context);
    bool en = !l.startsWith('sw');
    try {
      if (err is TimeoutException) return t(context, 'timeout');
      if (err is DioException) {
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
                            onPressed: () => Navigator.of(context).pushNamed('/savings/new').then((_) => _reload()),
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
                    final potId = (p['id'] ?? '').toString();

                    return _PotCard(
                      name: name,
                      subtitle: '${t(context, 'goal')}: ${NumberFormat('#,###').format(goal)} ${t(context, 'currency')}',
                      statusLabel: '${t(context, 'status')}: $status',
                      onTap: () async {
                        final accountId = await _resolveAccountId();
                        if (!mounted) return;

                        if (accountId.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(t(context, 'cannot_find_account'))),
                          );
                          return;
                        }

                        _openDepositSheet(context, potId, name, accountId);
                      },
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
          potId: potId,
          potName: name,
          accountId: accountId,
          onSuccess: () {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
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
              ? [cs.primary.withOpacity(0.18), cs.secondary.withOpacity(0.18)]
              : [cs.primary.withOpacity(0.12), cs.secondary.withOpacity(0.10)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: cs.primary.withOpacity(0.14),
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
          border: Border.all(color: cs.outlineVariant.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: cs.shadow.withOpacity(0.06),
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
                  color: cs.primary.withOpacity(0.12),
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
          color: cs.surfaceVariant.withOpacity(0.45),
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
  final String potId;
  final String potName;
  final String accountId;
  final VoidCallback onSuccess;

  // Localization injection (so we don't re-detect inside sheet)
  final String Function(String key) t;
  final String lang;

  const _DepositSheet({
    required this.paymentsRepo,
    required this.potId,
    required this.potName,
    required this.accountId,
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

  final List<int> _quickAmounts = const [5000, 10000, 20000, 50000, 100000];

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

    setState(() => _submitting = true);
    try {
      final cleaned = _amountCtrl.text.trim().replaceAll(',', '').replaceAll(' ', '');
      final amountInt = int.parse(cleaned); // backend expects integer

      await widget.paymentsRepo
          .createDeposit(
            accountId: widget.accountId,
            potId: widget.potId.isEmpty ? null : widget.potId,
            amountTZS: amountInt,
          )
          .timeout(const Duration(seconds: 25));

      if (!mounted) return;
      Navigator.pop(context);
      widget.onSuccess();
    } on TimeoutException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(widget.t('timeout'))));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_humanizeError(e))));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _humanizeError(Object? err) {
    try {
      if (err is TimeoutException) return widget.t('timeout');
      if (err is DioException) {
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
                      border: Border.all(color: cs.outlineVariant.withOpacity(0.3)),
                    ),
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                    child: Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: cs.primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.all(8),
                          child: Icon(Icons.savings_outlined, color: cs.primary),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '${widget.t('deposit_to')}: ${widget.potName}',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

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
                      onPressed: _submitting ? null : _submit,
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
          color: cs.secondary.withOpacity(0.10),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: cs.secondary.withOpacity(0.22)),
        ),
        child: Text(
          label,
          style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w700, fontSize: 12),
        ),
      ),
    );
  }
}