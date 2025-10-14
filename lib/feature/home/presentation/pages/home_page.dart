import 'dart:async';

import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:misana_finance_app/core/theme/app_theme.dart';
import 'package:misana_finance_app/feature/account/domain/account_repository.dart';
import 'package:misana_finance_app/feature/pots/domain/pots_repository.dart';
import 'package:misana_finance_app/feature/payments/domain/payments_repository.dart';

import 'package:misana_finance_app/feature/pots/presentation/pages/pots_list_page.dart';
import 'package:misana_finance_app/feature/payments/presentation/pages/deposit_page.dart';
import 'package:misana_finance_app/feature/payments/presentation/pages/transactions_page.dart';

import '../../../../core/i18n/locale_cubit.dart';
import '../../../session/auth_cubit.dart';

/// Enforce:
/// - Hakuna kufungua akaunti bila KYC verified
/// - Kuunda mpango/Deposit zinahitaji external account ID na KYC verified
/// - Hakuna “sina account id” tena kwa sababu tunahakikisha data inabaki kwenye state
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const double _navBarHeight = 60;
  final _navKey = GlobalKey<CurvedNavigationBarState>();
  int _selectedIndex = 0;
  bool _showBalance = false;

  bool _loadingAccount = true;
  String? _accountError;
  Map<String, dynamic>? _account; // { id, user_id, external_account_id, status, ... }

  // Withdraw eligibility
  bool _checkingWithdraw = true;
  bool _canWithdraw = false;
  String? _withdrawWhy; // reason when disabled

  double get _displayBalance => 0.0;

  AccountRepository get _accountRepo => RepositoryProvider.of<AccountRepository>(context);
  PotsRepository get _potsRepo => RepositoryProvider.of<PotsRepository>(context);
  PaymentsRepository get _paymentsRepo => RepositoryProvider.of<PaymentsRepository>(context);

  @override
  void initState() {
    super.initState();
    // Kick off initial load; this will now wait for user id.
    // ignore: discarded_futures
    _refreshAccount();
    // Also compute withdraw eligibility
    // ignore: discarded_futures
    _refreshWithdrawEligibility();
  }

  @override
  void dispose() {
    super.dispose();
  }

  // Waits for an authenticated user id if not yet available.
  Future<String?> _getUserIdOrWait({Duration timeout = const Duration(seconds: 8)}) async {
    final auth = context.read<AuthCubit>();
    String id = (auth.state.user?['id'] ?? '').toString();
    if (id.isNotEmpty) return id;

    try {
      final next = await auth.stream
          .firstWhere((s) => ((s.user?['id'] ?? '').toString().isNotEmpty))
          .timeout(timeout);
      return (next.user?['id'] ?? '').toString();
    } on TimeoutException {
      return null;
    }
  }

  String _normalizeKycFromUser(Map<String, dynamic>? user) {
    if (user == null) return 'unknown';
    final anyTrue = [
      user['is_verified'],
      user['kyc_verified'],
      user['kycApproved'],
      // Some backends send nested profile flags; add defensive reads if applicable:
      (user['profile'] is Map ? user['profile']['kyc_verified'] : null),
    ].any((v) {
      if (v is bool) return v;
      if (v is String) {
        final s = v.toLowerCase();
        return s == 'true' || s == '1' || s == 'yes' || s == 'approved' || s == 'verified' || s == 'success';
      }
      return false;
    });
    if (anyTrue) return 'verified';
    final raw = (user['kyc_status'] ??
            user['kyc_verification'] ??
            (user['profile'] is Map ? user['profile']['kyc_status'] : '') ??
            '')
        .toString()
        .toLowerCase()
        .trim();
    if (raw == 'approved' || raw == 'verified' || raw == 'success') return 'verified';
    if (raw == 'pending' || raw == 'in_review' || raw == 'processing') return 'pending';
    if (raw == 'rejected' || raw == 'failed') return 'rejected';
    return 'unknown';
  }

  Future<void> _refreshAccount() async {
    if (!mounted) return;
    setState(() {
      _loadingAccount = true;
      _accountError = null;
    });

    try {
      final uid = await _getUserIdOrWait();
      if (!mounted) return;

      if (uid == null || uid.isEmpty) {
        // Auth not ready yet; keep spinner, and listener below will try again.
        setState(() {
          _loadingAccount = true;
        });
        return;
      }

      // Ensure the latest profile first so KYC flags are up to date
      await context.read<AuthCubit>().refreshProfile();

      final acc = await _accountRepo.getByUser(uid);
      if (!mounted) return;

      setState(() {
        _account = acc;
        _loadingAccount = false;
        _accountError = null;
      });

      // Recompute withdraw eligibility when account changes
      // ignore: discarded_futures
      _refreshWithdrawEligibility();
    } catch (e) {
      if (!mounted) return;
      if (e is DioException && e.response?.statusCode == 404) {
        // Account doesn't exist (yet). Don't treat as hard error.
        setState(() {
          _account = null;
          _loadingAccount = false;
          _accountError = null;
        });
        // Even if there's no account, recompute (will be false)
        // ignore: discarded_futures
        _refreshWithdrawEligibility();
        return;
      }
      setState(() {
        _accountError = e.toString();
        _loadingAccount = false;
      });
    }
  }

  // Compute withdraw eligibility based on:
  // - KYC verified
  // - Has external account
  // - At least one Pot is withdrawable:
  //   - allow_withdraw | can_withdraw | withdraw_enabled true
  //   - OR matured == true OR status in ['matured', 'unlocked']
  //   - Respect optional constraints: lock_until (past), min balance >= withdraw_min
  Future<void> _refreshWithdrawEligibility() async {
    if (!mounted) return;
    setState(() {
      _checkingWithdraw = true;
      _canWithdraw = false;
      _withdrawWhy = null;
    });

    try {
      final user = context.read<AuthCubit>().state.user ?? {};
      final kyc = _normalizeKycFromUser(user);
      final hasKyc = kyc == 'verified';
      final hasExternal = _hasExternalAccount;

      if (!hasKyc) {
        setState(() {
          _canWithdraw = false;
          _withdrawWhy = 'Kamilisha KYC verification kwanza.';
          _checkingWithdraw = false;
        });
        return;
      }

      if (!hasExternal) {
        setState(() {
          _canWithdraw = false;
          _withdrawWhy = 'Huna akaunti ya malipo iliyounganishwa.';
          _checkingWithdraw = false;
        });
        return;
      }

      final uid = await _getUserIdOrWait();
      if (uid == null || uid.isEmpty) {
        setState(() {
          _canWithdraw = false;
          _withdrawWhy = 'Hujalogin ipasavyo.';
          _checkingWithdraw = false;
        });
        return;
      }

      // Load pots and evaluate
      final pots = await _loadUserPots(uid);
      bool any = false;
      for (final p in pots) {
        if (_isPotWithdrawable(p)) {
          any = true;
          break;
        }
      }

      setState(() {
        _canWithdraw = any;
        _withdrawWhy = any ? null : 'Hakuna mpango ulio tayari kutoa (withdraw).';
        _checkingWithdraw = false;
      });
    } catch (e) {
      setState(() {
        _canWithdraw = false;
        _withdrawWhy = 'Imeshindikana kuthibitisha ruhusa ya kutoa.';
        _checkingWithdraw = false;
      });
    }
  }

  Future<List<Map<String, dynamic>>> _loadUserPots(String userId) async {
    final dynamic repo = _potsRepo;
    // Try the common method names defensively
    try {
      final r = await repo.listByUser(userId);
      if (r is List) return r.cast<Map<String, dynamic>>();
    } catch (_) {}
    try {
      final r = await repo.listPots(userId);
      if (r is List) return r.cast<Map<String, dynamic>>();
    } catch (_) {}
    try {
      final r = await repo.list(userId);
      if (r is List) return r.cast<Map<String, dynamic>>();
    } catch (_) {}
    try {
      final r = await repo.getByUser(userId);
      if (r is List) return r.cast<Map<String, dynamic>>();
    } catch (_) {}
    // Map with items
    try {
      final r = await repo.list(userId);
      if (r is Map && r['items'] is List) {
        return (r['items'] as List).cast<Map<String, dynamic>>();
      }
    } catch (_) {}
    return const <Map<String, dynamic>>[];
  }

  bool _isPotWithdrawable(Map<String, dynamic> p) {
    bool flagTrue(List<String> keys) {
      for (final k in keys) {
        final v = p[k];
        if (v is bool && v) return true;
        if (v is String && v.toLowerCase().trim() == 'true') return true;
      }
      return false;
    }

    bool statusIn(List<String> values) {
      final s = (p['status'] ?? '').toString().toLowerCase();
      return values.contains(s);
    }

    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      final s = v.toString();
      try {
        return DateTime.parse(s);
      } catch (_) {
        return null;
      }
    }

    // Basic flags
    final allowed =
        flagTrue(['allow_withdraw', 'can_withdraw', 'withdraw_enabled']) || statusIn(['matured', 'unlocked', 'active']);

    if (!allowed) return false;

    // Optional constraints
    final lockUntil = parseDate(p['lock_until'] ?? p['locked_until']);
    if (lockUntil != null && lockUntil.isAfter(DateTime.now())) return false;

    final balance = (p['balance'] as num?)?.toDouble() ??
        double.tryParse((p['balance'] ?? '').toString()) ??
        0.0;
    final minReq = (p['withdraw_min'] as num?)?.toDouble() ??
        double.tryParse((p['withdraw_min'] ?? '').toString()) ??
        0.0;

    if (balance <= 0) return false;
    if (minReq > 0 && balance < minReq) return false;

    return true;
  }

  Future<void> _ensureAccount() async {
    // Guard: Ruhusu kufungua akaunti tu kama KYC ni verified
    final user = context.read<AuthCubit>().state.user;
    final kyc = _normalizeKycFromUser(user);
    if (kyc != 'verified') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Kamilisha KYC verification kwanza kabla ya kufungua akaunti."),
        ),
      );
      if (mounted) {
        Navigator.of(context).pushNamed('/kyc').then((_) {
          // After returning from KYC, re-check
          // ignore: discarded_futures
          _refreshAccount();
        });
      }
      return;
    }

    setState(() {
      _loadingAccount = true;
      _accountError = null;
    });
    try {
      final ensured = await _accountRepo.ensureAccount();
      if (!mounted) return;
      setState(() {
        _account = ensured;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Akaunti imefunguliwa")),
      );
      await context.read<AuthCubit>().refreshProfile();
      // After opening, recompute withdraw
      // ignore: discarded_futures
      _refreshWithdrawEligibility();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _accountError = e.toString();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Hitilafu kufungua akaunti: $e")),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loadingAccount = false;
        });
      }
    }
  }

  void _toggleBalance() => setState(() => _showBalance = !_showBalance);

  Future<void> _logout() async {
    try {
      context.read<AuthCubit>().logout();
    } catch (_) {
      await context.read<AuthCubit>().signOut();
    }
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (r) => false);
  }

  bool get _hasExternalAccount =>
      ((_account?['external_account_id'] ?? '').toString()).isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    // IMPORTANT: compute reactive KYC here during build (safe to use watch)
    final user = context.watch<AuthCubit>().state.user;
    final kycVerified = _normalizeKycFromUser(user) == 'verified';

    final pages = [
      const SizedBox.shrink(),
      SafeArea(
        top: false,
        left: false,
        right: false,
        bottom: true,
        child: PotsListPage(repo: _potsRepo),
      ),
      _ProfileTab(
        loadingAccount: _loadingAccount,
        account: _account,
        onLogout: _logout,
      ),
    ];

    return BlocListener<AuthCubit, dynamic>(
      listenWhen: (prev, curr) {
        // Re-run account fetch when user object changes (e.g., after login or refreshProfile)
        final prevId = (prev.user?['id'] ?? '').toString();
        final currId = (curr.user?['id'] ?? '').toString();
        return prevId != currId || prev.user != curr.user;
      },
      listener: (context, state) {
        // ignore: discarded_futures
        _refreshAccount();
      },
      child: Scaffold(
        extendBody: false,
        body: SafeArea(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 450),
            transitionBuilder: (child, anim) {
              final offsetAnim = Tween<Offset>(begin: const Offset(0.08, 0.08), end: Offset.zero)
                  .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic));
              return SlideTransition(
                position: offsetAnim,
                child: FadeTransition(opacity: anim, child: child),
              );
            },
            child: _selectedIndex == 0
                ? _dashboard(scheme, kycVerified: kycVerified)
                : pages[_selectedIndex],
          ),
        ),
        bottomNavigationBar: CurvedNavigationBar(
          key: _navKey,
          index: _selectedIndex,
          height: _navBarHeight,
          items: [
            Icon(Icons.dashboard, size: 28, color: scheme.onPrimary),
            Icon(Icons.account_balance, size: 28, color: scheme.onPrimary),
            Icon(Icons.person, size: 28, color: scheme.onPrimary),
          ],
          color: scheme.primary,
          buttonBackgroundColor: scheme.secondary,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          animationCurve: Curves.easeOutBack,
          animationDuration: const Duration(milliseconds: 500),
          onTap: (index) => setState(() => _selectedIndex = index),
        ),
      ),
    );
  }

  Widget _dashboard(ColorScheme scheme, {required bool kycVerified}) {
    final brand = Theme.of(context).extension<BrandTheme>()!;
    final user = context.watch<AuthCubit>().state.user;
    final kyc = _normalizeKycFromUser(user);

    if (_loadingAccount) {
      return const Center(child: SizedBox(width: 100, height: 100, child: CircularProgressIndicator()));
    }

    if (_accountError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: scheme.error, size: 48),
              const SizedBox(height: 10),
              Text("Imeshindikana kupakia akaunti",
                  style: TextStyle(color: scheme.onSurface, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(_accountError!, style: TextStyle(color: scheme.onSurfaceVariant), textAlign: TextAlign.center),
              const SizedBox(height: 12),
              OutlinedButton.icon(onPressed: _refreshAccount, icon: const Icon(Icons.refresh), label: const Text("Jaribu tena")),
            ],
          ),
        ),
      );
    }

    if (_account == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.account_balance_outlined, size: 56, color: scheme.primary),
              const SizedBox(height: 12),
              Text(
                kycVerified
                    ? "Huna akaunti bado. Fungua akaunti ya Selcom ili uanze kuhifadhi."
                    : "Kamilisha KYC verification kabla ya kufungua akaunti ya Selcom.",
                style: TextStyle(fontSize: 16, color: scheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                onPressed: _ensureAccount,
                icon: const Icon(Icons.add_circle_outline),
                label: const Text("Fungua Akaunti"),
              ),
              if (kyc != 'verified') ...[
                const SizedBox(height: 10),
                TextButton.icon(
                  onPressed: () => Navigator.of(context).pushNamed('/kyc').then((_) {
                    // ignore: discarded_futures
                    _refreshAccount();
                  }),
                  icon: const Icon(Icons.verified_outlined),
                  label: const Text("Nenda KYC"),
                ),
              ],
            ],
          ),
        ),
      );
    }

    final externalId = (_account?['external_account_id'] ?? '').toString();
    final accountStatus = (_account?['status'] ?? '').toString();

    // Capture booleans once for gestures (no Provider reads in onTap)
    final hasExternal = _hasExternalAccount;

    return RefreshIndicator(
      color: scheme.primary,
      onRefresh: () async {
        await _refreshAccount();
        if (!mounted) return;
        setState(() {});
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 28),
              decoration: BoxDecoration(
                gradient: (Theme.of(context).brightness == Brightness.dark
                    ? brand.headerGradientDark
                    : brand.headerGradient),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
              ),
              child: Column(
                children: [
                  // External ID + status (informational)
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Akaunti yako", style: TextStyle(color: Colors.white70)),
                            const SizedBox(height: 4),
                            Text(
                              externalId.isEmpty ? "—" : externalId,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            _StatusPill(status: accountStatus),
                          ],
                        ),
                      ),
                      InkWell(
                        onTap: _toggleBalance,
                        borderRadius: BorderRadius.circular(22),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 280),
                          child: Icon(
                            _showBalance ? Icons.visibility : Icons.visibility_off,
                            key: ValueKey(_showBalance),
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  // Quick actions (zinalindwa)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _QuickAction(
                        icon: Icons.file_download_outlined,
                        label: "Weka (Deposit)",
                        enabled: hasExternal && kycVerified,
                        onTap: () {
                          if (!hasExternal || !kycVerified) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Hakikisha akaunti ipo na KYC imeidhinishwa.")),
                            );
                            return;
                          }
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DepositPage(
                                paymentsRepo: _paymentsRepo,
                                potsRepo: _potsRepo,
                              ),
                            ),
                          ).then((_) => _refreshAccount());
                        },
                      ),
                      _QuickAction(
                        icon: Icons.file_upload_outlined,
                        label: "Toa (Withdraw)",
                        enabled: _canWithdraw && !_checkingWithdraw,
                        onTap: () {
                          if (!_canWithdraw) {
                            final reason = _withdrawWhy ?? "Hujafikia vigezo vya kutoa.";
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(reason)));
                            return;
                          }
                         
                          Navigator.of(context).pushNamed('/withdraw').then((_) {
                            // After possible changes, refresh eligibility
                            // ignore: discarded_futures
                            _refreshWithdrawEligibility();
                          });
                        },
                      ),
                      _QuickAction(
                        icon: Icons.receipt_long_outlined,
                        label: "Miamala",
                        enabled: hasExternal,
                        onTap: () {
                          if (!hasExternal) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Huna akaunti ya Selcom bado.")),
                            );
                            return;
                          }
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TransactionsPage(repo: _paymentsRepo),
                            ),
                          );
                        },
                      ),
                      _QuickAction(
                        icon: Icons.account_balance,
                        label: "Pots",
                        enabled: hasExternal && kycVerified,
                        onTap: () {
                          if (!hasExternal || !kycVerified) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Hakikisha akaunti ipo na KYC imeidhinishwa.")),
                            );
                            return;
                          }
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => PotsListPage(repo: _potsRepo)),
                          );
                        },
                      ),
                    ],
                  ),
                  if (_checkingWithdraw)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          ),
                          SizedBox(width: 8),
                          Text("Inathibitisha ruhusa ya kutoa...", style: TextStyle(color: Colors.white70)),
                        ],
                      ),
                    )
                  else if (!_canWithdraw && _withdrawWhy != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        _withdrawWhy!,
                        style: const TextStyle(color: Colors.white70, fontSize: 12, fontStyle: FontStyle.italic),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            ),

            // Spacer ili maudhui ya chini yasiende nyuma ya nav bar
            const SizedBox(height: _navBarHeight + 16),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback onTap;
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = enabled ? Colors.white : Colors.white70;
    return Opacity(
      opacity: enabled ? 1 : 0.6,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(50),
        child: Column(
          children: [
            Container(
              decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
              padding: const EdgeInsets.all(14),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 6),
            Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _ProfileTab extends StatelessWidget {
  final Map<String, dynamic>? account; // optional, linked Selcom ID
  final bool loadingAccount;
  final VoidCallback onLogout;

  const _ProfileTab({
    required this.account,
    required this.loadingAccount,
    required this.onLogout,
  });

  String _t(BuildContext context, String key) {
    final lang = context.watch<LocaleCubit>().state.languageCode;
    final sw = {
      'profile': 'Akaunti Yangu',
      'kyc_status': 'Hali ya Mtumiaji',
      'verified': 'Imethibitishwa',
      'pending': 'Inasubiri',
      'rejected': 'Imekataliwa',
      'unknown': 'Haijulikani',
      'verify_now': 'Thibitisha sasa',
      'linked_id': 'Namba yako ya Misana',
      'account': 'Akaunti',
      'loading': 'Inapakia...',
      'logout': 'Toka (Logout)',
      'logout_title': 'Toka',
      'logout_msg': 'Una uhakika unataka kutoka?',
      'cancel': 'Ghairi',
      'yes_logout': 'Toka',
      'username': 'Mtumiaji',
      'email': 'Barua pepe',
    };
    final en = {
      'profile': 'My Profile',
      'kyc_status': 'User status',
      'verified': 'Verified',
      'pending': 'Pending',
      'rejected': 'Rejected',
      'unknown': 'Unknown',
      'verify_now': 'Verify now',
      'linked_id': 'Your Misana ID',
      'account': 'Account',
      'loading': 'Loading...',
      'logout': 'Logout',
      'logout_title': 'Logout',
      'logout_msg': 'Are you sure you want to logout?',
      'cancel': 'Cancel',
      'yes_logout': 'Logout',
      'username': 'Username',
      'email': 'Email',
    };
    return (lang == 'sw' ? sw : en)[key] ?? key;
  }

  String _normalizeKycFromUser(Map<String, dynamic>? user) {
    if (user == null) return 'unknown';
    final anyTrue = [
      user['is_verified'],
      user['kyc_verified'],
      user['kycApproved'],
      (user['profile'] is Map ? user['profile']['kyc_verified'] : null),
    ].any((v) {
      if (v is bool) return v;
      if (v is String) {
        final s = v.toLowerCase();
        return s == 'true' || s == '1' || s == 'yes' || s == 'approved' || s == 'verified' || s == 'success';
      }
      return false;
    });
    if (anyTrue) return 'verified';
    final raw = (user['kyc_status'] ??
            user['kyc_verification'] ??
            (user['profile'] is Map ? user['profile']['kyc_status'] : '') ??
            '')
        .toString()
        .toLowerCase()
        .trim();
    if (raw == 'approved' || raw == 'verified' || raw == 'success') return 'verified';
    if (raw == 'pending' || raw == 'in_review' || raw == 'processing') return 'pending';
    if (raw == 'rejected' || raw == 'failed') return 'rejected';
    return 'unknown';
  }

  Color _kycColor(String status, Brightness b) {
    final s = status.toLowerCase();
    final dark = b == Brightness.dark;
    if (s == 'verified') return dark ? Colors.greenAccent : Colors.green;
    if (s == 'pending') return dark ? Colors.amberAccent : Colors.amber;
    if (s == 'rejected') return dark ? Colors.redAccent : Colors.red;
    return dark ? Colors.blueGrey.shade200 : Colors.blueGrey;
  }

  IconData _kycIcon(String status) {
    final s = status.toLowerCase();
    if (s == 'verified') return Icons.verified;
    if (s == 'pending') return Icons.hourglass_top;
    if (s == 'rejected') return Icons.error_outline;
    return Icons.info_outline;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;
    final brand = Theme.of(context).extension<BrandTheme>();

    final user = context.watch<AuthCubit>().state.user ?? {};
    final username = (user['username'] ?? 'User').toString();
    final email = (user['email'] ?? '').toString();

    final kycNorm = _normalizeKycFromUser(user);
    final kycColor = _kycColor(kycNorm, brightness);
    final kycIcon = _kycIcon(kycNorm);
    final kycText = _t(context, kycNorm);

    final selcomId = (account?['external_account_id'] ?? '').toString();

    Future<void> confirmLogout() async {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(_t(context, 'logout_title')),
          content: Text(_t(context, 'logout_msg')),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(_t(context, 'cancel'))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: scheme.error),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(_t(context, 'yes_logout')),
            ),
          ],
        ),
      );
      if (ok == true) onLogout();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_t(context, 'profile')),
        actions: [
          IconButton(
            tooltip: _t(context, 'logout'),
            icon: const Icon(Icons.logout_rounded),
            onPressed: confirmLogout,
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // Gradient header
          SliverToBoxAdapter(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 28),
              decoration: BoxDecoration(
                gradient: (Theme.of(context).brightness == Brightness.dark
                    ? brand?.headerGradientDark
                    : brand?.headerGradient),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 34,
                    backgroundColor: Colors.white.withAlpha((0.15 * 255).round()),
                    child: const Icon(Icons.person, color: Colors.white, size: 32),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          username,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        if (email.isNotEmpty)
                          Text(email, style: const TextStyle(color: Colors.white70), overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content cards
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                children: [
                  // KYC card
                  Card(
                    elevation: 1.5,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      leading: CircleAvatar(
                        backgroundColor: kycColor.withAlpha((0.15 * 255).round()),
                        child: Icon(kycIcon, color: kycColor),
                      ),
                      title: Text(_t(context, 'kyc_status')),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: kycColor.withAlpha((0.12 * 255).round()),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            kycText,
                            style: TextStyle(color: kycColor, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                      trailing: (kycNorm == 'verified')
                          ? null
                          : TextButton(
                              onPressed: () => Navigator.of(context).pushNamed('/kyc').then((_) {
                                // ignore: discarded_futures
                                context.read<AuthCubit>().refreshProfile();
                              }),
                              child: Text(_t(context, 'verify_now')),
                            ),
                    ),
                  ),

                  // Linked Selcom ID
                  if (loadingAccount)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Card(
                        elevation: 1.5,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: const ListTile(
                          leading: CircleAvatar(child: Icon(Icons.sync)),
                          title: Text('Akaunti'),
                          subtitle: Text('Inapakia...'),
                        ),
                      ),
                    )
                  else if (selcomId.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Card(
                        elevation: 1.5,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          leading: const CircleAvatar(child: Icon(Icons.link)),
                          title: const Text('Namba yako ya Misana'),
                          subtitle: Text(selcomId, overflow: TextOverflow.ellipsis),
                        ),
                      ),
                    ),

                  // Logout
                  Padding(
                    padding: const EdgeInsets.only(top: 16, bottom: 16),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: confirmLogout,
                        icon: const Icon(Icons.logout_rounded),
                        label: const Text('Toka (Logout)'),
                      ),
                    ),
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

class _StatusPill extends StatelessWidget {
  final String status;
  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;
    switch (status.toLowerCase()) {
      case 'active':
        color = Colors.green;
        icon = Icons.verified;
        break;
      case 'pending':
        color = Colors.amber;
        icon = Icons.hourglass_top;
        break;
      case 'blocked':
      case 'closed':
        color = Theme.of(context).colorScheme.error;
        icon = Icons.error_outline;
        break;
      default:
        color = Theme.of(context).colorScheme.onPrimary;
        icon = Icons.info_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0x2EFFFFFF), // ~18% white
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0x59FFFFFF)), // ~35% white
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(status, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}