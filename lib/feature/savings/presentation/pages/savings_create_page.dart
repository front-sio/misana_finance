import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import 'package:misana_finance_app/core/theme/app_theme.dart';
import 'package:misana_finance_app/core/ui/decimal_text_input_formatter.dart';
import 'package:misana_finance_app/feature/savings/presentation/widgets/plan_metrics.dart';

import '../../../session/auth_cubit.dart';
import '../../../account/domain/account_repository.dart';
import '../../domain/savings_repository.dart';
import '../bloc/savings_bloc.dart';
import '../bloc/savings_event.dart';
import '../bloc/savings_state.dart';
import '../utils/savings_plan.dart';

class SavingsCreatePage extends StatefulWidget {
  final SavingsRepository repo;
  const SavingsCreatePage({super.key, required this.repo});

  @override
  State<SavingsCreatePage> createState() => _SavingsCreatePageState();
}

class _SavingsCreatePageState extends State<SavingsCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _goalCtrl = TextEditingController();
  final _durationCtrl = TextEditingController(text: "6");
  final _purposeCtrl = TextEditingController();
  final _nameFocus = FocusNode();
  final _goalFocus = FocusNode();
  final _durationFocus = FocusNode();
  final _purposeFocus = FocusNode();

  String _condition = 'amount'; // amount | time | both
  String _cadence = 'monthly'; // daily | weekly | monthly

  @override
  void initState() {
    super.initState();
    _nameCtrl.addListener(_onChange);
    _goalCtrl.addListener(_onChange);
    _durationCtrl.addListener(_onChange);
  }

  @override
  void dispose() {
    _nameCtrl.removeListener(_onChange);
    _goalCtrl.removeListener(_onChange);
    _durationCtrl.removeListener(_onChange);
    _nameCtrl.dispose();
    _goalCtrl.dispose();
    _durationCtrl.dispose();
    _purposeCtrl.dispose();
    _nameFocus.dispose();
    _goalFocus.dispose();
    _durationFocus.dispose();
    _purposeFocus.dispose();
    super.dispose();
  }

  void _onChange() => setState(() {});

  SavingsPlan _plan() {
    final g = double.tryParse(_goalCtrl.text.trim()) ?? 0.0;
    final m = int.tryParse(_durationCtrl.text.trim()) ?? 0;
    return SavingsPlan(goalAmount: g, durationMonths: m);
  }

  void _applyPreset({required int months, double? goal}) {
    if (goal != null) _goalCtrl.text = goal.toStringAsFixed(0);
    _durationCtrl.text = months.toString();
    setState(() {});
  }

  String _fmt(num v) {
    final f = NumberFormat.decimalPattern();
    return "TZS ${f.format(v.round())}";
  }

  String _humanizeError(Object err) {
    try {
      if (err is DioException) {
        if (err.type == DioExceptionType.connectionTimeout ||
            err.type == DioExceptionType.sendTimeout ||
            err.type == DioExceptionType.receiveTimeout ||
            err.type == DioExceptionType.connectionError) {
          return 'Inaonekana huna intaneti. Tafadhali angalia muunganisho wako kisha jaribu tena.';
        }
        final code = err.response?.statusCode ?? 0;
        switch (code) {
          case 400:
          case 422:
            return 'Taarifa zako hazijakamilika. Tafadhali kagua na ujaribu tena.';
          case 401:
            return 'Kikao kimeisha. Tafadhali ingia tena.';
          case 403:
            return 'Huna ruhusa ya kufanya hatua hii.';
          case 404:
            return 'Huduma haikupatikana. Jaribu tena.';
          case 429:
            return 'Maombi mengi kwa sasa. Jaribu tena baadaye.';
          default:
            if (code >= 500 && code <= 599) return 'Hitilafu ya mfumo. Tafadhali jaribu tena baadaye.';
        }
      }
    } catch (_) {}
    return 'Hitilafu imetokea. Tafadhali jaribu tena.';
  }

  // Resolve the internal account UUID required by backend
  Future<String?> _resolveAccountUuid(BuildContext ctx) async {
    final user = ctx.read<AuthCubit>().state.user ?? {};
    final userId = (user['id'] ?? '').toString();

    String? uuidFromUser() {
      // Nested object form
      if (user['account'] is Map) {
        final id = (user['account']['id'] ?? '').toString();
        if (_isUuid(id)) return id;
        final id2 = (user['account']['account_id'] ?? '').toString();
        if (_isUuid(id2)) return id2;
        final id3 = (user['account']['uuid'] ?? '').toString();
        if (_isUuid(id3)) return id3;
      }
      // flat fields variants
      for (final key in ['account_id', 'accountId', 'uuid', 'accountUuid']) {
        final v = (user[key] ?? '').toString();
        if (_isUuid(v)) return v;
      }
      return null;
    }

    final direct = uuidFromUser();
    if (direct != null) return direct;

    if (userId.isEmpty) return null;

    try {
      final repo = RepositoryProvider.of<AccountRepository>(ctx);
      final acc = await repo.getByUser(userId);
      // Try common keys on the account response
      for (final key in ['id', 'account_id', 'uuid']) {
        final v = (acc?[key] ?? '').toString();
        if (_isUuid(v)) return v;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  bool _isUuid(String v) {
    if (v.isEmpty) return false;
    final re = RegExp(
        r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$');
    return re.hasMatch(v);
  }

  Future<void> _submit(BuildContext ctx) async {
    if (!_formKey.currentState!.validate()) return;

    final user = ctx.read<AuthCubit>().state.user ?? {};
    final userId = (user['id'] ?? '').toString();
    if (userId.isEmpty) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(content: Text("Hatukutambua mtumiaji. Tafadhali ingia tena.")),
      );
      return;
    }

    final accountId = await _resolveAccountUuid(ctx);
    if (!mounted) return;

    if (accountId == null || !_isUuid(accountId)) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(
          content: Text("Fungua au unganisha akaunti yako ya Selcom kwanza."),
        ),
      );
      Navigator.of(ctx).pushNamed('/');
      return;
    }

    final purposeStr = _purposeCtrl.text.trim(); // Always a string

    ctx.read<SavingsBloc>().add(SavingsCreate(
          name: _nameCtrl.text.trim(),
          goalAmount: _goalCtrl.text.trim(),
          accountId: accountId,
          durationMonths: int.parse(_durationCtrl.text.trim()),
          purpose: purposeStr,
          withdrawalCondition: _condition,
          userId: userId,
        ));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final plan = _plan();
    final daily = plan.forCadence('daily');
    final weekly = plan.forCadence('weekly');
    final monthly = plan.forCadence('monthly');

    return BlocProvider(
      create: (_) => SavingsBloc(widget.repo),
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Mpango Mpya"),
          actions: [
            IconButton(
              tooltip: "Presets",
              icon: const Icon(Icons.auto_awesome),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  showDragHandle: true,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  builder: (_) => _PresetsSheet(
                    onPick: _applyPreset,
                  ),
                );
              },
            ),
          ],
        ),
        body: BlocConsumer<SavingsBloc, SavingsState>(
          listener: (ctx, state) async {
            if (state.error != null) {
              final msg = _humanizeError(state.error!);
              ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(msg)));
            } else if (!state.creating && state.accounts.isNotEmpty) {
              if (mounted) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text("✅ Mpango umetengenezwa kikamilifu.")),
                );
                Navigator.of(ctx).pop(true);
              }
            }
          },
          builder: (ctx, state) {
            final creating = state.creating;

            return LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 640;

                return SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: wide ? 24 : 16, vertical: 16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _HeroHeader(),
                        const SizedBox(height: 16),

                        _AssistantPanel(
                          cadence: _cadence,
                          onCadenceChanged: (v) => setState(() => _cadence = v),
                          daily: daily,
                          weekly: weekly,
                          monthly: monthly,
                          highlightCondition: _condition,
                        ),
                        const SizedBox(height: 16),

                        _SectionCard(
                          title: "Taarifa za Mpango",
                          child: Column(
                            children: [
                              TextFormField(
                                controller: _nameCtrl,
                                focusNode: _nameFocus,
                                textCapitalization: TextCapitalization.sentences,
                                decoration: const InputDecoration(
                                  labelText: "Jina la mpango (mf. Ada ya shule, Dharura, Safari...)",
                                  prefixIcon: Icon(Icons.title_outlined),
                                ),
                                textInputAction: TextInputAction.next,
                                onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_goalFocus),
                                validator: (v) {
                                  final s = v?.trim() ?? '';
                                  if (s.length < 2) return "Weka jina la mpango (angalau herufi 2)";
                                  if (s.length > 120) return "Jina ni refu sana";
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _goalCtrl,
                                      focusNode: _goalFocus,
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      inputFormatters: [
                                        FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                                        DecimalTextInputFormatter(decimalRange: 2),
                                      ],
                                      decoration: const InputDecoration(
                                        labelText: "Kiasi cha lengo",
                                        prefixIcon: Icon(Icons.savings_outlined),
                                        suffixText: "TZS",
                                      ),
                                      textInputAction: TextInputAction.next,
                                      onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_durationFocus),
                                      validator: (v) {
                                        final s = v?.trim() ?? "";
                                        if (s.isEmpty) return "Weka kiasi cha lengo";
                                        final d = double.tryParse(s);
                                        if (d == null || d <= 0) return "Kiasi si sahihi";
                                        return null;
                                      },
                                    ),
                                  ),
                                  if (wide) const SizedBox(width: 12),
                                  if (wide)
                                    Expanded(
                                      child: TextFormField(
                                        controller: _durationCtrl,
                                        focusNode: _durationFocus,
                                        keyboardType: TextInputType.number,
                                        decoration: const InputDecoration(
                                          labelText: "Muda (miezi)",
                                          prefixIcon: Icon(Icons.calendar_month_outlined),
                                        ),
                                        textInputAction: TextInputAction.next,
                                        onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_purposeFocus),
                                        validator: (v) {
                                          final s = v?.trim() ?? "";
                                          if (s.isEmpty) return "Weka muda";
                                          final n = int.tryParse(s);
                                          if (n == null || n < 1) return "Chini ya mwezi 1 si ruhusa";
                                          return null;
                                        },
                                      ),
                                    ),
                                ],
                              ),
                              if (!wide) const SizedBox(height: 12),
                              if (!wide)
                                TextFormField(
                                  controller: _durationCtrl,
                                  focusNode: _durationFocus,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: "Muda (miezi)",
                                    prefixIcon: Icon(Icons.calendar_month_outlined),
                                  ),
                                  textInputAction: TextInputAction.next,
                                  onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_purposeFocus),
                                  validator: (v) {
                                    final s = v?.trim() ?? "";
                                    if (s.isEmpty) return "Weka muda";
                                    final n = int.tryParse(s);
                                    if (n == null || n < 1) return "Chini ya mwezi 1 si ruhusa";
                                    return null;
                                  },
                                ),
                              const SizedBox(height: 12),
                              _DurationSlider(
                                valueGetter: () => int.tryParse(_durationCtrl.text.trim()) ?? 1,
                                onChanged: (v) {
                                  _durationCtrl.text = v.toString();
                                  setState(() {});
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        _SectionCard(
                          title: "Masharti ya uondoaji",
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SegmentedButton<String>(
                                segments: const [
                                  ButtonSegment(value: 'amount', icon: Icon(Icons.flag_outlined), label: Text("Kiasi")),
                                  ButtonSegment(value: 'time', icon: Icon(Icons.schedule), label: Text("Muda")),
                                  ButtonSegment(value: 'both', icon: Icon(Icons.rule), label: Text("Vyote")),
                                ],
                                selected: {_condition},
                                onSelectionChanged: (s) => setState(() => _condition = s.first),
                                style: const ButtonStyle(
                                  visualDensity: VisualDensity.compact,
                                ),
                              ),
                              const SizedBox(height: 10),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 250),
                                child: Text(
                                  key: ValueKey(_condition),
                                  _condition == 'both'
                                      ? "Fedha zitachukuliwa baada ya kufikia KIASI na MUDA ulioweka."
                                      : _condition == 'time'
                                          ? "Fedha zitachukuliwa wakati MUDA umefika."
                                          : "Fedha zitachukuliwa ukishafikia KIASI cha lengo.",
                                  style: TextStyle(color: scheme.onSurfaceVariant),
                                ),
                              ),
                              const SizedBox(height: 10),
                              const _InfoBanner(
                                text: "Una saa 24 kubadili mpango huu baada ya kuunda.",
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        _SectionCard(
                          title: "Sababu ya kuokoa (hiari)",
                          child: TextFormField(
                            controller: _purposeCtrl,
                            focusNode: _purposeFocus,
                            decoration: const InputDecoration(
                              labelText: "Unaokoa kwa ajili ya nini?",
                              prefixIcon: Icon(Icons.edit_outlined),
                            ),
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _submit(ctx),
                          ),
                        ),
                        const SizedBox(height: 16),

                        _SectionCard(
                          title: "Kadirio la michango",
                          child: Column(
                            children: [
                              SegmentedButton<String>(
                                segments: const [
                                  ButtonSegment(value: 'daily', label: Text("Siku")),
                                  ButtonSegment(value: 'weekly', label: Text("Wiki")),
                                  ButtonSegment(value: 'monthly', label: Text("Mwezi")),
                                ],
                                selected: {_cadence},
                                onSelectionChanged: (s) => setState(() => _cadence = s.first),
                                style: const ButtonStyle(visualDensity: VisualDensity.compact),
                              ),
                              const SizedBox(height: 12),
                              _LiveSummary(
                                text:
                                    "Hifadhi ${_fmt(plan.forCadence(_cadence).amount)} kwa kila ${_cadence == 'daily' ? 'siku' : _cadence == 'weekly' ? 'wiki' : 'mwezi'} • "
                                    "${plan.forCadence(_cadence).deposits} michango • Jumla ${_fmt(plan.goalAmount)} ndani ya miezi ${plan.totalMonths}.",
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: creating ? null : () => _submit(ctx),
                            icon: const Icon(Icons.auto_awesome),
                            label: creating
                                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Text("Unda Mpango"),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

// Header with subtle gradient shine
class _HeroHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final brand = Theme.of(context).extension<BrandTheme>()!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        gradient: brand.headerGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.whatshot_outlined, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "Tujenge mpango wako wa akiba",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.20),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
            ),
            child: Text(
              "Smart Assist",
              style: TextStyle(color: scheme.onPrimary, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

// Dynamic assistant with three metric cards
class _AssistantPanel extends StatelessWidget {
  final String cadence;
  final void Function(String) onCadenceChanged;
  final ({double amount, int deposits}) daily;
  final ({double amount, int deposits}) weekly;
  final ({double amount, int deposits}) monthly;
  final String highlightCondition;

  const _AssistantPanel({
    required this.cadence,
    required this.onCadenceChanged,
    required this.daily,
    required this.weekly,
    required this.monthly,
    required this.highlightCondition,
  });

  @override
  Widget build(BuildContext context) {
    final isAmount = highlightCondition == 'amount';
    final isTime = highlightCondition == 'time';
    final isBoth = highlightCondition == 'both';

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: PlanMetricCard(
                label: "Kwa Siku",
                amount: daily.amount,
                deposits: daily.deposits,
                cadence: 'daily',
                highlight: cadence == 'daily' || isAmount || isBoth,
                onTap: () => onCadenceChanged('daily'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: PlanMetricCard(
                label: "Kwa Wiki",
                amount: weekly.amount,
                deposits: weekly.deposits,
                cadence: 'weekly',
                highlight: cadence == 'weekly' || isAmount || isBoth,
                onTap: () => onCadenceChanged('weekly'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: PlanMetricCard(
                label: "Kwa Mwezi",
                amount: monthly.amount,
                deposits: monthly.deposits,
                cadence: 'monthly',
                highlight: cadence == 'monthly' || isTime || isBoth,
                onTap: () => onCadenceChanged('monthly'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurface,
                )),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}

class _DurationSlider extends StatelessWidget {
  final int Function() valueGetter;
  final void Function(int) onChanged;
  const _DurationSlider({required this.valueGetter, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final v = valueGetter().clamp(1, 60);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),
        Row(
          children: [
            const Icon(Icons.tune, size: 18),
            const SizedBox(width: 8),
            Text("Rekebisha haraka muda (1–60 miezi)",
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 6,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
          ),
          child: Slider(
            min: 1,
            max: 60,
            divisions: 59,
            value: v.toDouble(),
            label: "$v mo",
            onChanged: (nv) => onChanged(nv.round()),
          ),
        ),
      ],
    );
  }
}

class _InfoBanner extends StatelessWidget {
  final String text;
  const _InfoBanner({required this.text});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.secondary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.secondary.withValues(alpha: 0.20)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lock_clock, color: scheme.secondary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: TextStyle(color: scheme.onSurface)),
          ),
        ],
      ),
    );
  }
}

class _LiveSummary extends StatelessWidget {
  final String text;
  const _LiveSummary({required this.text});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Icon(Icons.auto_graph, color: scheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: scheme.onSurface),
            ),
          ),
        ],
      ),
    );
  }
}

class _PresetsSheet extends StatelessWidget {
  final void Function({required int months, double? goal}) onPick;
  const _PresetsSheet({required this.onPick});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    Widget chip(String label, {required VoidCallback onTap}) {
      return ActionChip(
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        onPressed: () {
          Navigator.pop(context);
          onTap();
        },
        backgroundColor: scheme.primary.withValues(alpha: 0.08),
        shape: StadiumBorder(side: BorderSide(color: scheme.primary.withValues(alpha: 0.25))),
      );
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Mipangilio ya haraka", style: TextStyle(fontWeight: FontWeight.w800, color: scheme.onSurface)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                chip("Kuanza • miezi 3", onTap: () => onPick(months: 3)),
                chip("Kawaida • miezi 6", onTap: () => onPick(months: 6)),
                chip("Mwaka • miezi 12", onTap: () => onPick(months: 12)),
                chip("Lengo kubwa • miezi 24", onTap: () => onPick(months: 24, goal: 100000000)),
                chip("TZS 5,000,000 • 12 mo", onTap: () => onPick(months: 12, goal: 5000000)),
                chip("TZS 10,000,000 • 12 mo", onTap: () => onPick(months: 12, goal: 10000000)),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}