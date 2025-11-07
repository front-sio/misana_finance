// lib/feature/pots/presentation/pages/pot_create_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:misana_finance_app/core/format/ammount_formatter.dart';
import 'package:misana_finance_app/core/theme/app_theme.dart';
import 'package:misana_finance_app/core/utils/message_mapper.dart';

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

class _PotCreatePageState extends State<PotCreatePage> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _goalCtrl = TextEditingController();
  final _purposeCtrl = TextEditingController();

  String _condition = 'amount';
  String _cadence = 'monthly';

  DateTime? _startDate;
  DateTime? _endDate;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  static const _strings = {
    'title': {'en': 'Create New Plan', 'sw': 'Unda Mpango Mpya'},
    'plan_details': {'en': 'Plan Details', 'sw': 'Maelezo ya Mpango'},
    'plan_name': {'en': 'Plan name', 'sw': 'Jina la mpango'},
    'plan_name_hint': {'en': 'E.g. Education, Emergency, Vacation', 'sw': 'Mf. Elimu, Dharura, Likizo'},
    'plan_name_error': {'en': 'Name must be at least 2 characters', 'sw': 'Jina liwe na herufi angalau 2'},
    'goal_amount': {'en': 'Goal Amount (TZS)', 'sw': 'Lengo (TZS)'},
    'goal_amount_hint': {'en': '0.00', 'sw': '0.00'},
    'goal_amount_error': {'en': 'Enter a positive amount', 'sw': 'Ingiza kiasi chanya'},
    'purpose': {'en': 'Purpose (optional)', 'sw': 'Kusudi (hiari)'},
    'purpose_hint': {'en': 'Why are you saving this money?', 'sw': 'Kwa nini unakusudilia pesa hii?'},
    'time_limit': {'en': 'Time Limit', 'sw': 'Ukomo wa Muda'},
    'select_dates': {'en': 'Select start and end dates', 'sw': 'Chagua tarehe za kuanzia na kumalizia'},
    'select_dates_prompt': {'en': 'Choose dates to distribute contributions over time', 'sw': 'Chagua tarehe ili kusambaza michango kwa muda unaolingana'},
    'total_days': {'en': 'Total: {days} days ({months})', 'sw': 'Jumla: {days} siku ({months})'},
    'withdrawal_conditions': {'en': 'Withdrawal Conditions', 'sw': 'Masharti ya Uondoaji'},
    'amount_only': {'en': 'Amount Only', 'sw': 'Kiasi tu'},
    'time_only': {'en': 'Time Only', 'sw': 'Muda tu'},
    'amount_and_time': {'en': 'Amount & Time', 'sw': 'Kiasi & Muda'},
    'condition_both': {'en': 'Funds will be withdrawn after BOTH amount and time are reached.', 'sw': 'Fedha zitachukuliwa baada ya KIASI na MUDA vimefikiwa.'},
    'condition_time': {'en': 'Funds will be withdrawn after TIME is reached.', 'sw': 'Fedha zitachukuliwa baada ya MUDA umefika.'},
    'condition_amount': {'en': 'Funds will be withdrawn after AMOUNT is reached.', 'sw': 'Fedha zitachukuliwa baada ya KIASI kimefikiwa.'},
    'edit_window': {'en': 'You can modify this plan within 24 hours after creation.', 'sw': 'Unaweza kubadili mpango huu ndani ya saa 24 tu baada ya kuunda.'},
    'day': {'en': 'Day', 'sw': 'Siku'},
    'week': {'en': 'Week', 'sw': 'Wiki'},
    'month': {'en': 'Month', 'sw': 'Mwezi'},
    'per_day': {'en': 'per day', 'sw': 'kwa siku'},
    'per_week': {'en': 'per week', 'sw': 'kwa wiki'},
    'per_month': {'en': 'per month', 'sw': 'kwa mwezi'},
    'contribution_estimate': {'en': 'Your Contribution Estimate', 'sw': 'Kadirio lako la Michango'},
    'goal': {'en': 'Goal', 'sw': 'Lengo'},
    'duration': {'en': 'Duration', 'sw': 'Muda'},
    'days': {'en': 'days', 'sw': 'siku'},
    'create_button': {'en': 'Create Plan', 'sw': 'Unda Mpango'},
    'saving': {'en': 'Saving...', 'sw': 'Inahifadhi...'},
    'verifying_account': {'en': 'Verifying your account...', 'sw': 'Inahakikisha akaunti yako...'},
    'select_dates_required': {'en': 'Please select start and end dates', 'sw': 'Tafadhali chagua tarehe za mwanzo na mwisho'},
    'account_not_found': {'en': 'Account not found. Please try again.', 'sw': 'Akaunti yako haipatikani. Tafadhali jaribu tena.'},
    'min_duration': {'en': 'Duration must be at least 1 day', 'sw': 'Muda lazima uwe angalau siku 1'},
    'account_error': {'en': 'Account Error: {error}', 'sw': 'Tatizo la Akaunti: {error}'},
    'retry': {'en': 'Retry', 'sw': 'Jaribu Tena'},
    'month_1': {'en': '1 month', 'sw': 'mwezi 1'},
    'months_n': {'en': '{n} months', 'sw': 'miezi {n}'},
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
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.02),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic),
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _goalCtrl.dispose();
    _purposeCtrl.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  bool _isUuid(String v) {
    if (v.isEmpty) return false;
    final re = RegExp(
        r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$');
    return re.hasMatch(v);
  }

  String? _extractAccountId(Map<String, dynamic>? acc) {
    if (acc == null) return null;
    for (final k in ['id', 'account_id', 'uuid']) {
      final v = (acc[k] ?? '').toString();
      if (_isUuid(v)) return v;
    }
    return null;
  }

  int _calculateTotalDays() {
    if (_startDate == null || _endDate == null) return 0;
    return _endDate!.difference(_startDate!).inDays;
  }

  int _calculateMonthsDuration() {
    if (_startDate == null || _endDate == null) return 1;

    final start = _startDate!;
    final end = _endDate!;

    int months = (end.year - start.year) * 12 + (end.month - start.month);

    DateTime tempDate = DateTime(start.year, start.month + months, start.day);
    if (tempDate.isAfter(end)) {
      months--;
    }

    return months < 1 ? 1 : months;
  }

  String _formatDurationText() {
    if (_startDate == null || _endDate == null) return '0 ${_t('days')}';

    final totalDays = _calculateTotalDays();
    final months = _calculateMonthsDuration();
    final remainingDays = totalDays - (months * 30);

    if (months == 0) return '$totalDays ${_t('days')}';

    if (remainingDays <= 0) {
      if (months == 1) return _t('month_1');
      return _t('months_n', params: {'n': months.toString()});
    }

    final monthText = months == 1 ? _t('month_1') : _t('months_n', params: {'n': months.toString()});
    return '$monthText, $remainingDays ${_t('days')} ($totalDays ${_t('days')} jumla)';
  }

  String _formatMagicHeaderDuration(int months) {
    if (months == 1) return _t('month_1');
    return _t('months_n', params: {'n': months.toString()});
  }

  Future<void> _selectDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 3650)),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme,
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  void _showErrorFeedback(String message) {
    final brand = Theme.of(context).extension<BrandTheme>()!;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: brand.errorColor,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _submit(BuildContext ctx, Map<String, dynamic>? account) async {
    if (!_formKey.currentState!.validate()) return;

    if (_startDate == null || _endDate == null) {
      _showErrorFeedback(_t('select_dates_required'));
      return;
    }

    final userId = (ctx.read<AuthCubit>().state.user?['id'] ?? '').toString();
    if (userId.isEmpty) {
      _showErrorFeedback(MessageMapper.getPotsFriendlyError('unauthorized'));
      return;
    }

    final accountId = _extractAccountId(account);
    if (accountId == null) {
      _showErrorFeedback(_t('account_not_found'));
      return;
    }

    final goal = double.tryParse(_goalCtrl.text.trim()) ?? 0.0;
    final months = _calculateMonthsDuration();
    final totalDays = _calculateTotalDays();

    if (totalDays < 1) {
      _showErrorFeedback(_t('min_duration'));
      return;
    }

    ctx.read<PotsBloc>().add(PotCreate(
          name: _nameCtrl.text.trim(),
          goalAmount: goal,
          purpose: _purposeCtrl.text.trim(),
          accountId: accountId,
          withdrawalCondition: _condition,
          durationMonths: months,
          startDate: _startDate!,
          endDate: _endDate!,
          userId: userId,
        ));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;
    final padding = isSmallScreen ? 16.0 : 24.0;

    final goal = double.tryParse(_goalCtrl.text.trim()) ?? 0.0;
    final months = _calculateMonthsDuration();
    final totalDays = _calculateTotalDays();
    final plan = SavingsPlan(goalAmount: goal, durationMonths: months);
    final per = plan.forCadence(_cadence);

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: RepositoryProvider.of<AccountRepository>(context)),
      ],
      child: BlocProvider(
        create: (_) => PotsBloc(widget.repo),
        child: Scaffold(
          backgroundColor: scheme.surface,
          appBar: AppBar(
            title: Text(_t('title')),
            elevation: 0,
            scrolledUnderElevation: 2,
            shadowColor: scheme.scrim.withValues(alpha: 0.1),
            centerTitle: true,
          ),
          body: BlocConsumer<PotsBloc, PotsState>(
            listener: (ctx, state) {
              if (state is PotError) {
                _showErrorFeedback(MessageMapper.getPotsFriendlyError(state.error));
              } else if (state is PotActionSuccess) {
                Navigator.pop(ctx, true);
              }
            },
            builder: (ctx, state) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: BlocProvider(
                    create: (_) => AccountBloc(RepositoryProvider.of(context))..add(AccountEnsure()),
                    child: BlocBuilder<AccountBloc, AccountState>(
                      builder: (aCtx, aState) {
                        final acc = aState.account;
                        final ensuring = aState.loading;
                        final accountError = aState.error;
                        final accountId = _extractAccountId(acc);

                        final isCreating = state is PotLoading;
                        final readyToCreate = !isCreating && !ensuring && accountId != null && accountError == null;

                        return SingleChildScrollView(
                          padding: EdgeInsets.all(padding),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (accountError != null) ...[
                                  _buildErrorBanner(
                                    _t('account_error', params: {'error': MessageMapper.getAccountFriendlyError(accountError)}),
                                    onRetry: () => aCtx.read<AccountBloc>().add(AccountEnsure()),
                                  ),
                                  const SizedBox(height: 20),
                                ],
                                _AnimatedSection(
                                  delay: 0,
                                  child: _Section(
                                    title: _t('plan_details'),
                                    icon: Icons.edit_note_rounded,
                                    child: Column(
                                      children: [
                                        _buildTextField(
                                          controller: _nameCtrl,
                                          label: _t('plan_name'),
                                          hint: _t('plan_name_hint'),
                                          icon: Icons.label_outline,
                                          validator: (v) => (v == null || v.trim().length < 2) ? _t('plan_name_error') : null,
                                        ),
                                        const SizedBox(height: 16),
                                        _buildTextField(
                                          controller: _goalCtrl,
                                          label: _t('goal_amount'),
                                          hint: _t('goal_amount_hint'),
                                          icon: Icons.savings_outlined,
                                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                          inputFormatters: [
                                            FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                                          ],
                                          suffixText: "TZS",
                                          validator: (v) {
                                            final d = double.tryParse(v ?? '');
                                            if (d == null || d <= 0) return _t('goal_amount_error');
                                            return null;
                                          },
                                        ),
                                        const SizedBox(height: 16),
                                        _buildTextField(
                                          controller: _purposeCtrl,
                                          label: _t('purpose'),
                                          hint: _t('purpose_hint'),
                                          icon: Icons.flag_outlined,
                                          maxLines: 2,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                _AnimatedSection(
                                  delay: 1,
                                  child: _Section(
                                    title: _t('time_limit'),
                                    icon: Icons.calendar_month_outlined,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _buildDateSelector(),
                                        if (_startDate != null && _endDate != null) ...[
                                          const SizedBox(height: 12),
                                          _buildInfoBox(
                                            _t('total_days', params: {
                                              'days': totalDays.toString(),
                                              'months': _formatMagicHeaderDuration(months)
                                            }),
                                            scheme.primary,
                                            icon: Icons.event_available_rounded,
                                          ),
                                        ],
                                        if (_startDate == null) ...[
                                          const SizedBox(height: 12),
                                          _buildInfoBox(
                                            _t('select_dates_prompt'),
                                            BrandColors.orange,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                _AnimatedSection(
                                  delay: 2,
                                  child: _Section(
                                    title: _t('withdrawal_conditions'),
                                    icon: Icons.rule_rounded,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        SingleChildScrollView(
                                          scrollDirection: Axis.horizontal,
                                          child: Row(
                                            children: [
                                              _ConditionButton(
                                                label: _t('amount_only'),
                                                value: 'amount',
                                                isSelected: _condition == 'amount',
                                                onTap: () => setState(() => _condition = 'amount'),
                                              ),
                                              const SizedBox(width: 10),
                                              _ConditionButton(
                                                label: _t('time_only'),
                                                value: 'time',
                                                isSelected: _condition == 'time',
                                                onTap: () => setState(() => _condition = 'time'),
                                              ),
                                              const SizedBox(width: 10),
                                              _ConditionButton(
                                                label: _t('amount_and_time'),
                                                value: 'both',
                                                isSelected: _condition == 'both',
                                                onTap: () => setState(() => _condition = 'both'),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        _buildInfoBox(
                                          _condition == 'both'
                                              ? _t('condition_both')
                                              : _condition == 'time'
                                                  ? _t('condition_time')
                                                  : _t('condition_amount'),
                                          BrandColors.orange,
                                        ),
                                        const SizedBox(height: 12),
                                        _buildInfoBox(
                                          _t('edit_window'),
                                          scheme.secondary,
                                          icon: Icons.schedule_rounded,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                _AnimatedSection(
                                  delay: 3,
                                  child: Center(
                                    child: SegmentedButton<String>(
                                      segments: [
                                        ButtonSegment(
                                          value: 'daily',
                                          icon: const Icon(Icons.calendar_view_day, size: 18),
                                          label: Text(_t('day'), style: const TextStyle(fontSize: 13)),
                                        ),
                                        ButtonSegment(
                                          value: 'weekly',
                                          icon: const Icon(Icons.date_range, size: 18),
                                          label: Text(_t('week'), style: const TextStyle(fontSize: 13)),
                                        ),
                                        ButtonSegment(
                                          value: 'monthly',
                                          icon: const Icon(Icons.calendar_month, size: 18),
                                          label: Text(_t('month'), style: const TextStyle(fontSize: 13)),
                                        ),
                                      ],
                                      selected: {_cadence},
                                      onSelectionChanged: (s) => setState(() => _cadence = s.first),
                                      style: const ButtonStyle(visualDensity: VisualDensity.compact),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                _AnimatedSection(
                                  delay: 4,
                                  child: _MagicHeader(
                                    cadence: _cadence,
                                    perAmount: per.amount,
                                    goal: goal,
                                    months: months,
                                    totalDays: totalDays,
                                    formatDuration: _formatMagicHeaderDuration,
                                    t: _t,
                                  ),
                                ),
                                const SizedBox(height: 32),
                                _AnimatedSection(
                                  delay: 5,
                                  child: SizedBox(
                                    width: double.infinity,
                                    height: 52,
                                    child: ElevatedButton.icon(
                                      onPressed: readyToCreate ? () => _submit(ctx, acc) : null,
                                      icon: isCreating
                                          ? SizedBox(
                                              height: 20,
                                              width: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2.5,
                                                valueColor: AlwaysStoppedAnimation(scheme.onPrimary),
                                              ),
                                            )
                                          : const Icon(Icons.auto_awesome_rounded),
                                      label: Text(
                                        isCreating ? _t('saving') : _t('create_button'),
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                if (!readyToCreate && accountError == null) ...[
                                  const SizedBox(height: 16),
                                  _AnimatedSection(
                                    delay: 6,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          height: 16,
                                          width: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation(BrandColors.orange),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          _t('verifying_account'),
                                          style: TextStyle(
                                            color: scheme.onSurfaceVariant,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 24),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildErrorBanner(String message, {VoidCallback? onRetry}) {
    final brand = Theme.of(context).extension<BrandTheme>()!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: brand.errorColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: brand.errorColor.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.error_outline_rounded, color: brand.errorColor, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    color: brand.errorColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(_t('retry')),
                style: OutlinedButton.styleFrom(
                  foregroundColor: brand.errorColor,
                  side: BorderSide(color: brand.errorColor.withValues(alpha: 0.5)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? suffixText,
    int maxLines = 1,
  }) {
    final scheme = Theme.of(context).colorScheme;

    return TextFormField(
      controller: controller,
      textCapitalization: TextCapitalization.sentences,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLines: maxLines,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
        suffixText: suffixText,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: scheme.outline.withValues(alpha: 0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: BrandColors.orange, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      validator: validator,
    );
  }

  Widget _buildDateSelector() {
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: _selectDateRange,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: scheme.outline.withValues(alpha: 0.3),
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, color: BrandColors.orange, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _startDate != null && _endDate != null
                        ? "${DateFormat('dd MMM yyyy').format(_startDate!)} - ${DateFormat('dd MMM yyyy').format(_endDate!)}"
                        : _t('select_dates'),
                    style: TextStyle(
                      color: _startDate != null ? scheme.onSurface : scheme.onSurfaceVariant,
                      fontWeight: _startDate != null ? FontWeight.w600 : FontWeight.normal,
                      fontSize: 14,
                    ),
                  ),
                  if (_startDate != null && _endDate != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        _formatDurationText(),
                        style: const TextStyle(
                          color: BrandColors.orange,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: BrandColors.orange),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBox(String text, Color color, {IconData icon = Icons.info_rounded}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedSection extends StatelessWidget {
  final int delay;
  final Widget child;

  const _AnimatedSection({required this.delay, required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 500 + (delay * 80)),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 15),
            child: child,
          ),
        );
      },
    );
  }
}

class _ConditionButton extends StatelessWidget {
  final String label;
  final String value;
  final bool isSelected;
  final VoidCallback onTap;

  const _ConditionButton({
    required this.label,
    required this.value,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: [BrandColors.orange, BrandColors.orange.withValues(alpha: 0.8)],
                  )
                : null,
            color: isSelected ? null : Colors.transparent,
            border: Border.all(
              color: isSelected ? BrandColors.orange : Colors.grey.withValues(alpha: 0.3),
              width: isSelected ? 2 : 1.5,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey[700],
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

class _MagicHeader extends StatelessWidget {
  final String cadence;
  final double perAmount;
  final double goal;
  final int months;
  final int totalDays;
  final Function(int) formatDuration;
  final String Function(String, {Map<String, String>? params}) t;

  const _MagicHeader({
    required this.cadence,
    required this.perAmount,
    required this.goal,
    required this.months,
    required this.totalDays,
    required this.formatDuration,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    String cadenceText = cadence == 'daily' 
        ? t('per_day') 
        : cadence == 'weekly' 
            ? t('per_week') 
            : t('per_month');

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            BrandColors.orange.withValues(alpha: 0.12),
            BrandColors.orange.withValues(alpha: 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: BrandColors.orange.withValues(alpha: 0.25), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [BrandColors.orange, BrandColors.orange.withValues(alpha: 0.7)],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.trending_up_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t('contribution_estimate'),
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 300),
                      style: const TextStyle(
                        color: BrandColors.orange,
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                      ),
                      child: Text(
                        "${AmountFormatter.money(perAmount)} $cadenceText",
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            height: 1,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  BrandColors.orange.withValues(alpha: 0.3),
                  BrandColors.orange.withValues(alpha: 0.05),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildStat(t('goal'), AmountFormatter.money(goal)),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _buildStat(t('duration'), "$totalDays ${t('days')}"),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[700],
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: BrandColors.orange,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Widget child;

  const _Section({required this.title, required this.child, this.icon});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 1,
      shadowColor: scheme.scrim.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null)
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: BrandColors.orange.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: BrandColors.orange, size: 20),
                  ),
                if (icon != null) const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            child,
          ],
        ),
      ),
    );
  }
}