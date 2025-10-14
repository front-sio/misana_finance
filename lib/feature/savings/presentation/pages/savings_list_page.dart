import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:misana_finance_app/feature/savings/presentation/utils/debouncer.dart';
import 'package:misana_finance_app/feature/savings/presentation/widgets/savings_buttons.dart';
import 'package:misana_finance_app/feature/savings/presentation/widgets/savings_card.dart';
import 'package:misana_finance_app/feature/savings/presentation/widgets/savings_empty.dart';
import 'package:misana_finance_app/feature/savings/presentation/widgets/savings_error.dart';
import 'package:misana_finance_app/feature/savings/presentation/widgets/savings_filter_chip.dart';
import 'package:misana_finance_app/feature/savings/presentation/widgets/savings_header.dart';
import 'package:misana_finance_app/feature/savings/presentation/widgets/savings_loading.dart';
import 'package:misana_finance_app/feature/savings/presentation/widgets/savings_no_results.dart';
import 'package:misana_finance_app/feature/savings/presentation/widgets/savings_payment_schedule.dart';
import 'package:misana_finance_app/feature/savings/presentation/widgets/savings_progress_bits.dart';
import 'package:misana_finance_app/feature/savings/presentation/widgets/savings_search_bar.dart';
import 'package:misana_finance_app/feature/savings/presentation/widgets/savings_status_badge.dart';
import 'package:misana_finance_app/feature/savings/presentation/widgets/savings_tx_card.dart';

import '../../../session/auth_cubit.dart';
import '../../domain/savings_repository.dart';
import '../bloc/savings_bloc.dart';
import '../bloc/savings_event.dart';
import '../bloc/savings_state.dart';

// Payments repo for inline plan transactions
import 'package:misana_finance_app/feature/payments/domain/payments_repository.dart';

// Utils
import '../utils/savings_plan.dart';

class SavingsListPage extends StatefulWidget {
  final SavingsRepository repo;
  const SavingsListPage({super.key, required this.repo});

  @override
  State<SavingsListPage> createState() => _SavingsListPageState();
}

class _SavingsListPageState extends State<SavingsListPage> with SingleTickerProviderStateMixin {
  final _searchCtrl = TextEditingController();
  final _debouncer = Debouncer(const Duration(milliseconds: 250));
  late TabController _tabController;

  String _query = '';
  String _status = 'all'; // all | active | pending | closed
  String _cadence = 'monthly'; // daily | weekly | monthly

  static const double _pageMaxWidth = 720; // mobile-first, then center on wider screens

  String _lang(BuildContext ctx) {
    try {
      return Localizations.localeOf(ctx).languageCode.toLowerCase();
    } catch (_) {
      return 'sw';
    }
  }

  String t(BuildContext ctx, String key) {
    final l = _lang(ctx);
    final sw = <String, String>{
      'title': 'Mipango ya Akiba',
      'subtitle': 'Panga fedha zako kwa ajili ya malengo ya baadaye',
      'search_hint': 'Tafuta mpango...',
      'all': 'Zote',
      'active': 'Hai',
      'pending': 'Inasubiri',
      'closed': 'Imefungwa',
      'day': 'Kila Siku',
      'week': 'Kila Wiki',
      'month': 'Kila Mwezi',
      'new_plan': 'Mpango Mpya',
      'no_plans_title': 'Hakuna Mipango ya Akiba',
      'no_plans_desc': 'Anzisha mpango wa akiba leo ili kufikia malengo yako ya kifedha.',
      'start_first': 'Anza Mpango wa Kwanza',
      'no_results': 'Hakuna Matokeo',
      'no_results_desc': 'Hatukupata mpango wowote unaofanana na',
      'error_title': 'Tatizo Limetokea',
      'retry': 'Jaribu Tena',
      'progress': 'Maendeleo',
      'goal': 'Lengo',
      'per': 'Kwa',
      'months': 'Miezi',
      'saved': 'Kimehifadhiwa',
      'remaining': 'Kilichosalia',
      'quick_tips': 'Vidokezo',
      'tip_text':
          'Weka akiba mara kwa mara kufikia lengo lako haraka. Unaweza kupanga malipo ya kiotomatiki kuepuka kusahau.',
      'share_plan': 'Shiriki Mpango',
      'projected_completion': 'Matarajio ya Kukamilika',
      'deposit_now': 'Weka Akiba',
      'share': 'Shiriki',
      'view_transactions': 'Miamala ya Mpango',
      'transactions_empty': 'Hakuna miamala kwa mpango huu bado.',
      'loading': 'Inapakia...',
      'ok': 'Sawa',
      'not_logged': 'Tafadhali ingia tena',
      'go_login': 'Nenda kwenye kuingia',
    };

    final en = <String, String>{
      'title': 'Savings Plans',
      'subtitle': 'Organize your money for future goals',
      'search_hint': 'Search plan...',
      'all': 'All',
      'active': 'Active',
      'pending': 'Pending',
      'closed': 'Closed',
      'day': 'Daily',
      'week': 'Weekly',
      'month': 'Monthly',
      'new_plan': 'New Plan',
      'no_plans_title': 'No Savings Plans',
      'no_plans_desc': 'Start a savings plan today to reach your financial goals.',
      'start_first': 'Start Your First Plan',
      'no_results': 'No Results',
      'no_results_desc': 'We didn’t find any plan matching',
      'error_title': 'Something Went Wrong',
      'retry': 'Try Again',
      'progress': 'Progress',
      'goal': 'Goal',
      'per': 'Per',
      'months': 'Months',
      'saved': 'Saved',
      'remaining': 'Remaining',
      'quick_tips': 'Tips',
      'tip_text':
          'Save regularly to reach your goal faster. You can schedule automatic payments to avoid forgetting.',
      'share_plan': 'Share Plan',
      'projected_completion': 'Projected Completion',
      'deposit_now': 'Deposit',
      'share': 'Share',
      'view_transactions': 'Plan Transactions',
      'transactions_empty': 'No transactions for this plan yet.',
      'loading': 'Loading...',
      'ok': 'OK',
      'not_logged': 'Please sign in again',
      'go_login': 'Go to login',
    };

    final dict = l.startsWith('sw') ? sw : en;
    return dict[key] ?? (en[key] ?? key);
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          switch (_tabController.index) {
            case 0:
              _cadence = 'daily';
              break;
            case 1:
              _cadence = 'weekly';
              break;
            case 2:
              _cadence = 'monthly';
              break;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debouncer.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _openCreate(BuildContext context) async {
    final created = await Navigator.of(context).pushNamed('/savings/new');
    if (!context.mounted) return;
    if (created == true) {
      final uid = (context.read<AuthCubit>().state.user?['id'] ?? '').toString();
      context.read<SavingsBloc>().add(SavingsLoad(uid));
      _showSuccessSnackBar(context, "Mpango wa akiba umeundwa!");
    }
  }

  void _showSuccessSnackBar(BuildContext context, String message) {
    final snackBar = SnackBar(
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      backgroundColor: Colors.green.shade800,
      content: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(child: Text(message, style: const TextStyle(color: Colors.white))),
        ],
      ),
      action: SnackBarAction(
        label: t(context, 'ok'),
        textColor: Colors.white,
        onPressed: () {},
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 3),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    // Keep tab synced with cadence
    final tabIndex = _cadence == 'daily' ? 0 : _cadence == 'weekly' ? 1 : 2;
    if (_tabController.index != tabIndex) {
      _tabController.animateTo(tabIndex);
    }

    // AUTH GATE: wait for user to be available to avoid firing loads with empty userId (causes 404)
    return BlocBuilder<AuthCubit, dynamic>(
      builder: (ctx, authState) {
        final userId = (authState.user?['id'] ?? '').toString();

        if (authState.checking) {
          return Scaffold(
            backgroundColor: scheme.surface,
            body: Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 2, color: scheme.primary),
              ),
            ),
          );
        }

        if (userId.isEmpty || authState.authenticated != true) {
          return Scaffold(
            backgroundColor: scheme.surface,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_outline, color: scheme.onSurfaceVariant),
                  const SizedBox(height: 12),
                  Text(t(context, 'not_logged'), style: TextStyle(color: scheme.onSurfaceVariant)),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false),
                    child: Text(t(context, 'go_login')),
                  ),
                ],
              ),
            ),
          );
        }

        // Only create SavingsBloc after we have a valid userId
        return BlocProvider(
          key: ValueKey('savings-bloc-$userId'),
          create: (_) => SavingsBloc(widget.repo)..add(SavingsLoad(userId)),
          child: Scaffold(
            body: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isCompact = constraints.maxWidth < 360;
                  return NestedScrollView(
                    headerSliverBuilder: (context, innerBoxIsScrolled) => [
                      SliverAppBar(
                        expandedHeight: 200.0,
                        floating: false,
                        pinned: true,
                        elevation: 0,
                        backgroundColor: scheme.surface, // deprecation-safe (was background)
                        flexibleSpace: FlexibleSpaceBar(
                          background: SavingsHeaderGradient(
                            title: t(context, 'title'),
                            subtitle: t(context, 'subtitle'),
                          ),
                        ),
                        bottom: PreferredSize(
                          preferredSize: const Size.fromHeight(62),
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 10, left: 16, right: 16),
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: _pageMaxWidth),
                                child: SavingsSearchBar(
                                  controller: _searchCtrl,
                                  hintText: t(context, 'search_hint'),
                                  onChanged: (v) => _debouncer.run(() {
                                    setState(() => _query = v.trim().toLowerCase());
                                  }),
                                  onClear: () {
                                    _searchCtrl.clear();
                                    setState(() => _query = '');
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                        actions: const [
                          IconButton(icon: Icon(Icons.notifications_outlined, color: Colors.white), onPressed: null),
                          IconButton(icon: Icon(Icons.more_vert, color: Colors.white), onPressed: null),
                        ],
                      ),
                    ],
                    body: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: _pageMaxWidth),
                        child: Column(
                          children: [
                            Material(
                              color: scheme.surface,
                              child: TabBar(
                                controller: _tabController,
                                isScrollable: isCompact,
                                labelColor: scheme.primary,
                                unselectedLabelColor: scheme.onSurfaceVariant,
                                indicatorColor: scheme.primary,
                                indicatorWeight: 3,
                                labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                                tabs: [
                                  Tab(icon: const Icon(Icons.calendar_view_day), text: t(context, 'day')),
                                  Tab(icon: const Icon(Icons.date_range), text: t(context, 'week')),
                                  Tab(icon: const Icon(Icons.calendar_month), text: t(context, 'month')),
                                ],
                              ),
                            ),

                            SavingsFilterChips(
                              selected: _status,
                              onChanged: (v) => setState(() => _status = v),
                              t: (k) => t(context, k),
                            ),

                            Expanded(
                              child: BlocBuilder<SavingsBloc, SavingsState>(
                                builder: (context, state) {
                                  if (state.loading) return const SavingsLoadingView();

                                  if (state.error != null) {
                                    return SavingsErrorView(
                                      title: t(context, 'error_title'),
                                      retryLabel: t(context, 'retry'),
                                      message: state.error!,
                                      onRetry: () {
                                        final uid =
                                            (context.read<AuthCubit>().state.user?['id'] ?? '').toString();
                                        if (uid.isNotEmpty) {
                                          context.read<SavingsBloc>().add(SavingsLoad(uid));
                                        }
                                      },
                                    );
                                  }

                                  if (state.accounts.isEmpty) {
                                    return SavingsEmptyView(
                                      title: t(context, 'no_plans_title'),
                                      desc: t(context, 'no_plans_desc'),
                                      cta: t(context, 'start_first'),
                                      onCreate: () => _openCreate(context),
                                    );
                                  }

                                  // Client-side filter/search
                                  final list = state.accounts.where((a) {
                                    final status = (a['status'] ?? '').toString().toLowerCase();
                                    if (_status != 'all' && status != _status) return false;
                                    if (_query.isEmpty) return true;

                                    final purpose = (a['purpose'] ?? '').toString().toLowerCase();
                                    final name = (a['name'] ?? '').toString().toLowerCase();
                                    final cond = (a['withdrawal_condition'] ?? '').toString().toLowerCase();
                                    final amount =
                                        ((a['goal_amount'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(0);

                                    return purpose.contains(_query) ||
                                        name.contains(_query) ||
                                        cond.contains(_query) ||
                                        status.contains(_query) ||
                                        amount.contains(_query);
                                  }).toList();

                                  if (list.isEmpty) {
                                    return SavingsNoResultsView(
                                      title: t(context, 'no_results'),
                                      descPrefix: t(context, 'no_results_desc'),
                                      query: _query,
                                    );
                                  }

                                  return RefreshIndicator(
                                    color: scheme.primary,
                                    onRefresh: () async {
                                      final uid =
                                          (context.read<AuthCubit>().state.user?['id'] ?? '').toString();
                                      if (uid.isNotEmpty) {
                                        context.read<SavingsBloc>().add(SavingsLoad(uid));
                                      }
                                    },
                                    child: ListView.builder(
                                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                                      physics: const AlwaysScrollableScrollPhysics(),
                                      itemCount: list.length,
                                      itemBuilder: (context, i) {
                                        final a = list[i];
                                        final goal = (a['goal_amount'] as num?)?.toDouble() ?? 0.0;
                                        final cond = (a['withdrawal_condition'] ?? '').toString();
                                        final status = (a['status'] ?? '').toString();
                                        final months = (a['duration_months'] as int?) ??
                                            int.tryParse((a['duration_months'] ?? '0').toString()) ??
                                            0;
                                        final locked = a['is_edit_locked'] == true;
                                        final progress = (a['current_amount'] as num?)?.toDouble() ?? 0.0;
                                        final progressPercent = goal > 0 ? (progress / goal).clamp(0.0, 1.0) : 0.0;

                                        final plan = SavingsPlan(goalAmount: goal, durationMonths: months);
                                        final breakdown = plan.forCadence(_cadence);

                                        return SavingsCard(
                                          index: i,
                                          name: (a['name'] ?? 'Mpango').toString(),
                                          goal: goal,
                                          months: months,
                                          currentAmount: progress,
                                          progressPercent: progressPercent,
                                          cadence: _cadence,
                                          cadenceAmount: breakdown.amount,
                                          condition: cond,
                                          status: status,
                                          locked: locked,
                                          t: (k) => t(context, k),
                                          onTap: () => _showDetailBottomSheet(context, a, plan),
                                        );
                                      },
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            floatingActionButton: GradientFAB(
              onPressed: () => _openCreate(context),
              icon: Icons.add,
              label: t(context, 'new_plan'),
            ),
            floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
          ),
        );
      },
    );
  }

  void _showDetailBottomSheet(
    BuildContext context,
    Map<String, dynamic> plan,
    SavingsPlan calculations,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final goal = (plan['goal_amount'] as num?)?.toDouble() ?? 0.0;
    final months = (plan['duration_months'] as int?) ?? 0;
    final name = (plan['name'] ?? 'Mpango').toString();
    final currentAmount = (plan['current_amount'] as num?)?.toDouble() ?? 0.0;
    final progressPercent = goal > 0 ? (currentAmount / goal).clamp(0.0, 1.0) : 0.0;

    final daily = calculations.forCadence('daily');
    final weekly = calculations.forCadence('weekly');
    final monthly = calculations.forCadence('monthly');

    final remaining = max(0, goal - currentAmount);
    final remainingFormatted =
        NumberFormat.currency(locale: 'sw', symbol: 'TSh', decimalDigits: 0).format(remaining);

    final potId = (plan['id'] ?? plan['pot_id'] ?? '').toString();
    final userId = (context.read<AuthCubit>().state.user?['id'] ?? '').toString();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.92,
          child: Container(
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 40,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(2.5),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: scheme.onSurface),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.purple.shade800, Colors.deepPurple.shade600],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: Colors.purple.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                  margin: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Flexible(
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ),
                        SavingsStatusBadge(status: plan['status'] ?? 'pending'),
                      ]),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(t(context, 'goal'),
                                  style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13)),
                              Text(
                                NumberFormat.currency(locale: 'sw', symbol: 'TSh', decimalDigits: 0).format(goal),
                                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text('${t(context, "months")} $months',
                                  style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13)),
                            ]),
                          ),
                          RingProgress(percent: progressPercent, size: 84, label: '${(progressPercent * 100).toInt()}%'),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 10,
                        runSpacing: 8,
                        children: [
                          PillStat(
                            icon: Icons.savings_outlined,
                            label: t(context, 'saved'),
                            value: NumberFormat.currency(locale: 'sw', symbol: 'TSh', decimalDigits: 0)
                                .format(currentAmount),
                            color: Colors.greenAccent.withOpacity(0.2),
                          ),
                          PillStat(
                            icon: Icons.timelapse_outlined,
                            label: t(context, 'remaining'),
                            value: remainingFormatted,
                            color: Colors.orangeAccent.withOpacity(0.2),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: DefaultTabController(
                    length: 3,
                    initialIndex: _cadence == 'daily'
                        ? 0
                        : _cadence == 'weekly'
                            ? 1
                            : 2,
                    child: Column(
                      children: [
                        TabBar(
                          labelColor: scheme.primary,
                          unselectedLabelColor: scheme.onSurfaceVariant,
                          indicatorColor: scheme.primary,
                          isScrollable: true,
                          tabs: [
                            Tab(text: t(context, 'day')),
                            Tab(text: t(context, 'week')),
                            Tab(text: t(context, 'month')),
                          ],
                        ),
                        Expanded(
                          child: TabBarView(
                            children: [
                              PaymentScheduleView(
                                amount: daily.amount,
                                deposits: daily.deposits,
                                icon: Icons.calendar_view_day,
                                title: t(context, 'day'),
                                goal: goal,
                                currentAmount: currentAmount,
                                months: months,
                                progressTitle: t(context, 'projected_completion'),
                                savedLabel: t(context, 'saved'),
                                remainingLabel: t(context, 'remaining'),
                                tipsTitle: t(context, 'quick_tips'),
                                tipText: t(context, 'tip_text'),
                                shareLabel: t(context, 'share_plan'),
                                onShare: () => _sharePaymentPlan(context, plan, calculations),
                              ),
                              PaymentScheduleView(
                                amount: weekly.amount,
                                deposits: weekly.deposits,
                                icon: Icons.date_range,
                                title: t(context, 'week'),
                                goal: goal,
                                currentAmount: currentAmount,
                                months: months,
                                progressTitle: t(context, 'projected_completion'),
                                savedLabel: t(context, 'saved'),
                                remainingLabel: t(context, 'remaining'),
                                tipsTitle: t(context, 'quick_tips'),
                                tipText: t(context, 'tip_text'),
                                shareLabel: t(context, 'share_plan'),
                                onShare: () => _sharePaymentPlan(context, plan, calculations),
                              ),
                              PaymentScheduleView(
                                amount: monthly.amount,
                                deposits: monthly.deposits,
                                icon: Icons.calendar_month,
                                title: t(context, 'month'),
                                goal: goal,
                                currentAmount: currentAmount,
                                months: months,
                                progressTitle: t(context, 'projected_completion'),
                                savedLabel: t(context, 'saved'),
                                remainingLabel: t(context, 'remaining'),
                                tipsTitle: t(context, 'quick_tips'),
                                tipText: t(context, 'tip_text'),
                                shareLabel: t(context, 'share_plan'),
                                onShare: () => _sharePaymentPlan(context, plan, calculations),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            // TODO: hook deposit flow for this pot
                          },
                          icon: const Icon(Icons.add_card),
                          label: Text(t(context, 'deposit_now')),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: scheme.primaryContainer,
                            foregroundColor: scheme.onPrimaryContainer,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            textStyle: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _sharePaymentPlan(context, plan, calculations),
                          icon: const Icon(Icons.share),
                          label: Text(t(context, 'share')),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: scheme.primary,
                            foregroundColor: scheme.onPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            textStyle: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      t(context, 'view_transactions'),
                      style: TextStyle(fontWeight: FontWeight.w800, color: scheme.onSurface),
                    ),
                  ),
                ),
                SizedBox(
                  height: 180,
                  child: FutureBuilder<List<Map<String, dynamic>>>(
                    future: _fetchPotTransactions(context, userId, potId),
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const InlineLoader();
                      }
                      final items = snap.data ?? const <Map<String, dynamic>>[];
                      if (items.isEmpty) {
                        return Center(
                          child: Text(
                            t(context, 'transactions_empty'),
                            style: TextStyle(color: scheme.onSurfaceVariant),
                          ),
                        );
                      }
                      return ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                        scrollDirection: Axis.horizontal,
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (_, i) => TxCard(item: items[i]),
                      );
                    },
                  ),
                ),

                SizedBox(height: MediaQuery.of(context).viewPadding.bottom),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _fetchPotTransactions(
      BuildContext context, String userId, String potId) async {
    if (userId.isEmpty || potId.isEmpty) return const <Map<String, dynamic>>[];
    final paymentsRepo = RepositoryProvider.of<PaymentsRepository>(context);

    final res = await paymentsRepo
        .listTransactions(
          userId: userId,
          page: 1,
          pageSize: 100,
          query: '',
          type: 'all',
          status: 'all',
        )
        .timeout(const Duration(seconds: 20));

    final items = ((res['items'] as List?) ?? const <dynamic>[])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .where((m) => (m['pot_id'] ?? '').toString() == potId)
        .toList()
      ..sort((a, b) {
        final ad = (a['created_at'] ?? '').toString();
        final bd = (b['created_at'] ?? '').toString();
        return bd.compareTo(ad);
      });

    return items.take(12).toList();
  }

  void _sharePaymentPlan(BuildContext context, Map<String, dynamic> plan, SavingsPlan calculations) {
    final daily = calculations.forCadence('daily');
    final weekly = calculations.forCadence('weekly');
    final monthly = calculations.forCadence('monthly');
    final name = (plan['name'] ?? 'Mpango').toString();
    final goal = (plan['goal_amount'] as num?)?.toDouble() ?? 0.0;
    final months = (plan['duration_months'] as int?) ?? 0;

    final formattedGoal = NumberFormat.currency(locale: 'sw', symbol: 'TSh', decimalDigits: 0).format(goal);
    final formattedDaily = NumberFormat.currency(locale: 'sw', symbol: 'TSh', decimalDigits: 0).format(daily.amount);
    final formattedWeekly =
        NumberFormat.currency(locale: 'sw', symbol: 'TSh', decimalDigits: 0).format(weekly.amount);
    final formattedMonthly =
        NumberFormat.currency(locale: 'sw', symbol: 'TSh', decimalDigits: 0).format(monthly.amount);

    final str = """
🏦 $name - ${t(context, 'title')}

🎯 ${t(context, 'goal')}: $formattedGoal
⏱️ ${t(context, 'months')}: $months

💰 ${t(context, 'per')}:
 • ${t(context, 'day')}: $formattedDaily
 • ${t(context, 'week')}: $formattedWeekly
 • ${t(context, 'month')}: $formattedMonthly

👉 ${t(context, 'subtitle')}
""";

    Clipboard.setData(ClipboardData(text: str));
    _showSuccessSnackBar(context, "Muhtasari umehifadhiwa kwenye clipboard");
  }
}