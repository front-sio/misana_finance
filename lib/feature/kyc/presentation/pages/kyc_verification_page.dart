import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/storage/token_storage.dart';
import '../../../../core/utils/jwt_utils.dart';
import '../../../session/auth_cubit.dart';
import '../bloc/kyc_bloc.dart';
import '../bloc/kyc_event.dart';
import '../bloc/kyc_state.dart';

class KycVerificationPage extends StatefulWidget {
  const KycVerificationPage({super.key});

  @override
  State<KycVerificationPage> createState() => _KycVerificationPageState();
}

class _KycVerificationPageState extends State<KycVerificationPage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameCtrl = TextEditingController();
  final _nidCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _dobCtrl = TextEditingController();

  DateTime? _dob;

  String _userId = '';
  bool _resolving = true;
  bool _loadedForUser = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _resolveUserIdAndLoad());
  }

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _nidCtrl.dispose();
    _addressCtrl.dispose();
    _dobCtrl.dispose();
    super.dispose();
  }

  String _fmtDob(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  Future<String?> _getUserIdOrWait({Duration timeout = const Duration(seconds: 8)}) async {
    final auth = context.read<AuthCubit>();
    final current = (auth.state.user?['id'] ?? '').toString();
    if (current.isNotEmpty) return current;

    try {
      final st = await auth.stream
          .firstWhere((s) {
            final id = (s.user?['id'] ?? '').toString();
            return id.isNotEmpty || (s.authenticated == false);
          })
          .timeout(timeout);
      final id = (st.user?['id'] ?? '').toString();
      return id.isNotEmpty ? id : null;
    } on TimeoutException {
      return null;
    }
  }

  Future<String?> _getUserIdFromToken() async {
    final storage = TokenStorage();
    final token = await storage.getAccessToken();
    return JwtUtils.getSub(token);
  }

  Future<void> _resolveUserIdAndLoad() async {
    setState(() => _resolving = true);

    String? uid = (context.read<AuthCubit>().state.user?['id'] ?? '').toString();
    if (uid.isEmpty) {
      try {
        await context.read<AuthCubit>().refreshProfile();
      } catch (_) {}
      uid = await _getUserIdOrWait();
    }
    if ((uid ?? '').isEmpty) {
      uid = await _getUserIdFromToken();
    }

    if (!mounted) return;
    setState(() {
      _userId = uid ?? '';
      _resolving = false;
      _loadedForUser = false;
    });

    _maybeDispatchLoad();
  }

  void _maybeDispatchLoad() {
    if (!mounted) return;
    if (_userId.isEmpty || _loadedForUser) return;
    context.read<KycBloc>().add(KycLoadStatus(userId: _userId));
    _loadedForUser = true;
  }

  // Friendly DOB picker (bottom sheet with iOS-style wheels + quick chips)
  Future<void> _openDobBottomSheet() async {
    final now = DateTime.now();
    final minDate = DateTime(1900, 1, 1);
    final maxDate = DateTime(now.year, now.month, now.day);
    final initial = _dob ?? DateTime(now.year - 18, now.month, now.day);
    DateTime temp = initial.isAfter(maxDate) ? maxDate : initial;

    final result = await showModalBottomSheet<DateTime>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final scheme = Theme.of(ctx).colorScheme;
        final media = MediaQuery.of(ctx);
        final height = media.size.height * 0.55;

        return SizedBox(
          height: height,
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                decoration: BoxDecoration(
                  color: scheme.surface,
                  border: Border(
                    bottom: BorderSide(color: scheme.outlineVariant),
                  ),
                ),
                child: Row(
                  children: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Ghairi')),
                    const SizedBox(width: 8),
                    // Chips take remaining space and scroll if needed
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _QuickChip(
                              label: '≥18',
                              onTap: () {
                                temp = DateTime(now.year - 18, now.month, now.day);
                                (ctx as Element).markNeedsBuild();
                              },
                            ),
                            const SizedBox(width: 6),
                            _QuickChip(
                              label: '≥25',
                              onTap: () {
                                temp = DateTime(now.year - 25, now.month, now.day);
                                (ctx as Element).markNeedsBuild();
                              },
                            ),
                            const SizedBox(width: 6),
                            _QuickChip(
                              label: '≥30',
                              onTap: () {
                                temp = DateTime(now.year - 30, now.month, now.day);
                                (ctx as Element).markNeedsBuild();
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Compact action button (overrides theme so it doesn't expand infinitely)
                    _CompactButton(
                      label: 'Chagua',
                      onPressed: () => Navigator.pop(ctx, temp),
                    ),
                  ],
                ),
              ),
              // Date wheel
              Expanded(
                child: CupertinoTheme(
                  data: CupertinoThemeData(
                    textTheme: CupertinoTextThemeData(
                      dateTimePickerTextStyle: TextStyle(
                        color: scheme.onSurface,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.date,
                    minimumDate: minDate,
                    maximumDate: maxDate,
                    initialDateTime: temp,
                    onDateTimeChanged: (d) => temp = d,
                  ),
                ),
              ),
              // Hint
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: scheme.onSurfaceVariant),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Tumia gurudumu kuchagua tarehe kwa urahisi.',
                        style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );

    if (result != null) {
      setState(() {
        _dob = result;
        _dobCtrl.text = _fmtDob(result);
      });
    }
  }

  void _submit() {
    if (_userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Hatukupata User ID. Tafadhali ingia tena.")),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    if (_dob == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Chagua Tarehe ya Kuzaliwa")),
      );
      return;
    }
    final dobStr = _fmtDob(_dob!);

    context.read<KycBloc>().add(
          KycSubmit(
            userId: _userId,
            documentType: 'national_id',
            documentNumber: _nidCtrl.text.trim(),
            fullName: _fullNameCtrl.text.trim(),
            dateOfBirth: dobStr,
            address: _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, dynamic>(
      listenWhen: (prev, curr) => prev.user != curr.user,
      listener: (_, s) {
        final id = (s.user?['id'] ?? '').toString();
        if (id.isNotEmpty) {
          setState(() {
            _userId = id;
            _resolving = false;
            _loadedForUser = false;
          });
          _maybeDispatchLoad();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Uthibitisho wa Utambulisho"),
          centerTitle: true,
        ),
        body: BlocConsumer<KycBloc, KycState>(
          listener: (context, state) async {
            if (state.error != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("❌ ${state.error}")),
              );
            }
            if (!state.submitting && state.isVerified) {
              await context.read<AuthCubit>().refreshProfile();
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("✅ Uthibitisho umekamilika!")),
              );
              Navigator.of(context).pop();
            }
          },
          builder: (context, state) {
            final loading = state.loading || _resolving;
            final submitting = state.submitting;

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _StatusCard(
                    status: state.status,
                    latest: state.history.isNotEmpty ? state.history.first : null,
                    missingUserId: !_resolving && _userId.isEmpty,
                  ),
                  const SizedBox(height: 16),

                  AbsorbPointer(
                    absorbing: _userId.isEmpty,
                    child: Opacity(
                      opacity: _userId.isEmpty ? 0.5 : 1,
                      child: Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                TextFormField(
                                  controller: _fullNameCtrl,
                                  textCapitalization: TextCapitalization.words,
                                  decoration: const InputDecoration(
                                    labelText: "Majina kamili (kama yalivyo kwenye kitambulisho)",
                                    prefixIcon: Icon(Icons.badge_outlined),
                                  ),
                                  validator: (v) =>
                                      (v == null || v.trim().length < 2) ? "Weka majina kamili" : null,
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _nidCtrl,
                                  keyboardType: TextInputType.number,
                                  maxLength: 20,
                                  decoration: const InputDecoration(
                                    labelText: "Namba ya NIDA (NIN)",
                                    prefixIcon: Icon(Icons.perm_identity),
                                    counterText: "",
                                  ),
                                  validator: (v) {
                                    final value = v?.trim() ?? '';
                                    if (value.isEmpty) return "Weka namba ya NIDA";
                                    if (value.length < 10) return "Namba ya NIDA inaonekana fupi sana";
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),

                                // Simpler DOB field
                                TextFormField(
                                  controller: _dobCtrl,
                                  readOnly: true,
                                  decoration: const InputDecoration(
                                    labelText: "Tarehe ya Kuzaliwa (YYYY-MM-DD)",
                                    prefixIcon: Icon(Icons.cake),
                                    hintText: "Gusa kuchagua tarehe",
                                  ),
                                  onTap: _openDobBottomSheet,
                                  validator: (_) => _dob == null ? "Chagua tarehe ya kuzaliwa" : null,
                                ),

                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _addressCtrl,
                                  decoration: const InputDecoration(
                                    labelText: "Anuani (hiari)",
                                    prefixIcon: Icon(Icons.home_outlined),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 250),
                                  child: submitting
                                      ? const Padding(
                                          padding: EdgeInsets.all(8.0),
                                          child: CircularProgressIndicator(),
                                        )
                                      : SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton.icon(
                                            onPressed: _submit,
                                            icon: const Icon(Icons.verified_outlined),
                                            label: const Text("Wasilisha kwa Uthibitisho"),
                                          ),
                                        ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            await _resolveUserIdAndLoad();
                            if (_userId.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Bado hatujapata User ID.")),
                              );
                            }
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text("Onesha Hali Upya"),
                        ),
                      ),
                    ],
                  ),

                  if (loading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(8),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                ],
              ),
            );
          },
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
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: scheme.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: scheme.primary.withValues(alpha: 0.25)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: scheme.onSurface,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

// A compact button that does NOT try to expand to full width (overrides global ElevatedButton theme).
class _CompactButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  const _CompactButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 0), // ensure shrink-wrap
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(1, 40), // override any global full-width min constraint
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
          shape: const StadiumBorder(),
        ),
        onPressed: onPressed,
        child: Text(label),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final String status; // verified | pending | rejected | unknown
  final Map<String, dynamic>? latest;
  final bool missingUserId;

  const _StatusCard({
    required this.status,
    required this.latest,
    required this.missingUserId,
  });

  Color _statusColor(BuildContext context) {
    switch (status) {
      case 'verified':
        return Colors.green.shade600;
      case 'pending':
        return Colors.orange.shade700;
      case 'rejected':
        return Colors.red.shade600;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  IconData _statusIcon() {
    switch (status) {
      case 'verified':
        return Icons.verified;
      case 'pending':
        return Icons.hourglass_top_outlined;
      case 'rejected':
        return Icons.error_outline;
      default:
        return Icons.info_outline;
    }
  }

  String _statusTextSw() {
    switch (status) {
      case 'verified':
        return "Imethibitishwa";
      case 'pending':
        return "Inasubiri";
      case 'rejected':
        return "Imekataliwa";
      default:
        return "Haijulikani";
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(context);
    final rejection = latest?['rejection_reason']?.toString();
    final submittedAt = latest?['submitted_at']?.toString();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha((0.08 * 255).round()),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha((0.2 * 255).round())),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_statusIcon(), color: color, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Hali ya Mtumiaji: ${_statusTextSw()}",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: color),
                ),
                if (submittedAt != null && submittedAt.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text("Iliyowasilishwa mwisho: $submittedAt", style: const TextStyle(fontSize: 12)),
                ],
                if (status == 'rejected' && rejection != null && rejection.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text("Sababu: $rejection", style: const TextStyle(fontSize: 12)),
                ],
                const SizedBox(height: 6),
                Text(
                  missingUserId
                      ? "Hatukupata User ID. Tafadhali ingia tena na ujaribu."
                      : status == 'verified'
                          ? "Uthibitisho wa utambulisho umekamilika. Unaweza kufurahia huduma zote."
                          : status == 'pending'
                              ? "Maombi yako ya uthibitisho yanashughulikiwa."
                              : status == 'rejected'
                                  ? "Maombi yamekataliwa. Tafadhali sahihisha taarifa zako na ujaribu tena."
                                  : "Jaza taarifa hapa chini ili kuanza mchakato wa uthibitisho.",
                  style: const TextStyle(fontSize: 13, color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}