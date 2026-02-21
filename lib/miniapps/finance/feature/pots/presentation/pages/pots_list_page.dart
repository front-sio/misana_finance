import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:misana_finance_app/core/i18n/locale_cubit.dart';

import 'package:misana_finance_app/core/format/ammount_formatter.dart';
import 'package:misana_finance_app/core/utils/message_mapper.dart';
import 'package:misana_finance_app/core/theme/app_theme.dart';
import 'package:misana_finance_app/miniapps/finance/feature/payments/domain/payments_repository.dart';
import 'package:misana_finance_app/miniapps/finance/feature/payments/presentation/pages/deposit_page.dart';
import 'package:misana_finance_app/core/transitions/page_transition.dart';

import 'package:misana_finance_app/auth/session/auth_cubit.dart';
import '../../domain/pots_repository.dart';
import '../bloc/pots_bloc.dart';
import '../bloc/pots_event.dart';
import '../bloc/pots_state.dart';
import '../utils/savings_plan.dart';

class PotsListPage extends StatefulWidget {
  final PotsRepository repo;
  const PotsListPage({super.key, required this.repo});

  @override
  State<PotsListPage> createState() => _PotsListPageState();
}

class _PotsListPageState extends State<PotsListPage> with SingleTickerProviderStateMixin {
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();
  Timer? _debounce;
  late AnimationController _pageAnimController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  String _query = '';
  String _cadence = 'daily';

  static const _strings = {
    'title': {'en': 'Career Investment Plans', 'sw': 'Mipango ya Uwekezaji wa Kazi'},
    'add_plan': {'en': 'Create Career Plan', 'sw': 'Unda Mpango wa Kazi'},
    'search_hint': {'en': 'Search career plan...', 'sw': 'Tafuta mpango wa kazi...'},
    'clear': {'en': 'Clear', 'sw': 'Futa'},
    'select_cadence': {'en': 'Select contribution frequency:', 'sw': 'Chagua mfumo wa michango:'},
    'day': {'en': 'Day', 'sw': 'Siku'},
    'week': {'en': 'Week', 'sw': 'Wiki'},
    'month': {'en': 'Month', 'sw': 'Mwezi'},
    'tap_hint': {'en': 'Tap a card to see full career plan summary.', 'sw': 'Bofya kadi kuona muhtasari kamili wa mpango wa kazi.'},
    'per_day': {'en': 'per day', 'sw': 'kwa siku'},
    'per_week': {'en': 'per week', 'sw': 'kwa wiki'},
    'per_month': {'en': 'per month', 'sw': 'kwa mwezi'},
    'amount_only': {'en': 'Target Only', 'sw': 'Lengo tu'},
    'time_only': {'en': 'Time Only', 'sw': 'Muda tu'},
    'amount_and_time': {'en': 'Target & Time', 'sw': 'Lengo & Muda'},
    'days_left': {'en': '{n} days', 'sw': '{n} siku'},
    'finished': {'en': 'Completed', 'sw': 'Imekamilika'},
    'summary': {'en': 'Career Summary', 'sw': 'Muhtasari wa Kazi'},
    'goal': {'en': 'Career Target', 'sw': 'Lengo la Kazi'},
    'duration': {'en': 'Duration', 'sw': 'Muda'},
    'conditions': {'en': 'Conditions', 'sw': 'Masharti'},
    'remaining': {'en': 'Remaining', 'sw': 'Imebaki'},
    'start': {'en': 'Start', 'sw': 'Mwanzo'},
    'end': {'en': 'Target Date', 'sw': 'Tarehe ya Lengo'},
    'months_n': {'en': '{n} months', 'sw': 'Miezi {n}'},
    'copy': {'en': 'Copy', 'sw': 'Nakili'},
    'ok': {'en': 'OK', 'sw': 'Sawa'},
    'copied': {'en': 'Career summary copied', 'sw': 'Muhtasari wa kaji umenakiliwa'},
    'plan_created': {'en': 'Career investment plan created successfully', 'sw': 'Mpango wa uwekezaji wa kazi umeundwa kikamilifu'},
    'empty_title': {'en': 'No career investment plans yet', 'sw': 'Hakuna mpango wa uwekezaji wa kazi bado'},
    'empty_desc': {'en': 'Create your first career plan to start investing in your professional growth.', 'sw': 'Unda mpango wa kwanza wa kazi ili uanze kuwekeza katika ukuaji wako wa kitaalamu.'},
    'create_plan': {'en': 'Create Career Plan', 'sw': 'Unda Mpango wa Kazi'},
    'no_results': {'en': 'No results', 'sw': 'Hakuna matokeo'},
    'no_results_desc': {'en': 'We could not find a career plan matching "{query}".', 'sw': 'Hatukupata mpango wa kazi unaolingana na "{query}".'},
    'clear_search': {'en': 'Clear search', 'sw': 'Futa utafutaji'},
    'error_occurred': {'en': 'An error occurred', 'sw': 'Hitilafu imetokea'},
    'retry': {'en': 'Retry', 'sw': 'Jaribu tena'},
    'new_plan': {'en': 'New Career Plan', 'sw': 'Mpango Mpya wa Kazi'},
    'daily_label': {'en': 'Daily', 'sw': 'Kwa Siku'},
    'weekly_label': {'en': 'Weekly', 'sw': 'Kwa Wiki'},
    'monthly_label': {'en': 'Monthly', 'sw': 'Kwa Mwezi'},
    'contributions': {'en': '{n} contributions', 'sw': '{n} michango'},
    'current_balance': {'en': 'Current Investment', 'sw': 'Uwekezaji wa Sasa'},
    'remaining_amount': {'en': 'Remaining', 'sw': 'Imebaki'},
    'goal_reached': {'en': 'Career target reached! 🎉', 'sw': 'Lengo la kazi limefikiwa! 🎉'},
    'progress': {'en': 'Career Growth', 'sw': 'Ukuaji wa Kazi'},
    'need_to_save': {'en': 'Need to invest', 'sw': 'Unahitaji kuwekeza'},
    'on_track': {'en': 'On track', 'sw': 'Kwenye mpango'},
    'behind': {'en': 'Behind schedule', 'sw': 'Umechelewa'},
    'ahead': {'en': 'Ahead of schedule', 'sw': 'Umeongoza'},
    'deposit_action': {'en': 'Pay this career', 'sw': 'Kuwekezea kazi hii'},
    'withdraw_action': {'en': 'Withdraw', 'sw': 'Toa fedha'},
  };

  String _t(String key, {Map<String, String>? params}) {
    final isSw = context.read<LocaleCubit>().state.languageCode == 'sw';
    final lang = isSw ? 'sw' : 'en';
    String text = _strings[key]?[lang] ?? _strings[key]?['en'] ?? key;

    if (params != null) {
      params.forEach((k, v) {
        text = text.replaceAll('{$k}', v);
      });
    }

    return text;
  }

  @override
  void initState() {
    super.initState();
    _pageAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pageAnimController, curve: Curves.easeOut),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.03),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _pageAnimController, curve: Curves.easeOutCubic),
    );
    _pageAnimController.forward();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    _pageAnimController.dispose();
    super.dispose();
  }

  void _onQueryChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() => _query = v.trim().toLowerCase());
    });
  }

  Future<void> _openCreate() async {
    final created = await Navigator.of(context).pushNamed('/pots/new');
    if (!mounted) return;
    if (created == true) {
      final uid = (context.read<AuthCubit>().state.user?['id'] ?? '').toString();
      if (uid.isNotEmpty) {
        context.read<PotsBloc>().add(PotsLoad(uid));
      }
      _showFeedback(
        message: _t('plan_created'),
        type: FeedbackType.success,
      );
    }
  }

  void _showFeedback({
    required String message,
    required FeedbackType type,
    Duration duration = const Duration(seconds: 4),
  }) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      _buildFeedbackSnackBar(message, type, duration),
    );
  }

  SnackBar _buildFeedbackSnackBar(String message, FeedbackType type, Duration duration) {
    final scheme = Theme.of(context).colorScheme;
    final brand = Theme.of(context).extension<BrandTheme>()!;

    Color bgColor;
    Color textColor;
    IconData icon;

    switch (type) {
      case FeedbackType.success:
        bgColor = brand.successColor;
        textColor = Colors.white;
        icon = Icons.check_circle_rounded;
        break;
      case FeedbackType.error:
        bgColor = brand.errorColor;
        textColor = Colors.white;
        icon = Icons.error_rounded;
        break;
      case FeedbackType.warning:
        bgColor = brand.warningColor;
        textColor = Colors.white;
        icon = Icons.warning_rounded;
        break;
      case FeedbackType.info:
        bgColor = scheme.primary;
        textColor = Colors.white;
        icon = Icons.info_rounded;
        break;
    }

    return SnackBar(
      content: Row(
        children: [
          Icon(icon, color: textColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: bgColor,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      duration: duration,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = (context.read<AuthCubit>().state.user?['id'] ?? '').toString();
    final scheme = Theme.of(context).colorScheme;

    return BlocProvider(
      key: ValueKey('pots-$uid'),
      create: (_) => PotsBloc(widget.repo)..add(PotsLoad(uid)),
      child: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: Scaffold(
            backgroundColor: scheme.surface,
            appBar: AppBar(
              title: Text(_t('title')),
              elevation: 0,
              scrolledUnderElevation: 2,
              shadowColor: scheme.scrim.withValues(alpha: 0.15),
              actions: [
                IconButton(
                  tooltip: _t('add_plan'),
                  onPressed: _openCreate,
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            ),
            body: BlocListener<PotsBloc, PotsState>(
              listener: (context, state) {
                if (state is PotError) {
                  _showFeedback(
                    message: MessageMapper.getPotsFriendlyError(state.error),
                    type: FeedbackType.error,
                  );
                }
              },
              child: Column(
                children: [
                  _TopControls(
                    searchCtrl: _searchCtrl,
                    searchFocus: _searchFocus,
                    onChangedQuery: _onQueryChanged,
                    cadence: _cadence,
                    onCadenceChanged: (v) => setState(() => _cadence = v),
                    t: _t,
                  ),
                  Expanded(
                    child: BlocBuilder<PotsBloc, PotsState>(
                      builder: (context, state) {
                        if (state is PotLoading) return const _SkeletonList();

                        if (state is PotError) {
                          return _ErrorView(
                            message: MessageMapper.getPotsFriendlyError(state.error),
                            onRetry: () {
                              if (uid.isNotEmpty) {
                                context.read<PotsBloc>().add(PotsLoad(uid));
                              }
                            },
                            t: _t,
                          );
                        }

                        final pots = state is PotsLoaded ? state.pots : <Map<String, dynamic>>[];
                        
                        if (pots.isEmpty) {
                          return _EmptyView(onCreate: _openCreate, t: _t);
                        }

                        final list = pots.where((p) {
                          if (_query.isEmpty) return true;
                          final name = (p['name'] ?? '').toString().toLowerCase();
                          final purpose = (p['purpose'] ?? '').toString().toLowerCase();
                          final amount =
                              ((p['goal_amount'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(0);
                          return name.contains(_query) ||
                              purpose.contains(_query) ||
                              amount.contains(_query);
                        }).toList();

                        if (list.isEmpty) {
                          return _NoResultsView(
                            query: _query,
                            onClear: () {
                              _searchCtrl.clear();
                              setState(() => _query = '');
                            },
                            t: _t,
                          );
                        }

                        return LayoutBuilder(
                          builder: (context, constraints) {
                            final isWide = constraints.maxWidth >= 680;
                            final padding = const EdgeInsets.fromLTRB(
                                16, 12, 16, kFloatingActionButtonMargin + 64);

                            return RefreshIndicator(
                              onRefresh: () async {
                                if (uid.isNotEmpty) {
                                  context.read<PotsBloc>().add(PotsLoad(uid));
                                }
                              },
                              color: scheme.primary,
                              child: isWide
                                  ? GridView.builder(
                                      padding: padding,
                                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 2,
                                        mainAxisSpacing: 12,
                                        crossAxisSpacing: 12,
                                        childAspectRatio: 1.75,
                                      ),
                                      itemCount: list.length,
                                      itemBuilder: (ctx, i) {
                                        final p = list[i];
                                        return _PotTile(
                                          index: i,
                                          pot: p,
                                          cadence: _cadence,
                                          onOpen: _openBreakdown,
                                          t: _t,
                                        );
                                      },
                                    )
                                  : ListView.separated(
                                      padding: padding,
                                      itemCount: list.length,
                                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                                      itemBuilder: (ctx, i) {
                                        final p = list[i];
                                        return _PotTile(
                                          index: i,
                                          pot: p,
                                          cadence: _cadence,
                                          onOpen: _openBreakdown,
                                          t: _t,
                                        );
                                      },
                                    ),
                            );
                          },
                        );
                      },
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

  void _openBreakdown(Map<String, dynamic> pot) {
    // Use backend-calculated values directly
    final goal = (pot['goal_amount'] as num?)?.toDouble() ?? 0.0;
    final currentBalance = (pot['current_balance'] as num?)?.toDouble() ?? 
                          (pot['current_amount'] as num?)?.toDouble() ??
                          (pot['balance'] as num?)?.toDouble() ?? 0.0;
    final name = (pot['name'] ?? _t('title')).toString();
    final cond = (pot['withdrawal_condition'] ?? 'amount').toString();
    
    // Use backend-provided status and recommendations
    final goalReached = pot['goal_reached'] == true;
    final amountGoalReached = pot['amount_goal_reached'] == true;
    final timeGoalReached = pot['time_goal_reached'] == true;
    final canWithdraw = pot['can_withdraw'] == true;
    final statusMessage = (pot['status_message'] ?? '').toString();
    final recommendation = (pot['recommendation'] ?? '').toString();
    
    // Use backend-calculated time metrics
    final daysRemaining = (pot['days_remaining'] as int?) ?? 0;
    final daysElapsed = (pot['days_elapsed'] as int?) ?? 0;
    final totalDays = (pot['total_days'] as int?) ?? 0;
    final timeProgressPercent = (pot['time_progress_percent'] as num?)?.toDouble() ?? 0.0;
    final progressPercent = (pot['progress_percent'] as num?)?.toDouble() ?? 0.0;
    final remainingAmount = (pot['remaining'] as num?)?.toDouble() ?? 0.0;
    
    // Parse dates
    DateTime? startDate;
    DateTime? endDate;
    if (pot['start_date'] != null) {
      startDate = DateTime.tryParse(pot['start_date'].toString());
    }
    if (pot['end_date'] != null) {
      endDate = DateTime.tryParse(pot['end_date'].toString());
    }
    
    final effectiveStart = startDate ?? DateTime.now();
    final effectiveEnd = endDate ?? DateTime.now();
    
    // Still calculate cadence requirements for display
    final months = (pot['duration_months'] as int?) ?? 0;
    final durationDays = (pot['duration_days'] as int?) ?? 0;
    final plan = SavingsPlan(
      goalAmount: goal,
      durationMonths: months,
      durationDays: durationDays > 0 ? durationDays : totalDays,
      startDate: startDate,
      endDate: endDate,
    );
    final daily = plan.forCadence('daily');
    final weekly = plan.forCadence('weekly');
    final monthly = plan.forCadence('monthly');

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final scheme = Theme.of(ctx).colorScheme;
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              8,
              16,
              16 + MediaQuery.of(ctx).viewPadding.bottom,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: scheme.onSurface,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Progress Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          scheme.primaryContainer.withValues(alpha: 0.3),
                          scheme.surfaceContainerHighest.withValues(alpha: 0.2),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: scheme.outline.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _t('current_balance'),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: scheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  AmountFormatter.money(currentBalance, withSymbol: true),
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                    color: scheme.primary,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  _t('goal'),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: scheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  AmountFormatter.money(goal, withSymbol: true),
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: scheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: progressPercent / 100.0,
                            minHeight: 10,
                            backgroundColor: scheme.surfaceContainerHighest,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              goalReached ? Colors.green : scheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "${progressPercent.toStringAsFixed(1)}% ${_t('progress')}",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: scheme.onSurface,
                              ),
                            ),
                            if (remainingAmount > 0 && !goalReached)
                              Text(
                                "${_t('remaining_amount')}: ${AmountFormatter.money(remainingAmount, withSymbol: true)}",
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: scheme.onSurfaceVariant,
                                ),
                              )
                            else if (goalReached)
                              Text(
                                statusMessage,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.green,
                                ),
                              )
                            else
                              Text(
                                statusMessage,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Status & Recommendation Banner
                  if (statusMessage.isNotEmpty)
                    const SizedBox(height: 16),
                  if (statusMessage.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            goalReached 
                              ? Colors.green.shade50
                              : timeGoalReached && !amountGoalReached
                                ? Colors.orange.shade50
                                : Colors.blue.shade50,
                            Colors.white,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: goalReached 
                            ? Colors.green.shade200
                            : timeGoalReached && !amountGoalReached
                              ? Colors.orange.shade200
                              : Colors.blue.shade200,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                goalReached 
                                  ? Icons.check_circle 
                                  : timeGoalReached && !amountGoalReached
                                    ? Icons.warning
                                    : Icons.info,
                                color: goalReached 
                                  ? Colors.green 
                                  : timeGoalReached && !amountGoalReached
                                    ? Colors.orange
                                    : Colors.blue,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  statusMessage,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: goalReached 
                                      ? Colors.green.shade900
                                      : timeGoalReached && !amountGoalReached
                                        ? Colors.orange.shade900
                                        : Colors.blue.shade900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (recommendation.isNotEmpty)
                            const SizedBox(height: 8),
                          if (recommendation.isNotEmpty)
                            Text(
                              recommendation,
                              style: TextStyle(
                                fontSize: 12,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                    ),
                  
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _BreakdownCard(
                          title: _t('daily_label'),
                          value: daily.amount,
                          deposits: daily.deposits,
                          icon: Icons.calendar_view_day,
                          t: _t,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _BreakdownCard(
                          title: _t('weekly_label'),
                          value: weekly.amount,
                          deposits: weekly.deposits,
                          icon: Icons.date_range,
                          t: _t,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _BreakdownCard(
                          title: _t('monthly_label'),
                          value: monthly.amount,
                          deposits: monthly.deposits,
                          icon: Icons.calendar_month,
                          t: _t,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _SummaryCard(
                          goal: goal,
                          months: months,
                          condition: cond,
                          daysLeft: daysRemaining,
                          startDate: effectiveStart,
                          endDate: effectiveEnd,
                          t: _t,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Action Buttons - Deposit & Withdraw
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(ctx);
                            _openPaymentFlow(pot, withdraw: false);
                          },
                          icon: const Icon(Icons.add_circle_outline, size: 20),
                          label: Text(_t('deposit_action')),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: scheme.primary,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: scheme.surfaceContainerHighest,
                            disabledForegroundColor: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: canWithdraw && currentBalance > 0 ? () {
                            Navigator.pop(ctx);
                            _openPaymentFlow(pot, withdraw: true);
                          } : null,
                          icon: const Icon(Icons.remove_circle_outline, size: 20),
                          label: Text(_t('withdraw_action')),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            disabledForegroundColor: scheme.onSurfaceVariant.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  
  void _openPaymentFlow(Map<String, dynamic> pot, {required bool withdraw}) {
    final potId = (pot['id'] ?? pot['pot_id'] ?? '').toString();
    final potName = (pot['name'] ?? 'Pot').toString();

    if (potId.isEmpty) {
      _showFeedback(
        message: 'Invalid pot ID',
        type: FeedbackType.error,
      );
      return;
    }

    Navigator.push(
      context,
      PageTransitions.slideUp(
        page: DepositPage(
          paymentsRepo: context.read<PaymentsRepository>(),
          potsRepo: widget.repo,
          flow: withdraw ? PaymentFlow.withdraw : PaymentFlow.deposit,
          initialPotId: potId,
          initialPotName: potName,
        ),
      ),
    ).then((_) {
      if (mounted) {
        final uid = (context.read<AuthCubit>().state.user?['id'] ?? '').toString();
        if (uid.isNotEmpty) {
          context.read<PotsBloc>().add(PotsLoad(uid));
        }
      }
    });
  }
}

enum FeedbackType { success, error, warning, info }

class _TopControls extends StatelessWidget {
  final TextEditingController searchCtrl;
  final FocusNode searchFocus;
  final void Function(String) onChangedQuery;
  final String cadence;
  final void Function(String) onCadenceChanged;
  final String Function(String, {Map<String, String>? params}) t;

  const _TopControls({
    required this.searchCtrl,
    required this.searchFocus,
    required this.onChangedQuery,
    required this.cadence,
    required this.onCadenceChanged,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(
          bottom: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: scheme.primary.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: searchCtrl,
              focusNode: searchFocus,
              onChanged: onChangedQuery,
              textInputAction: TextInputAction.search,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: scheme.onSurface,
              ),
              decoration: InputDecoration(
                hintText: t('search_hint'),
                hintStyle: TextStyle(
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
                  fontWeight: FontWeight.w400,
                ),
                prefixIcon: Icon(Icons.search_rounded, color: scheme.primary, size: 22),
                isDense: true,
                filled: true,
                fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.2),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: scheme.outlineVariant.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: scheme.primary, width: 1.5),
                ),
                suffixIcon: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: searchCtrl,
                  builder: (ctx, v, _) {
                    if (v.text.isEmpty) return const SizedBox.shrink();
                    return IconButton(
                      tooltip: t('clear'),
                      icon: Icon(Icons.close, color: scheme.onSurfaceVariant),
                      onPressed: () {
                        searchCtrl.clear();
                        onChangedQuery('');
                        searchFocus.unfocus();
                      },
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            t('select_cadence'),
            style: TextStyle(
              fontSize: 12,
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: SegmentedButton<String>(
              segments: [
                ButtonSegment(
                  value: 'daily',
                  icon: const Icon(Icons.calendar_view_day, size: 18),
                  label: Text(t('day'), style: const TextStyle(fontSize: 13)),
                ),
                ButtonSegment(
                  value: 'weekly',
                  icon: const Icon(Icons.date_range, size: 18),
                  label: Text(t('week'), style: const TextStyle(fontSize: 13)),
                ),
                ButtonSegment(
                  value: 'monthly',
                  icon: const Icon(Icons.calendar_month, size: 18),
                  label: Text(t('month'), style: const TextStyle(fontSize: 13)),
                ),
              ],
              selected: {cadence},
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                padding: WidgetStateProperty.all(
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
              ),
              onSelectionChanged: (s) => onCadenceChanged(s.first),
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: Text(
              t('tap_hint'),
              style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant.withValues(alpha: 0.6)),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _PotTile extends StatelessWidget {
  final int index;
  final Map<String, dynamic> pot;
  final String cadence;
  final void Function(Map<String, dynamic>) onOpen;
  final String Function(String, {Map<String, String>? params}) t;

  const _PotTile({
    required this.index,
    required this.pot,
    required this.cadence,
    required this.onOpen,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    // Use backend data directly
    final goal = (pot['goal_amount'] as num?)?.toDouble() ?? 0.0;
    final currentBalance = (pot['current_balance'] as num?)?.toDouble() ?? 
                          (pot['current_amount'] as num?)?.toDouble() ??
                          (pot['balance'] as num?)?.toDouble() ?? 0.0;
    final name = (pot['name'] ?? t('title')).toString();
    final cond = (pot['withdrawal_condition'] ?? 'amount').toString();
    
    // Use backend-calculated metrics
    final progressPercent = (pot['progress_percent'] as num?)?.toDouble() ?? 0.0;
    final daysRemaining = (pot['days_remaining'] as int?) ?? 0;
    final remainingAmount = (pot['remaining'] as num?)?.toDouble() ?? 0.0;
    final goalReached = pot['goal_reached'] == true;
    final statusMessage = (pot['status_message'] ?? '').toString();
    
    // Calculate cadence requirements for display
    final months = (pot['duration_months'] as int?) ?? 0;
    final durationDays = (pot['duration_days'] as int?) ?? 0;
    DateTime? startDate;
    DateTime? endDate;
    if (pot['start_date'] != null) {
      startDate = DateTime.tryParse(pot['start_date'].toString());
    }
    if (pot['end_date'] != null) {
      endDate = DateTime.tryParse(pot['end_date'].toString());
    }
    
    final plan = SavingsPlan(
      goalAmount: goal,
      durationMonths: months,
      durationDays: durationDays,
      startDate: startDate,
      endDate: endDate,
    );
    final per = plan.forCadence(cadence);
    final scheme = Theme.of(context).colorScheme;

    String cadenceLabel = cadence == 'daily'
        ? t('per_day')
        : cadence == 'weekly'
            ? t('per_week')
            : t('per_month');

    String condLabel = cond == 'both'
        ? t('amount_and_time')
        : cond == 'time'
            ? t('time_only')
            : t('amount_only');

    return _AnimatedTile(
      index: index,
      child: Card(
        elevation: 0.5,
        shadowColor: scheme.scrim.withValues(alpha: 0.05),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => onOpen(pot),
          borderRadius: BorderRadius.circular(18),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  scheme.primaryContainer.withValues(alpha: 0.15),
                  scheme.surface,
                ],
              ),
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: 0.3),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              scheme.primary,
                              scheme.primary.withValues(alpha: 0.7),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: scheme.primary.withValues(alpha: 0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.savings_rounded, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                color: scheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              condLabel,
                              style: TextStyle(
                                fontSize: 10,
                                color: scheme.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios_rounded,
                          color: scheme.onSurfaceVariant, size: 14),
                    ],
                  ),
                  const SizedBox(height: 10),
                  
                  // Progress Bar
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            AmountFormatter.money(currentBalance, withSymbol: true),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: scheme.primary,
                            ),
                          ),
                          Text(
                            "${progressPercent.toStringAsFixed(0)}%",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: progressPercent / 100.0,
                          minHeight: 8,
                          backgroundColor: scheme.surfaceContainerHighest,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            goalReached 
                              ? Colors.green 
                              : scheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                        Text(
                          goalReached && statusMessage.isNotEmpty
                            ? statusMessage
                            : remainingAmount > 0 
                              ? "${t('remaining')}: ${AmountFormatter.money(remainingAmount, withSymbol: true)}"
                              : t('goal_reached'),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: goalReached
                              ? Colors.green
                              : scheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                  
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          scheme.primary.withValues(alpha: 0.12),
                          scheme.primary.withValues(alpha: 0.06),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: scheme.primary.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.trending_up_rounded, size: 14, color: scheme.primary),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            "${AmountFormatter.money(per.amount, withSymbol: true)} $cadenceLabel",
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: scheme.onSurface,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.flag_rounded, size: 12, color: scheme.primary),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          AmountFormatter.money(goal),
                          style: TextStyle(
                            color: scheme.onSurfaceVariant,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.schedule_rounded, size: 12, color: scheme.primary),
                      const SizedBox(width: 3),
                      Text(
                        daysRemaining > 0
                            ? t('days_left', params: {'n': daysRemaining.toString()})
                            : t('finished'),
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
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

class _SummaryCard extends StatelessWidget {
  final double goal;
  final int months;
  final String condition;
  final int daysLeft;
  final DateTime startDate;
  final DateTime endDate;
  final String Function(String, {Map<String, String>? params}) t;

  const _SummaryCard({
    required this.goal,
    required this.months,
    required this.condition,
    required this.daysLeft,
    required this.startDate,
    required this.endDate,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final cond = condition == 'both'
        ? t('amount_and_time')
        : condition == 'time'
            ? t('time_only')
            : t('amount_only');

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.summarize_rounded, size: 16, color: scheme.primary),
                const SizedBox(width: 6),
                Text(t('summary'),
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: scheme.onSurface,
                      fontSize: 13,
                    )),
              ],
            ),
            const SizedBox(height: 10),
            _kv(t('goal'), AmountFormatter.money(goal)),
            const SizedBox(height: 4),
            _kv(t('duration'), months > 0 ? t('months_n', params: {'n': months.toString()}) : "-"),
            const SizedBox(height: 4),
            _kv(t('conditions'), cond),
            const SizedBox(height: 4),
            _kv(t('remaining'),
                daysLeft > 0 ? t('days_left', params: {'n': daysLeft.toString()}) : t('finished')),
            const SizedBox(height: 4),
            _kv(t('start'), "${startDate.day}/${startDate.month}/${startDate.year}"),
            const SizedBox(height: 4),
            _kv(t('end'), "${endDate.day}/${endDate.month}/${endDate.year}"),
          ],
        ),
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Row(
      children: [
        Expanded(
            child: Text(k,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ))),
        Flexible(
          child: Text(v,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}

class _BreakdownCard extends StatelessWidget {
  final String title;
  final double value;
  final int deposits;
  final IconData icon;
  final String Function(String, {Map<String, String>? params}) t;

  const _BreakdownCard({
    required this.title,
    required this.value,
    required this.deposits,
    required this.icon,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [scheme.primary, scheme.primary.withValues(alpha: 0.7)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              AmountFormatter.money(value),
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: scheme.primary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 3),
            Text(
              t('contributions', params: {'n': deposits.toString()}),
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final VoidCallback onCreate;
  final String Function(String, {Map<String, String>? params}) t;

  const _EmptyView({required this.onCreate, required this.t});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    scheme.primary.withValues(alpha: 0.15),
                    scheme.primary.withValues(alpha: 0.05),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.savings_outlined, color: scheme.primary, size: 60),
            ),
            const SizedBox(height: 24),
            Text(
              t('empty_title'),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: scheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              t('empty_desc'),
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                fontSize: 15,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add),
              label: Text(t('create_plan')),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoResultsView extends StatelessWidget {
  final String query;
  final VoidCallback onClear;
  final String Function(String, {Map<String, String>? params}) t;

  const _NoResultsView({
    required this.query,
    required this.onClear,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.search_off, color: scheme.onSurfaceVariant, size: 50),
            ),
            const SizedBox(height: 20),
            Text(
              t('no_results'),
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: scheme.onSurface,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              t('no_results_desc', params: {'query': query}),
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: onClear,
              icon: const Icon(Icons.clear),
              label: Text(t('clear_search')),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final String Function(String, {Map<String, String>? params}) t;

  const _ErrorView({
    required this.message,
    required this.onRetry,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final brand = Theme.of(context).extension<BrandTheme>()!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: brand.errorColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.error_outline, color: brand.errorColor, size: 50),
            ),
            const SizedBox(height: 20),
            Text(
              t('error_occurred'),
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: scheme.onSurface,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(t('retry')),
            ),
          ],
        ),
      ),
    );
  }
}

class _SkeletonList extends StatelessWidget {
  const _SkeletonList();

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4);
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) => ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: 120,
          decoration: BoxDecoration(
            color: base,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: base.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 12,
                            width: 140,
                            decoration: BoxDecoration(
                              color: base.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          const SizedBox(height: 5),
                          Container(
                            height: 9,
                            width: 80,
                            decoration: BoxDecoration(
                              color: base.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  height: 28,
                  width: 160,
                  decoration: BoxDecoration(
                    color: base.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const Spacer(),
                Container(
                  height: 10,
                  width: 200,
                  decoration: BoxDecoration(
                    color: base.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedTile extends StatelessWidget {
  final int index;
  final Widget child;
  const _AnimatedTile({required this.index, required this.child});

  @override
  Widget build(BuildContext context) {
    final int ms = (180 + min(320, index * 35)).toInt();
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: ms),
      curve: Curves.easeOutCubic,
      builder: (ctx, t, _) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, (1 - t) * 16),
          child: child,
        ),
      ),
    );
  }
}
