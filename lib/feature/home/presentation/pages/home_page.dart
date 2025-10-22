import 'dart:async';
import 'dart:math';

import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../session/auth_cubit.dart';
import '../../../../core/i18n/locale_extensions.dart';
import '../../../account/domain/account_repository.dart';
import '../../../pots/domain/pots_repository.dart';
import '../../../payments/domain/payments_repository.dart';
import '../../../pots/presentation/pages/pots_list_page.dart';
import '../../../payments/presentation/pages/deposit_page.dart';
import '../../../payments/presentation/pages/transactions_page.dart';
import '../../../auth/presentation/pages/profile_page.dart';

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
  Map<String, dynamic>? _account;

  // Live refresh
  Timer? _liveTimer;

  // Hero banners
  final _heroCtrl = PageController(viewportFraction: 0.9);
  Timer? _heroTimer;
  int _heroIndex = 0;
  final List<String> _heroImages = const [
    'https://picsum.photos/seed/misana2/1200/600',
    'https://picsum.photos/seed/misana3/1200/600',
  ];

  // Video banners (thumbnails)
  final List<_VideoItem> _videos = const [
    _VideoItem(
      title: 'Jinsi ya kuweka akiba',
      thumb: 'https://picsum.photos/seed/video2/800/450',
      url: 'https://example.com/video2',
    ),
    _VideoItem(
      title: 'Faida za Misana Saving',
      thumb: 'https://picsum.photos/seed/video3/800/450',
      url: 'https://example.com/video3',
    ),
    _VideoItem(
      title: 'Jinsi ya kutoa fedha',
      thumb: 'https://picsum.photos/seed/video1/800/450',
      url: 'https://example.com/video1',
    ),
    _VideoItem(
      title: 'Bonasi na promosheni',
      thumb: 'https://picsum.photos/seed/video4/800/450',
      url: 'https://example.com/video4',
    ),
  ];

  // Recently transactions
  bool _loadingTx = true;
  List<Map<String, dynamic>> _recentTx = const [];

  bool _checkingWithdraw = true;
  bool _canWithdraw = false;
  String? _withdrawWhy;

  // Keep greeting off to mimic original screenshot (set true to show)
  final bool showGreeting = false;

  AccountRepository get _accountRepo => RepositoryProvider.of<AccountRepository>(context);
  PotsRepository get _potsRepo => RepositoryProvider.of<PotsRepository>(context);
  PaymentsRepository get _paymentsRepo => RepositoryProvider.of<PaymentsRepository>(context);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _initialLoad();
      _startLiveTicker();
      _startHeroAutoSwipe();
    });
  }

  @override
  void dispose() {
    _liveTimer?.cancel();
    _heroTimer?.cancel();
    _heroCtrl.dispose();
    super.dispose();
  }

  Future<void> _initialLoad() async {
    await _refreshAccount();
    await _loadRecentTransactions();
    await _refreshWithdrawEligibility();
  }

  void _startLiveTicker() {
    _liveTimer?.cancel();
    _liveTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (!mounted) return;
      await _refreshAccount(silent: true);
      await _loadRecentTransactions(silent: true);
    });
  }

  void _startHeroAutoSwipe() {
    _heroTimer?.cancel();
    _heroTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || _heroImages.isEmpty) return;
      _heroIndex = (_heroIndex + 1) % _heroImages.length;
      _heroCtrl.animateToPage(
        _heroIndex,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  // ---------------- Helpers ----------------
  String _tr(String sw, String en) => context.trSw(sw, en);

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return _tr('Habari za Asubuhi', 'Good Morning');
    if (hour < 18) return _tr('Habari za Mchana', 'Good Afternoon');
    return _tr('Habari za Jioni', 'Good Evening');
  }

  num _rawBalance() {
    final v = _account?['balance'] ??
        _account?['current_balance'] ??
        _account?['current_amount'] ??
        0;
    if (v is num) return v;
    final parsed = num.tryParse(v.toString());
    return parsed ?? 0;
  }

  bool get _hasExternalAccount =>
      ((_account?['external_account_id'] ?? '') as String).isNotEmpty;

  // ---------------- Account Refresh ----------------
  Future<void> _refreshAccount({bool silent = false}) async {
    if (!mounted) return;
    if (!silent) {
      setState(() {
        _loadingAccount = true;
        _accountError = null;
      });
    }
    try {
      final uid = await _getUserIdOrWait();
      if (!mounted) return;
      if (uid == null || uid.isEmpty) {
        if (!silent) setState(() => _loadingAccount = false);
        return;
      }
      await context.read<AuthCubit>().refreshProfile();
      if (!mounted) return;

      final acc = await _accountRepo.getByUser(uid);
      if (!mounted) return;
      setState(() {
        _account = acc;
        _loadingAccount = false;
      });
    } on DioException catch (e) {
      final code = e.response?.statusCode ?? 0;
      if (code == 401) {
        try {
          await context.read<AuthCubit>().checkSession();
          if (!mounted) return;
          if (context.read<AuthCubit>().state.authenticated) {
            final uid2 = await _getUserIdOrWait();
            if (uid2 != null && uid2.isNotEmpty) {
              final acc = await _accountRepo.getByUser(uid2);
              if (!mounted) return;
              setState(() {
                _account = acc;
                _loadingAccount = false;
              });
              return;
            }
          }
        } catch (_) {}
        await _logout();
        return;
      }

      if (code == 404) {
        setState(() {
          _account = null;
          _accountError = null;
          _loadingAccount = false;
        });
        return;
      }

      setState(() {
        _accountError = e.toString();
        _loadingAccount = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _accountError = e.toString();
        _loadingAccount = false;
      });
    }
  }

  Future<void> _loadRecentTransactions({bool silent = false}) async {
    if (!mounted) return;
    if (!silent) setState(() => _loadingTx = true);
    try {
      final uid = await _getUserIdOrWait();
      if (!mounted || uid == null || uid.isEmpty) {
        if (!silent) setState(() => _loadingTx = false);
        return;
      }

      final dynamic repo = _paymentsRepo;
      List<Map<String, dynamic>> txs = [];

      Future<void> attempt(Future<dynamic> Function() fn) async {
        if (txs.isNotEmpty) return;
        try {
          final r = await fn();
          if (r is List) txs = r.cast<Map<String, dynamic>>();
          if (r is Map && r['items'] is List) {
            txs = (r['items'] as List).cast<Map<String, dynamic>>();
          }
        } catch (_) {}
      }

      await attempt(() => repo.listByUser(uid));
      await attempt(() => repo.list(uid));
      await attempt(() => repo.getByUser(uid));
      await attempt(() => repo.transactions(uid));

      txs.sort((a, b) {
        final aa = DateTime.tryParse((a['created_at'] ?? a['createdAt'] ?? '').toString()) ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final bb = DateTime.tryParse((b['created_at'] ?? b['createdAt'] ?? '').toString()) ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return bb.compareTo(aa);
      });

      if (!mounted) return;
      setState(() {
        _recentTx = txs.take(8).toList();
        _loadingTx = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingTx = false);
    }
  }

  Future<String?> _getUserIdOrWait({Duration timeout = const Duration(seconds: 8)}) async {
    final auth = context.read<AuthCubit>();
    final id = (auth.state.user?['id'] ?? '').toString();
    if (id.isNotEmpty) return id;
    try {
      final s = await auth.stream
          .firstWhere((st) => ((st.user?['id'] ?? '').toString().isNotEmpty))
          .timeout(timeout);
      return (s.user?['id'] ?? '').toString();
    } on TimeoutException {
      return null;
    }
  }

  // ---------------- Withdraw Eligibility ----------------
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
        if (mounted) {
          setState(() {
            _canWithdraw = false;
            _withdrawWhy =
                _tr('Kamilisha Mtumiaji verification kwanza.', 'Complete User verification first.');
          });
        }
        return;
      }

      if (!hasExternal) {
        if (mounted) {
          setState(() {
            _canWithdraw = false;
            _withdrawWhy =
                _tr('Huna akaunti ya malipo iliyounganishwa.', 'No linked payment account.');
          });
        }
        return;
      }

      final uid = (user['id'] ?? '').toString();
      if (uid.isEmpty) {
        if (mounted) {
          setState(() {
            _canWithdraw = false;
            _withdrawWhy = _tr('Hujalogin ipasavyo.', 'Not fully authenticated.');
          });
        }
        return;
      }

      final pots = await _loadUserPots(uid);
      final any = pots.any(_isPotWithdrawable);

      if (mounted) {
        setState(() {
          _canWithdraw = any;
          _withdrawWhy = any
              ? null
              : _tr('Hakuna mpango ulio tayari kutoa (withdraw).',
                  'No pots available for withdrawal.');
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _canWithdraw = false;
          _withdrawWhy = _tr(
              'Imeshindikana kuthibitisha ruhusa ya kutoa.', 'Unable to verify withdrawal permission.');
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _checkingWithdraw = false;
        });
      }
    }
  }

  Future<List<Map<String, dynamic>>> _loadUserPots(String userId) async {
    if (userId.isEmpty) return const [];
    final dynamic repo = _potsRepo;
    final List<Map<String, dynamic>> collected = [];

    Future<void> attempt(Future<dynamic> Function() fn) async {
      if (collected.isNotEmpty) return;
      try {
        final r = await fn();
        if (r is List) {
          collected.addAll(r.cast<Map<String, dynamic>>());
        } else if (r is Map && r['items'] is List) {
          collected.addAll((r['items'] as List).cast<Map<String, dynamic>>());
        }
      } catch (_) {}
    }

    await attempt(() => repo.listByUser(userId));
    await attempt(() => repo.listPots(userId));
    await attempt(() => repo.list(userId));
    await attempt(() => repo.getByUser(userId));
    await attempt(() => repo.list(userId));
    return collected;
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
      try {
        return DateTime.parse(v.toString());
      } catch (_) {
        return null;
      }
    }

    final allowed = flagTrue(['allow_withdraw', 'can_withdraw', 'withdraw_enabled']) ||
        statusIn(['matured', 'unlocked', 'active']);
    if (!allowed) return false;

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

  // ---------------- KYC Normalization ----------------
  String _normalizeKycFromUser(Map<String, dynamic>? user) {
    if (user == null) return 'unknown';
    final checks = [
      user['is_verified'],
      user['kyc_verified'],
      user['kycApproved'],
      (user['profile'] is Map ? user['profile']['kyc_verified'] : null),
    ];
    final anyTrue = checks.any((v) {
      if (v is bool) return v;
      if (v is String) {
        final s = v.toLowerCase();
        return ['true', '1', 'yes', 'approved', 'verified', 'success'].contains(s);
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

    if (['approved', 'verified', 'success'].contains(raw)) return 'verified';
    if (['pending', 'in_review', 'processing'].contains(raw)) return 'pending';
    if (['rejected', 'failed'].contains(raw)) return 'rejected';
    return 'unknown';
  }

  // ---------------- Ensure Account ----------------
  Future<void> _ensureAccount() async {
    if (!mounted) return;
    final user = context.read<AuthCubit>().state.user ?? {};
    final kyc = _normalizeKycFromUser(user);
    if (kyc != 'verified') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_tr('Kamilisha Taarifa za Mtumiaji kwanza.', 'Verify User information first.'))),
      );
      return;
    }

    setState(() {
      _loadingAccount = true;
      _accountError = null;
    });

    try {
      final acc = await _accountRepo.ensureAccount();
      if (!mounted) return;
      setState(() {
        _account = acc;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_tr('✅ Akaunti imefunguliwa', '✅ Account opened'))),
      );
      await context.read<AuthCubit>().refreshProfile();
      if (!mounted) return;
      _refreshWithdrawEligibility();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _accountError = e.toString();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_tr('Hitilafu kufungua akaunti: $e', 'Failed to open account: $e'))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loadingAccount = false;
        });
      }
    }
  }

  // ---------------- Logout ----------------
  Future<void> _logout() async {
    try {
      await context.read<AuthCubit>().logout();
    } catch (_) {
      await context.read<AuthCubit>().signOut();
    }
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
  }

  // ---------------- UI Helpers ----------------
  void _toggleBalance() => setState(() => _showBalance = !_showBalance);

  // ---------------- Build ----------------
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final user = context.watch<AuthCubit>().state.user ?? {};

    final pages = <Widget>[
      const SizedBox.shrink(),
      SafeArea(
        top: false,
        bottom: true,
        child: PotsListPage(repo: _potsRepo),
      ),
      const ProfilePage(),
    ];

    return BlocListener<AuthCubit, dynamic>(
      listenWhen: (prev, curr) => prev.user != curr.user,
      listener: (_, __) async {
        await _refreshAccount();
        await _loadRecentTransactions();
      },
      child: Scaffold(
        body: SafeArea(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 450),
            transitionBuilder: (child, anim) {
              final offset = Tween<Offset>(begin: const Offset(0.08, 0.08), end: Offset.zero)
                  .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic));
              return SlideTransition(
                position: offset,
                child: FadeTransition(opacity: anim, child: child),
              );
            },
            child: _selectedIndex == 0
                ? _buildDashboard(context, scheme, user)
                : pages[_selectedIndex],
          ),
        ),
        // Purple navbar with orange FAB button background
        bottomNavigationBar: CurvedNavigationBar(
          key: _navKey,
          index: _selectedIndex,
          height: _navBarHeight,
          items: [
            Icon(Icons.dashboard, size: 28, color: Colors.white),
            Icon(Icons.account_balance, size: 28, color: Colors.white),
            Icon(Icons.person, size: 28, color: Colors.white),
          ],
          color: BrandPalette.purple,
          buttonBackgroundColor: BrandPalette.orange,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          animationCurve: Curves.easeOutBack,
          animationDuration: const Duration(milliseconds: 500),
          onTap: (i) => setState(() => _selectedIndex = i),
        ),
      ),
    );
  }

  Widget _buildDashboard(BuildContext context, ColorScheme scheme, Map<String, dynamic> user) {
    final kycVerified = _normalizeKycFromUser(user) == 'verified';

    if (_loadingAccount) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_accountError != null) {
      final err = _accountError!;
      if (err.contains('401') || err.contains('404')) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _logout());
        return Center(child: Text(_tr('Session imeisha. Ingia upya.', 'Session expired. Please login again.')));
      }
      return _errorState(scheme, err);
    }
    if (_account == null) {
      return _noAccountState(scheme, kycVerified);
    }
    return _accountHeader(context, scheme, user, kycVerified);
  }

  Widget _errorState(ColorScheme scheme, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: scheme.error, size: 52),
            const SizedBox(height: 12),
            Text(_tr('Imeshindikana kupakia akaunti', 'Failed to load account'),
                style: TextStyle(fontWeight: FontWeight.w700, color: scheme.onSurface)),
            const SizedBox(height: 6),
            Text(error, textAlign: TextAlign.center, style: TextStyle(color: scheme.onSurfaceVariant)),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: () async {
                await _refreshAccount();
                await _loadRecentTransactions();
              },
              icon: const Icon(Icons.refresh),
              label: Text(_tr('Jaribu tena', 'Try Again')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _noAccountState(ColorScheme scheme, bool kycVerified) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(26),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.account_balance_outlined, color: BrandPalette.purple, size: 64),
            const SizedBox(height: 14),
            Text(
              kycVerified
                  ? _tr('Huna akaunti bado. Fungua akaunti ya Misana Saving ili uanze kuhifadhi.',
                      'No account yet. Open a Misana Saving account to start saving.')
                  : _tr('Kamilisha Taarifa za Mtumiaji kabla ya kufungua akaunti ya Misana Saving.',
                      'Complete User verification before opening a Misana Saving account.'),
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 15),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: _ensureAccount,
              icon: const Icon(Icons.add_circle_outline),
              label: Text(_tr('Fungua Akaunti', 'Open Account')),
              style: ElevatedButton.styleFrom(backgroundColor: BrandPalette.orange),
            ),
            if (!kycVerified)
              TextButton.icon(
                onPressed: () => Navigator.of(context).pushNamed('/kyc').then((_) async {
                  await _refreshAccount();
                  await _loadRecentTransactions();
                }),
                icon: const Icon(Icons.verified_outlined),
                label: Text(_tr('Kamilisha utambulishaji', 'Complete verification')),
              ),
          ],
        ),
      ),
    );
  }

  Widget _accountHeader(
      BuildContext context, ColorScheme scheme, Map<String, dynamic> user, bool kycVerified) {
    final accountNumber = (_account?['external_account_id'] ?? '—').toString();
    final status = (_account?['status'] ?? '').toString();
    final balanceValue = _rawBalance().toDouble();

    return RefreshIndicator(
      color: BrandPalette.purple,
      onRefresh: () async {
        await _refreshAccount();
        await _loadRecentTransactions();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            // Header: solid purple (no gradient), accents with brand orange
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(18, 26, 18, 28),
              decoration: const BoxDecoration(
                color: BrandPalette.purple,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showGreeting) ...[
                    Text(
                      _greeting(),
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                    const SizedBox(height: 6),
                  ],
                  const Text(
                    'Your Account',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          accountNumber,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      InkWell(
                        onTap: _toggleBalance,
                        borderRadius: BorderRadius.circular(22),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          child: Icon(
                            _showBalance ? Icons.visibility : Icons.visibility_off,
                            key: ValueKey(_showBalance),
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  _StatusPill(status: status),
                  const SizedBox(height: 18),
                  // Balance line with smooth number animation
                  Row(
                    children: [
                      const Text('Balance: ', style: TextStyle(color: Colors.white70)),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        child: _showBalance
                            ? _AnimatedAmount(
                                key: ValueKey<double>(balanceValue),
                                value: balanceValue,
                              )
                            : Container(
                                key: const ValueKey('balHidden'),
                                width: 70,
                                height: 18,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.18),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  // Quick actions row (inside header)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _QuickAction(
                        icon: Icons.file_download_outlined,
                        label: _tr('Weka (Deposit)', 'Deposit'),
                        enabled: _hasExternalAccount && kycVerified,
                        onTap: () {
                          if (!_hasExternalAccount || !kycVerified) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(_tr(
                                    'Hakikisha akaunti ipo na KYC imeidhinishwa.',
                                    'Ensure account exists and KYC is verified.')),
                              ),
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
                          ).then((_) async {
                            await _refreshAccount();
                            await _loadRecentTransactions();
                          });
                        },
                      ),
                      _QuickAction(
                        icon: Icons.file_upload_outlined,
                        label: _tr('Toa (Withdraw)', 'Withdraw'),
                        enabled: _canWithdraw && !_checkingWithdraw,
                        onTap: () {
                          if (!_canWithdraw) {
                            final reason = _withdrawWhy ??
                                _tr('Hujafikia vigezo vya kutoa.', 'Not eligible to withdraw.');
                            ScaffoldMessenger.of(context)
                                .showSnackBar(SnackBar(content: Text(reason)));
                            return;
                          }
                          Navigator.of(context).pushNamed('/withdraw').then((_) async {
                            await _refreshWithdrawEligibility();
                            await _refreshAccount();
                            await _loadRecentTransactions();
                          });
                        },
                      ),
                      _QuickAction(
                        icon: Icons.receipt_long_outlined,
                        label: _tr('Miamala', 'Transactions'),
                        enabled: _hasExternalAccount,
                        onTap: () {
                          if (!_hasExternalAccount) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(_tr(
                                    'Huna akaunti ya Selcom bado.', 'You do not have a Selcom account yet.')),
                              ),
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
                        label: 'Pots',
                        enabled: _hasExternalAccount && kycVerified,
                        onTap: () {
                          if (!_hasExternalAccount || !kycVerified) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(_tr(
                                    'Hakikisha akaunti ipo na KYC imeidhinishwa.',
                                    'Ensure account exists and KYC is verified.')),
                              ),
                            );
                            return;
                          }
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PotsListPage(repo: _potsRepo),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  if (_checkingWithdraw)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Checking withdraw eligibility...',
                            style: TextStyle(color: Colors.white70, fontSize: 11),
                          )
                        ],
                      ),
                    )
                  else if (!_canWithdraw && _withdrawWhy != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        _withdrawWhy!,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            ),

            // Hero Banners (with dot indicators)
            const SizedBox(height: 14),
            _HeroBanners(
              controller: _heroCtrl,
              images: _heroImages,
              index: _heroIndex,
              onChanged: (i) => setState(() => _heroIndex = i),
            ),

            // Video Banners Grid
            const SizedBox(height: 14),
            _VideoBannerGrid(items: _videos),

            // Recent Transactions
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    _tr('Miamala ya Hivi Karibuni', 'Recent Transactions'),
                    style: TextStyle(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _hasExternalAccount
                        ? () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => TransactionsPage(repo: _paymentsRepo),
                              ),
                            )
                        : null,
                    child: Text(_tr('Ona zote', 'See all')),
                  ),
                ],
              ),
            ),
            _RecentTxList(loading: _loadingTx, items: _recentTx),

            const SizedBox(height: _navBarHeight + 18),
          ],
        ),
      ),
    );
  }
}

class _VideoItem {
  final String title;
  final String thumb;
  final String url;
  const _VideoItem({required this.title, required this.thumb, required this.url});
}

// ---------------- UI Components ----------------
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
      opacity: enabled ? 1 : 0.55,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(50),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                shape: BoxShape.circle,
                border: Border.all(
                  color: BrandPalette.orange.withOpacity(0.35),
                  width: 1,
                ),
              ),
              padding: const EdgeInsets.all(14),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: 72,
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  height: 1.15,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String status;
  const _StatusPill({required this.status});

  IconData _icon() {
    switch (status.toLowerCase()) {
      case 'active':
        return Icons.verified;
      case 'pending':
        return Icons.hourglass_top;
      case 'blocked':
      case 'closed':
        return Icons.error_outline;
      default:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon(), size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            status,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedAmount extends StatelessWidget {
  final double value;
  const _AnimatedAmount({super.key, required this.value});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      builder: (_, v, __) => Text(
        'TSh ${v.toStringAsFixed(2)}',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
    );
  }
}

class _HeroBanners extends StatelessWidget {
  final PageController controller;
  final List<String> images;
  final int index;
  final ValueChanged<int> onChanged;

  const _HeroBanners({
    required this.controller,
    required this.images,
    required this.index,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        SizedBox(
          height: 170,
          child: PageView.builder(
            controller: controller,
            onPageChanged: onChanged,
            itemCount: images.length,
            padEnds: false,
            itemBuilder: (ctx, i) {
              final img = images[i];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(img, fit: BoxFit.cover),
                      Positioned(
                        left: 10,
                        bottom: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.35),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text(
                            'Misana Finance',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        // Dot indicators (orange active, grey inactive)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(images.length, (i) {
            final active = i == index;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 6,
              width: active ? 18 : 6,
              decoration: BoxDecoration(
                color: active ? BrandPalette.orange : Colors.black12,
                borderRadius: BorderRadius.circular(999),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _VideoBannerGrid extends StatelessWidget {
  final List<_VideoItem> items;
  const _VideoBannerGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 680;
    final crossAxisCount = isWide ? 3 : 2;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 16 / 9,
        ),
        itemBuilder: (ctx, i) {
          final v = items[i];
          return _VideoCard(item: v);
        },
      ),
    );
  }
}

class _VideoCard extends StatelessWidget {
  final _VideoItem item;
  const _VideoCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Video: ${item.title}')),
        );
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(item.thumb, fit: BoxFit.cover),
          ),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Colors.black.withOpacity(0.45), Colors.transparent],
              ),
            ),
          ),
          Center(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                shape: BoxShape.circle,
                border: Border.all(color: BrandPalette.orange, width: 1.5),
              ),
              padding: const EdgeInsets.all(10),
              child: Icon(Icons.play_arrow, size: 26, color: BrandPalette.orange),
            ),
          ),
          Positioned(
            left: 10,
            bottom: 8,
            right: 10,
            child: Text(
              item.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                shadows: [Shadow(blurRadius: 3, color: Colors.black54)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentTxList extends StatelessWidget {
  final bool loading;
  final List<Map<String, dynamic>> items;
  const _RecentTxList({required this.loading, required this.items});

  Color _statusColor(BuildContext context, String s) {
    switch (s.toLowerCase()) {
      case 'posted':
      case 'success':
      case 'completed':
        return Colors.green.shade600;
      case 'pending':
        return Colors.orange.shade700;
      case 'failed':
      case 'rejected':
        return Colors.red.shade600;
      default:
        return Theme.of(context).colorScheme.onSurfaceVariant;
    }
  }

  IconData _iconByType(String t) {
    switch (t.toLowerCase()) {
      case 'deposit':
        return Icons.arrow_downward_rounded;
      case 'withdraw':
        return Icons.arrow_upward_rounded;
      default:
        return Icons.receipt_long_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Text(
          '— Hakuna miamala bado —',
          textAlign: TextAlign.center,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: min(items.length, 8),
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (ctx, i) {
        final tx = items[i];
        final type = (tx['type'] ?? '').toString();
        final status = (tx['status'] ?? tx['provider_status'] ?? '').toString();
        final amount = (tx['amount'] is num)
            ? (tx['amount'] as num).toDouble()
            : double.tryParse((tx['amount'] ?? '0').toString()) ?? 0.0;
        final created = (tx['created_at'] ?? tx['createdAt'] ?? '').toString();
        final color = _statusColor(ctx, status);

        return Card(
          elevation: 0.8,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: color.withOpacity(0.12),
              child: Icon(_iconByType(type), color: color),
            ),
            title: Text(
              type.isEmpty ? '—' : '${type[0].toUpperCase()}${type.substring(1)}',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            subtitle: Text(created.isEmpty ? '—' : created),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('TSh ${amount.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: color.withOpacity(0.2)),
                  ),
                  child: Text(
                    status.isEmpty ? '—' : status,
                    style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}