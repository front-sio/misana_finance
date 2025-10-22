import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:misana_finance_app/core/format/ammount_formatter.dart';

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

class _PotsListPageState extends State<PotsListPage> {
  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  String _query = '';
  String _cadence = 'monthly'; // daily | weekly | monthly

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onQueryChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
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
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("✅ Mpango wa akiba umeundwa")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = (context.read<AuthCubit>().state.user?['id'] ?? '').toString();

    return BlocProvider(
      key: ValueKey('pots-$uid'),
      create: (_) => PotsBloc(widget.repo)..add(PotsLoad(uid)),
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Mipango ya Akiba"),
          actions: [
            IconButton(
              tooltip: "Unda Mpango",
              onPressed: _openCreate,
              icon: const Icon(Icons.add_circle_outline),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(88),
            child: _TopControls(
              searchCtrl: _searchCtrl,
              onChangedQuery: _onQueryChanged,
              cadence: _cadence,
              onCadenceChanged: (v) => setState(() => _cadence = v),
            ),
          ),
        ),
        body: BlocBuilder<PotsBloc, PotsState>(
          builder: (context, state) {
            if (state.loading) return const _SkeletonList();

            if (state.error != null) {
              return _ErrorView(
                message: "Imeshindikana kupakia: ${state.error}",
                onRetry: () {
                  if (uid.isNotEmpty) {
                    context.read<PotsBloc>().add(PotsLoad(uid));
                  }
                },
              );
            }

            if (state.pots.isEmpty) {
              return _EmptyView(onCreate: _openCreate);
            }

            final list = state.pots.where((p) {
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
              );
            }

            return LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 680;
                final padding =
                    const EdgeInsets.fromLTRB(16, 12, 16, kFloatingActionButtonMargin + 64);

                return RefreshIndicator(
                  onRefresh: () async {
                    if (uid.isNotEmpty) {
                      context.read<PotsBloc>().add(PotsLoad(uid));
                    }
                  },
                  child: isWide
                      ? GridView.builder(
                          padding: padding,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 1.85,
                          ),
                          itemCount: list.length,
                          itemBuilder: (ctx, i) {
                            final p = list[i];
                            return _PotTile(
                              index: i,
                              pot: p,
                              cadence: _cadence,
                              onOpen: _openBreakdown,
                            );
                          },
                        )
                      : ListView.separated(
                          padding: padding,
                          itemCount: list.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (ctx, i) {
                            final p = list[i];
                            return _PotTile(
                              index: i,
                              pot: p,
                              cadence: _cadence,
                              onOpen: _openBreakdown,
                            );
                          },
                        ),
                );
              },
            );
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _openCreate,
          icon: const Icon(Icons.add),
          label: const Text("Mpango Mpya"),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      ),
    );
  }

  void _openBreakdown(Map<String, dynamic> pot) {
    final goal = (pot['goal_amount'] as num?)?.toDouble() ?? 0.0;
    final months = (pot['duration_months'] as int?) ??
        int.tryParse((pot['duration_months'] ?? '0').toString()) ??
        0;
    final name = (pot['name'] ?? 'Akiba').toString();
    final cond = (pot['withdrawal_condition'] ?? '').toString();

    final plan = SavingsPlan(goalAmount: goal, durationMonths: months);
    final daily = plan.forCadence('daily');
    final weekly = plan.forCadence('weekly');
    final monthly = plan.forCadence('monthly');

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _BreakdownCard(
                        title: "Kwa Siku",
                        value: daily.amount,
                        deposits: daily.deposits,
                        icon: Icons.calendar_view_day,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _BreakdownCard(
                        title: "Kwa Wiki",
                        value: weekly.amount,
                        deposits: weekly.deposits,
                        icon: Icons.date_range,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _BreakdownCard(
                        title: "Kwa Mwezi",
                        value: monthly.amount,
                        deposits: monthly.deposits,
                        icon: Icons.calendar_month,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child:
                          _SummaryCard(goal: goal, months: months, condition: cond),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          final s =
                              "Lengo: ${AmountFormatter.money(goal)}\nMuda: miezi $months\nSiku: ${AmountFormatter.money(daily.amount, withSymbol: true)}\nWiki: ${AmountFormatter.money(weekly.amount, withSymbol: true)}\nMwezi: ${AmountFormatter.money(monthly.amount, withSymbol: true)}";
                          Clipboard.setData(ClipboardData(text: s));
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Muhtasari umenakiliwa")),
                          );
                        },
                        icon: const Icon(Icons.copy),
                        label: const Text("Nakili"),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text("Sawa"),
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
  }
}

/* =========================
   Top controls (Search + cadence)
   ========================= */
class _TopControls extends StatelessWidget {
  final TextEditingController searchCtrl;
  final void Function(String) onChangedQuery;
  final String cadence;
  final void Function(String) onCadenceChanged;

  const _TopControls({
    required this.searchCtrl,
    required this.onChangedQuery,
    required this.cadence,
    required this.onCadenceChanged,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: searchCtrl,
                  onChanged: onChangedQuery,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: "Tafuta kwa jina, kusudi, au kiasi...",
                    prefixIcon: const Icon(Icons.search),
                    isDense: true,
                    suffixIcon: ValueListenableBuilder<TextEditingValue>(
                      valueListenable: searchCtrl,
                      builder: (ctx, v, _) {
                        if (v.text.isEmpty) return const SizedBox.shrink();
                        return IconButton(
                          tooltip: 'Futa',
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            searchCtrl.clear();
                            onChangedQuery('');
                          },
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'daily',
                    icon: Icon(Icons.calendar_view_day),
                    label: Text("Siku"),
                  ),
                  ButtonSegment(
                    value: 'weekly',
                    icon: Icon(Icons.date_range),
                    label: Text("Wiki"),
                  ),
                  ButtonSegment(
                    value: 'monthly',
                    icon: Icon(Icons.calendar_month),
                    label: Text("Mwezi"),
                  ),
                ],
                selected: {cadence},
                style: const ButtonStyle(
                  visualDensity: VisualDensity.compact,
                ),
                onSelectionChanged: (s) => onCadenceChanged(s.first),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Bofya kadi kuona muhtasari wa mpango.",
              style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

/* =========================
   Pot list tile (responsive card)
   ========================= */
class _PotTile extends StatelessWidget {
  final int index;
  final Map<String, dynamic> pot;
  final String cadence;
  final void Function(Map<String, dynamic>) onOpen;

  const _PotTile({
    required this.index,
    required this.pot,
    required this.cadence,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final goal = (pot['goal_amount'] as num?)?.toDouble() ?? 0.0;
    final months = (pot['duration_months'] as int?) ??
        int.tryParse((pot['duration_months'] ?? '0').toString()) ??
        0;
    final name = (pot['name'] ?? 'Akiba').toString();
    final cond = (pot['withdrawal_condition'] ?? '').toString();

    final plan = SavingsPlan(goalAmount: goal, durationMonths: months);
    final per = plan.forCadence(cadence);

    return _AnimatedTile(
      index: index,
      child: Card(
        elevation: 1.5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => onOpen(pot),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 22,
                  child: const Icon(Icons.savings_outlined),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ),
                          _MetricPill(
                            label: cadence == 'daily'
                                ? "Kwa siku"
                                : cadence == 'weekly'
                                    ? "Kwa wiki"
                                    : "Kwa mwezi",
                            value: per.amount,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "${AmountFormatter.money(goal)} • Miezi $months",
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          _Chip(
                            text: cond == 'both'
                                ? "Kiasi & Muda"
                                : (cond == 'time' ? "Muda tu" : "Kiasi tu"),
                          ),
                          const _Chip(text: "Hariri ndani ya masaa 24"),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.black45),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/* =========================
   Small UI bits
   ========================= */
class _Chip extends StatelessWidget {
  final String text;
  const _Chip({required this.text});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: scheme.primary.withOpacity(0.2)),
      ),
      child: Text(
        text,
        style: TextStyle(fontWeight: FontWeight.w700, color: scheme.onSurface),
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  final String label;
  final double value;
  const _MetricPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: scheme.primary.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_graph, size: 14, color: scheme.primary),
          const SizedBox(width: 6),
          Text(
            "${AmountFormatter.money(value, withSymbol: true)} / $label",
            style: TextStyle(fontWeight: FontWeight.w700, color: scheme.onSurface),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final double goal;
  final int months;
  final String condition;
  const _SummaryCard({
    required this.goal,
    required this.months,
    required this.condition,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final cond =
        condition == 'both' ? "Kiasi & Muda" : (condition == 'time' ? "Muda tu" : "Kiasi tu");
    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Muhtasari",
                style:
                    TextStyle(fontWeight: FontWeight.w800, color: scheme.onSurface)),
            const SizedBox(height: 6),
            _kv("Lengo", AmountFormatter.money(goal)),
            _kv("Muda", "Miezi $months"),
            _kv("Masharti", cond),
            const SizedBox(height: 6),
            Text(
              "Marekebisho ndani ya saa 24 tu.",
              style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Expanded(child: Text(k, style: const TextStyle(fontWeight: FontWeight.w600))),
          Text(v),
        ],
      ),
    );
  }
}

class _BreakdownCard extends StatelessWidget {
  final String title;
  final double value;
  final int deposits;
  final IconData icon;
  const _BreakdownCard({
    required this.title,
    required this.value,
    required this.deposits,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: scheme.primary,
                  child: const Icon(Icons.savings, color: Colors.white),
                ),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              AmountFormatter.money(value),
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "$deposits michango",
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

/* =========================
   States: Empty / Error / Loading
   ========================= */
class _EmptyView extends StatelessWidget {
  final VoidCallback onCreate;
  const _EmptyView({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.savings_outlined, color: scheme.primary, size: 56),
            const SizedBox(height: 12),
            Text(
              "Huna mpango wa akiba bado",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Unda mpango wa kwanza ili uanze kuweka akiba.",
              style: TextStyle(color: scheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add),
              label: const Text("Unda Mpango"),
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
  const _NoResultsView({required this.query, required this.onClear});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, color: scheme.onSurfaceVariant, size: 48),
            const SizedBox(height: 12),
            Text(
              "Hakuna matokeo",
              style: TextStyle(fontWeight: FontWeight.w700, color: scheme.onSurface),
            ),
            const SizedBox(height: 6),
            Text(
              'Hatukupata mpango unaolingana na "$query".',
              style: TextStyle(color: scheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onClear,
              icon: const Icon(Icons.clear),
              label: const Text("Futa utafutaji"),
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
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: scheme.error, size: 48),
            const SizedBox(height: 12),
            Text(
              "Hitilafu imetokea",
              style: TextStyle(fontWeight: FontWeight.w700, color: scheme.onSurface),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(color: scheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text("Jaribu tena"),
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
    final base =
        Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.35);
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, __) => ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 100,
          decoration: BoxDecoration(
            color: base,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              const SizedBox(width: 14),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: base.withOpacity(0.8),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 14, width: 160, color: base.withOpacity(0.8)),
                    const SizedBox(height: 8),
                    Container(height: 12, width: 220, color: base),
                  ],
                ),
              ),
              const SizedBox(width: 14),
            ],
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
    final int ms = (220 + min(380, index * 40)).toInt();
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: ms),
      curve: Curves.easeOutCubic,
      builder: (ctx, t, _) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, (1 - t) * 12),
          child: child,
        ),
      ),
    );
  }
}