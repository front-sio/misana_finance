import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:misana_finance_app/core/format/ammount_formatter.dart';
import 'package:misana_finance_app/core/utils/message_mapper.dart';
import 'package:misana_finance_app/core/theme/app_theme.dart';

import '../../../session/auth_cubit.dart';
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
    'title': {'en': 'Savings Plans', 'sw': 'Mipango ya Akiba'},
    'add_plan': {'en': 'Create Plan', 'sw': 'Unda Mpango'},
    'search_hint': {'en': 'Search plan...', 'sw': 'Tafuta mpango...'},
    'clear': {'en': 'Clear', 'sw': 'Futa'},
    'select_cadence': {'en': 'Select contribution frequency:', 'sw': 'Chagua mfumo wa michango:'},
    'day': {'en': 'Day', 'sw': 'Siku'},
    'week': {'en': 'Week', 'sw': 'Wiki'},
    'month': {'en': 'Month', 'sw': 'Mwezi'},
    'tap_hint': {'en': 'Tap a card to see full plan summary.', 'sw': 'Bofya kadi kuona muhtasari kamili wa mpango.'},
    'per_day': {'en': 'per day', 'sw': 'kwa siku'},
    'per_week': {'en': 'per week', 'sw': 'kwa wiki'},
    'per_month': {'en': 'per month', 'sw': 'kwa mwezi'},
    'amount_only': {'en': 'Amount Only', 'sw': 'Kiasi tu'},
    'time_only': {'en': 'Time Only', 'sw': 'Muda tu'},
    'amount_and_time': {'en': 'Amount & Time', 'sw': 'Kiasi & Muda'},
    'days_left': {'en': '{n} days', 'sw': '{n} siku'},
    'finished': {'en': 'Finished', 'sw': 'Imeisha'},
    'summary': {'en': 'Summary', 'sw': 'Muhtasari'},
    'goal': {'en': 'Goal', 'sw': 'Lengo'},
    'duration': {'en': 'Duration', 'sw': 'Muda'},
    'conditions': {'en': 'Conditions', 'sw': 'Masharti'},
    'remaining': {'en': 'Remaining', 'sw': 'Imebaki'},
    'start': {'en': 'Start', 'sw': 'Mwanzo'},
    'end': {'en': 'End', 'sw': 'Mwisho'},
    'months_n': {'en': '{n} months', 'sw': 'Miezi {n}'},
    'copy': {'en': 'Copy', 'sw': 'Nakili'},
    'ok': {'en': 'OK', 'sw': 'Sawa'},
    'copied': {'en': 'Summary copied', 'sw': 'Muhtasari umenakiliwa'},
    'plan_created': {'en': 'Savings plan created successfully', 'sw': 'Mpango wa akiba umeundwa kikamilifu'},
    'empty_title': {'en': 'No savings plan yet', 'sw': 'Huna mpango wa akiba bado'},
    'empty_desc': {'en': 'Create your first plan to start saving efficiently.', 'sw': 'Unda mpango wa kwanza ili uanze kuweka akiba kwa ufanisi.'},
    'create_plan': {'en': 'Create Plan', 'sw': 'Unda Mpango'},
    'no_results': {'en': 'No results', 'sw': 'Hakuna matokeo'},
    'no_results_desc': {'en': 'We could not find a plan matching "{query}".', 'sw': 'Hatukupata mpango unaolingana na "{query}".'},
    'clear_search': {'en': 'Clear search', 'sw': 'Futa utafutaji'},
    'error_occurred': {'en': 'An error occurred', 'sw': 'Hitilafu imetokea'},
    'retry': {'en': 'Retry', 'sw': 'Jaribu tena'},
    'new_plan': {'en': 'New Plan', 'sw': 'Mpango Mpya'},
    'daily_label': {'en': 'Daily', 'sw': 'Kwa Siku'},
    'weekly_label': {'en': 'Weekly', 'sw': 'Kwa Wiki'},
    'monthly_label': {'en': 'Monthly', 'sw': 'Kwa Mwezi'},
    'contributions': {'en': '{n} contributions', 'sw': '{n} michango'},
  };

  String _t(String key, {Map<String, String>? params}) {
    final locale = Localizations.localeOf(context);
    final lang = locale.languageCode == 'en' ? 'en' : 'sw';
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
            floatingActionButton: FloatingActionButton.extended(
              onPressed: _openCreate,
              icon: const Icon(Icons.add),
              label: Text(_t('new_plan')),
              elevation: 4,
            ),
            floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
          ),
        ),
      ),
    );
  }

  void _openBreakdown(Map<String, dynamic> pot) {
    final goal = (pot['goal_amount'] as num?)?.toDouble() ?? 0.0;
    final months = (pot['duration_months'] as int?) ??
        int.tryParse((pot['duration_months'] ?? '0').toString()) ??
        0;
    final name = (pot['name'] ?? _t('title')).toString();
    final cond = (pot['withdrawal_condition'] ?? '').toString();
    final createdAt = pot['created_at'] != null
        ? DateTime.tryParse(pot['created_at'].toString())
        : null;

    final plan = SavingsPlan(goalAmount: goal, durationMonths: months);
    final daily = plan.forCadence('daily');
    final weekly = plan.forCadence('weekly');
    final monthly = plan.forCadence('monthly');

    final startDate = createdAt ?? DateTime.now();
    final endDate = startDate.add(Duration(days: months * 30));
    final daysLeft = max(0, endDate.difference(DateTime.now()).inDays);

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
                          daysLeft: daysLeft,
                          startDate: startDate,
                          endDate: endDate,
                          t: _t,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            final s =
                                "$name\n${_t('goal')}: ${AmountFormatter.money(goal)}\n${_t('duration')}: ${_t('months_n', params: {'n': months.toString()})}\n\n${_t('daily_label')}: ${AmountFormatter.money(daily.amount, withSymbol: true)} (${_t('contributions', params: {'n': daily.deposits.toString()})})\n${_t('weekly_label')}: ${AmountFormatter.money(weekly.amount, withSymbol: true)} (${_t('contributions', params: {'n': weekly.deposits.toString()})})\n${_t('monthly_label')}: ${AmountFormatter.money(monthly.amount, withSymbol: true)} (${_t('contributions', params: {'n': monthly.deposits.toString()})})\n\n${_t('start')}: ${startDate.day}/${startDate.month}/${startDate.year}\n${_t('end')}: ${endDate.day}/${endDate.month}/${endDate.year}\n${_t('remaining')}: ${_t('days_left', params: {'n': daysLeft.toString()})}";
                            Clipboard.setData(ClipboardData(text: s));
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).clearSnackBars();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    const Icon(Icons.check_circle_rounded,
                                        color: Colors.white, size: 20),
                                    const SizedBox(width: 12),
                                    Text(_t('copied'),
                                        style: const TextStyle(
                                            color: Colors.white, fontWeight: FontWeight.w500)),
                                  ],
                                ),
                                backgroundColor:
                                    Theme.of(context).extension<BrandTheme>()!.successColor,
                                behavior: SnackBarBehavior.floating,
                                margin: const EdgeInsets.all(16),
                                duration: const Duration(seconds: 3),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                            );
                          },
                          icon: const Icon(Icons.copy, size: 18),
                          label: Text(_t('copy')),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(Icons.check_circle_outline, size: 18),
                          label: Text(_t('ok')),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
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
    final goal = (pot['goal_amount'] as num?)?.toDouble() ?? 0.0;
    final months = (pot['duration_months'] as int?) ??
        int.tryParse((pot['duration_months'] ?? '0').toString()) ??
        0;
    final name = (pot['name'] ?? t('title')).toString();
    final cond = (pot['withdrawal_condition'] ?? '').toString();

    final plan = SavingsPlan(goalAmount: goal, durationMonths: months);
    final per = plan.forCadence(cadence);
    final scheme = Theme.of(context).colorScheme;

    final createdAt = pot['created_at'] != null
        ? DateTime.tryParse(pot['created_at'].toString())
        : null;
    final startDate = createdAt ?? DateTime.now();
    final endDate = startDate.add(Duration(days: months * 30));
    final daysLeft = max(0, endDate.difference(DateTime.now()).inDays);

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
                        daysLeft > 0
                            ? t('days_left', params: {'n': daysLeft.toString()})
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