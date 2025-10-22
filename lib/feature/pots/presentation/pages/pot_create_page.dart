import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:misana_finance_app/core/format/ammount_formatter.dart';
import 'package:misana_finance_app/core/theme/app_theme.dart';

import '../../../account/domain/account_repository.dart';
import '../../../account/presentation/bloc/account_bloc.dart';
import '../../../account/presentation/bloc/account_event.dart';
import '../../../account/presentation/bloc/account_state.dart';
import '../../../session/auth_cubit.dart';
import '../../domain/pots_repository.dart';
import '../bloc/pots_bloc.dart';
import '../bloc/pots_event.dart';
import '../bloc/pots_state.dart';
import '../utils/savings_plan.dart';

class PotCreatePage extends StatefulWidget {
  final PotsRepository repo;
  const PotCreatePage({super.key, required this.repo});

  @override
  State<PotCreatePage> createState() => _PotCreatePageState();
}

class _PotCreatePageState extends State<PotCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _goalCtrl = TextEditingController();
  final _monthsCtrl = TextEditingController(text: '6');
  final _purposeCtrl = TextEditingController();

  String _condition = 'amount';
  String _cadence = 'monthly';

  @override
  void dispose() {
    _nameCtrl.dispose();
    _goalCtrl.dispose();
    _monthsCtrl.dispose();
    _purposeCtrl.dispose();
    super.dispose();
  }

  bool _isUuid(String v) {
    if (v.isEmpty) return false;
    final re = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$');
    return re.hasMatch(v);
  }

  Future<String?> _resolveAccountUuid(BuildContext ctx, Map<String, dynamic>? acc) async {
    // 1) Prefer the AccountBloc-provided account map
    if (acc != null) {
      for (final k in ['id', 'account_id', 'uuid']) {
        final v = (acc[k] ?? '').toString();
        if (_isUuid(v)) return v;
      }
    }

    // 2) Fallback: fetch from account-service by userId
    final userId = (ctx.read<AuthCubit>().state.user?['id'] ?? '').toString();
    if (userId.isEmpty) return null;

    try {
      final repo = RepositoryProvider.of<AccountRepository>(ctx);
      final m = await repo.getByUser(userId);
      for (final k in ['id', 'account_id', 'uuid']) {
        final v = (m?[k] ?? '').toString();
        if (_isUuid(v)) return v;
      }
    } catch (_) {}
    return null;
  }

  Future<void> _submit(BuildContext ctx, Map<String, dynamic>? account) async {
    if (!_formKey.currentState!.validate()) return;

    final userId = (ctx.read<AuthCubit>().state.user?['id'] ?? '').toString();
    if (userId.isEmpty) {
      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text("Tafadhali ingia tena")));
      return;
    }

    // Resolve INTERNAL UUID (not external_account_id)
    final accountUuid = await _resolveAccountUuid(ctx, account);
    if (!mounted) return;
    if (accountUuid == null || !_isUuid(accountUuid)) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(content: Text("Akaunti haijapatikana. Fungua/unganisha akaunti ya Selcom kisha jaribu tena.")),
      );
      return;
    }

    final goal = double.tryParse(_goalCtrl.text.trim()) ?? 0.0;
    final months = int.tryParse(_monthsCtrl.text.trim()) ?? 0;

    ctx.read<PotsBloc>().add(PotCreate(
          name: _nameCtrl.text.trim(),
          goalAmount: goal,
          purpose: _purposeCtrl.text.trim().isEmpty ? '' : _purposeCtrl.text.trim(), // send string
          accountId: accountUuid,                   // INTERNAL UUID here
          withdrawalCondition: _condition,
          durationMonths: months,
          userId: userId,
        ));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final goal = double.tryParse(_goalCtrl.text.trim()) ?? 0.0;
    final months = int.tryParse(_monthsCtrl.text.trim()) ?? 0;
    final plan = SavingsPlan(goalAmount: goal, durationMonths: months);
    final cadence = _cadence;
    final per = plan.forCadence(cadence);

    return MultiRepositoryProvider(
      providers: [
        // Make sure AccountRepository is available for _resolveAccountUuid fallback
        RepositoryProvider.value(value: RepositoryProvider.of<AccountRepository>(context)),
      ],
      child: BlocProvider(
        create: (_) => PotsBloc(widget.repo),
        child: Scaffold(
          appBar: AppBar(title: const Text("Mpango Mpya")),
          body: BlocConsumer<PotsBloc, PotsState>(
            listener: (ctx, state) {
              if (state.error != null) {
                ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text("Hitilafu: ${state.error}")));
              } else if (!state.creating && state.pots.isNotEmpty) {
                Navigator.pop(ctx, true);
              }
            },
            builder: (ctx, state) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: BlocProvider(
                  create: (_) => AccountBloc(RepositoryProvider.of(context))..add(AccountEnsure()),
                  child: BlocBuilder<AccountBloc, AccountState>(
                    builder: (aCtx, aState) {
                      final acc = aState.account;
                      final ensuring = aState.loading;

                      // Try to detect internal UUID in the current account state
                      final internalId = (() {
                        if (acc == null) return '';
                        for (final k in ['id', 'account_id', 'uuid']) {
                          final v = (acc[k] ?? '').toString();
                          if (_isUuid(v)) return v;
                        }
                        return '';
                      })();

                      final readyToCreate = !state.creating && !ensuring && internalId.isNotEmpty;

                      return SingleChildScrollView(
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              _MagicHeader(cadence: cadence, perAmount: per.amount),
                              const SizedBox(height: 16),
                              _Section(
                                title: "Maelezo",
                                child: Column(
                                  children: [
                                    TextFormField(
                                      controller: _nameCtrl,
                                      textCapitalization: TextCapitalization.sentences,
                                      decoration: const InputDecoration(
                                        labelText: "Jina la mpango (mf. Elimu, Dharura...)",
                                        prefixIcon: Icon(Icons.edit_outlined),
                                      ),
                                      validator: (v) => (v == null || v.trim().length < 2) ? "Weka jina sahihi" : null,
                                    ),
                                    const SizedBox(height: 12),
                                    TextFormField(
                                      controller: _goalCtrl,
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      inputFormatters: [
                                        FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                                      ],
                                      decoration: const InputDecoration(
                                        labelText: "Lengo (TZS)",
                                        prefixIcon: Icon(Icons.savings_outlined),
                                        suffixText: "TZS",
                                      ),
                                      validator: (v) {
                                        final d = double.tryParse(v ?? '');
                                        if (d == null || d <= 0) return "Weka kiasi sahihi";
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 12),
                                    TextFormField(
                                      controller: _monthsCtrl,
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                        labelText: "Muda (miezi, min 1)",
                                        prefixIcon: Icon(Icons.calendar_month_outlined),
                                      ),
                                      validator: (v) {
                                        final n = int.tryParse(v ?? '');
                                        if (n == null || n < 1) return "Angalau mwezi 1";
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 12),
                                    TextFormField(
                                      controller: _purposeCtrl,
                                      decoration: const InputDecoration(
                                        labelText: "Kusudi (hiari)",
                                        prefixIcon: Icon(Icons.flag_outlined),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              _Section(
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
                                      style: const ButtonStyle(visualDensity: VisualDensity.compact),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _condition == 'both'
                                          ? "Fedha zitachukuliwa wakati KIASI na MUDA vimefikiwa."
                                          : _condition == 'time'
                                              ? "Fedha zitachukuliwa wakati MUDA umefika."
                                              : "Fedha zitachukuliwa wakati KIASI kimefikiwa.",
                                      style: TextStyle(color: scheme.onSurfaceVariant),
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: scheme.secondary.withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: scheme.secondary.withOpacity(0.2)),
                                      ),
                                      child: const Text("Una saa 24 kubadili mpango huu baada ya kuunda."),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              _Section(
                                title: "Kadirio la michango",
                                child: Column(
                                  children: [
                                    _CadenceSelector(
                                      cadence: _cadence,
                                      onChanged: (v) => setState(() => _cadence = v),
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        Expanded(child: _EstimateCard(title: "Kwa Siku", value: plan.perDay)),
                                        const SizedBox(width: 10),
                                        Expanded(child: _EstimateCard(title: "Kwa Wiki", value: plan.perWeek)),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        Expanded(child: _EstimateCard(title: "Kwa Mwezi", value: plan.perMonth)),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: _Summary(goal: goal, months: months),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 18),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: readyToCreate ? () => _submit(ctx, acc) : null,
                                  icon: const Icon(Icons.auto_awesome),
                                  label: (state.creating || ensuring)
                                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                      : const Text("Unda Mpango"),
                                ),
                              ),
                              if (!readyToCreate) ...[
                                const SizedBox(height: 8),
                                const Text("Inahakikisha akaunti yako ya Selcom..."),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _MagicHeader extends StatelessWidget {
  final String cadence;
  final double perAmount;
  const _MagicHeader({required this.cadence, required this.perAmount});

  @override
  Widget build(BuildContext context) {
    final brand = Theme.of(context).extension<BrandTheme>()!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(gradient: brand.headerGradient, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          const Icon(Icons.whatshot_outlined, color: Colors.white),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "Ukihifadhi ${AmountFormatter.money(perAmount)} ${cadence == 'daily' ? 'kwa siku' : cadence == 'weekly' ? 'kwa wiki' : 'kwa mwezi'}, utatimiza lengo lako kwa wakati.",
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          child,
        ]),
      ),
    );
  }
}

class _CadenceSelector extends StatelessWidget {
  final String cadence;
  final void Function(String) onChanged;
  const _CadenceSelector({required this.cadence, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<String>(
      segments: const [
        ButtonSegment(value: 'daily', label: Text("Siku")),
        ButtonSegment(value: 'weekly', label: Text("Wiki")),
        ButtonSegment(value: 'monthly', label: Text("Mwezi")),
      ],
      selected: {cadence},
      onSelectionChanged: (s) => onChanged(s.first),
    );
  }
}

class _EstimateCard extends StatelessWidget {
  final String title;
  final double value;
  const _EstimateCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(AmountFormatter.money(value), style: TextStyle(color: scheme.onSurface, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  final double goal;
  final int months;
  const _Summary({required this.goal, required this.months});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Muhtasari", style: TextStyle(fontWeight: FontWeight.w800, color: scheme.onSurface)),
            const SizedBox(height: 6),
            Text("Lengo: ${AmountFormatter.money(goal)}"),
            Text("Muda: miezi $months"),
          ],
        ),
      ),
    );
  }
}