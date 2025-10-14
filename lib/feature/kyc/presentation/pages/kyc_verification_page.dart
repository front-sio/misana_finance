import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import 'package:misana_finance_app/feature/account/domain/account_repository.dart';
import '../../../session/auth_cubit.dart';
import '../bloc/kyc_bloc.dart';
import '../bloc/kyc_event.dart';
import '../bloc/kyc_state.dart';

class KycVerificationPage extends StatefulWidget {
  // accountId ni hiari; kama haijatolewa tutajitafutia kiotomatiki.
  final String accountId;
  const KycVerificationPage({super.key, required this.accountId});

  @override
  State<KycVerificationPage> createState() => _KycVerificationPageState();
}

class _KycVerificationPageState extends State<KycVerificationPage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameCtrl = TextEditingController();
  final _nidCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();

  DateTime? _dob;
  String _resolvedAccountId = '';
  bool _resolving = true;

  @override
  void initState() {
    super.initState();
    // Resolve accountId mara tu ukurasa unapoanza
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _resolveAccountIdAndLoad();
    });
  }

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _nidCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  // Mpangilio wa kutafuta accountId:
  // 1) widget.accountId
  // 2) AuthCubit.user: account_id | accountId
  // 3) AccountRepository.getByUser(userId) => account['id'] (handle 404)
  Future<void> _resolveAccountIdAndLoad() async {
    String accountId = widget.accountId.trim();
    if (accountId.isEmpty) {
      final user = context.read<AuthCubit>().state.user ?? {};
      // Jaribu keys tofauti kutoka kwenye profile
      final fromAuth = (user['account_id'] ?? user['accountId'] ?? '').toString().trim();
      if (fromAuth.isNotEmpty) {
        accountId = fromAuth;
      } else {
        final userId = (user['id'] ?? '').toString().trim();
        if (userId.isNotEmpty) {
          try {
            final repo = RepositoryProvider.of<AccountRepository>(context);
            final acc = await repo.getByUser(userId);
            // FIX: acc inaweza kuwa null kwa baadhi ya utekelezaji; tumia null-aware access
            accountId = (acc?['id'] ?? '').toString().trim();
          } on DioException catch (e) {
            if (e.response?.statusCode == 404) {
              accountId = ''; // Hakuna akaunti bado
            } else {
              accountId = '';
            }
          } catch (_) {
            accountId = '';
          }
        }
      }
    }

    if (!mounted) return;
    setState(() {
      _resolvedAccountId = accountId;
      _resolving = false;
    });

    // Kama tuna accountId, pakia hali ya uthibitisho (bloc itafanya normalizing)
    if (_resolvedAccountId.isNotEmpty) {
      context.read<KycBloc>().add(KycLoadStatus(accountId: _resolvedAccountId));
    }
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final initial = DateTime(now.year - 18, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked != null) setState(() => _dob = picked);
  }

  void _submit() {
    // Tunahitaji accountId ya ndani ili kuwasilisha uthibitisho
    if (_resolvedAccountId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Hatukupata namba ya akaunti. Tafadhali jaribu tena baadaye.",
          ),
        ),
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
    final dobStr = DateFormat('yyyy-MM-dd').format(_dob!);

    context.read<KycBloc>().add(
          KycSubmit(
            accountId: _resolvedAccountId,
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
    return Scaffold(
      // Usitumie maneno ya kiufundi kwa mtumiaji: badala ya KYC, tumia “Uthibitisho wa Utambulisho”
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
            // Boresha profaili ili vionjo vya app visome hali mpya vizuri
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
                  status: state.status, // verified | pending | rejected | unknown (tayari imenormalizwa)
                  latest: state.history.isNotEmpty ? state.history.first : null,
                  missingAccountId: !_resolving && _resolvedAccountId.isEmpty,
                ),
                const SizedBox(height: 16),

                // Zuia fomu iwapo bado hatuna accountId
                AbsorbPointer(
                  absorbing: _resolvedAccountId.isEmpty,
                  child: Opacity(
                    opacity: _resolvedAccountId.isEmpty ? 0.5 : 1,
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
                              GestureDetector(
                                onTap: _pickDob,
                                child: AbsorbPointer(
                                  child: TextFormField(
                                    decoration: const InputDecoration(
                                      labelText: "Tarehe ya Kuzaliwa (yyyy-MM-dd)",
                                      prefixIcon: Icon(Icons.cake),
                                    ),
                                    controller: TextEditingController(
                                      text: _dob == null ? "" : DateFormat("yyyy-MM-dd").format(_dob!),
                                    ),
                                    validator: (_) =>
                                        _dob == null ? "Chagua tarehe ya kuzaliwa" : null,
                                  ),
                                ),
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

                if (loading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(8),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            if (_resolvedAccountId.isNotEmpty) {
                              context
                                  .read<KycBloc>()
                                  .add(KycLoadStatus(accountId: _resolvedAccountId));
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Bado hatujapata namba ya akaunti."),
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text("Onesha Hali Upya"),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final String status; // verified | pending | rejected | unknown
  final Map<String, dynamic>? latest;
  final bool missingAccountId;

  const _StatusCard({
    required this.status,
    required this.latest,
    required this.missingAccountId,
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
                // Usitumie neno KYC kwa mtumiaji
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
                  missingAccountId
                      ? "Hatukupata namba ya akaunti. Ukipata akaunti ya ndani, utaweza kuwasilisha uthibitisho hapa."
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