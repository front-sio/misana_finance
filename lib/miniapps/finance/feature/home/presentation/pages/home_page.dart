import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';

import 'package:misana_finance_app/core/theme/app_theme.dart';
import 'package:misana_finance_app/core/transitions/page_transition.dart';

import 'package:misana_finance_app/auth/session/auth_cubit.dart';
import 'package:misana_finance_app/auth/session/auth_state.dart';

import 'package:misana_finance_app/miniapps/finance/feature/account/domain/account_repository.dart';
import 'package:misana_finance_app/miniapps/finance/feature/payments/domain/payments_repository.dart';
import 'package:misana_finance_app/miniapps/finance/feature/pots/domain/pots_repository.dart';

import 'package:misana_finance_app/auth/presentation/pages/profile_page.dart';
import 'package:misana_finance_app/miniapps/finance/feature/pots/presentation/pages/pots_list_page.dart';
import 'package:misana_finance_app/miniapps/finance/feature/payments/presentation/pages/deposit_page.dart';
import 'package:misana_finance_app/miniapps/finance/feature/payments/presentation/pages/transactions_page.dart';

import 'package:misana_finance_app/miniapps/finance/feature/home/presentation/widgets/account_header.dart';
import 'package:misana_finance_app/miniapps/finance/feature/home/presentation/widgets/hero_banner.dart';
import 'package:misana_finance_app/miniapps/finance/feature/home/presentation/widgets/quick_action_button.dart';
import 'package:misana_finance_app/miniapps/finance/feature/home/presentation/widgets/transction_list.dart';
import 'package:misana_finance_app/core/i18n/locale_cubit.dart';

class HomePage extends StatefulWidget {
  final int initialIndex;
  const HomePage({super.key, this.initialIndex = 0});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  static const double _navBarHeight = 60;
  final _navKey = GlobalKey<CurvedNavigationBarState>();

  late final AnimationController _tabController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;

  int _selectedIndex = 0;
  bool _showBalance = false;

  late final PageController _heroController;
  Timer? _heroTimer;
  int _heroIndex = 0;

  bool _loadingAccount = true;
  String? _accountError;
  Map<String, dynamic>? _account;
  double _potsTotalBalance = 0;

  bool _loadingTx = true;
  List<Map<String, dynamic>> _transactions = const [];
  double _pullProgress = 0;

  AccountRepository get _accountRepo => context.read<AccountRepository>();
  PaymentsRepository get _paymentsRepo => context.read<PaymentsRepository>();
  PotsRepository get _potsRepo => context.read<PotsRepository>();

  final List<String> _heroImages = const [
    'https://picsum.photos/seed/misana2/1200/600',
    'https://picsum.photos/seed/misana3/1200/600',
  ];



  @override
  void initState() {
    super.initState();
    _heroController = PageController(viewportFraction: 0.9);
    _selectedIndex = widget.initialIndex.clamp(0, 2);
    _setupAnimations();
    _startHeroAutoSwipe();
    _checkAuthAndLoad();
  }

  void _setupAnimations() {
    _tabController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(parent: _tabController, curve: Curves.easeOutCubic);
    _scaleAnimation = Tween(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _tabController, curve: Curves.easeOutCubic),
    );
    _tabController.forward();
  }

  void _startHeroAutoSwipe() {
    _heroTimer?.cancel();
    _heroTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || _heroImages.isEmpty || !_heroController.hasClients) return;

      try {
        setState(() {
          _heroIndex = (_heroIndex + 1) % _heroImages.length;
        });
        _heroController.animateToPage(
          _heroIndex,
          duration: const Duration(milliseconds: 580),
          curve: Curves.easeOutCubic,
        );
      } catch (e) {
        debugPrint('Hero banner animation error: $e');
      }
    });
  }

  Future<void> _checkAuthAndLoad() async {
    try {
      await context.read<AuthCubit>().checkSession();
      if (!mounted) return;
      
      final auth = context.read<AuthCubit>().state;
      if (auth.authenticated) {
        // Force refresh profile to get latest verification status
        await context.read<AuthCubit>().refreshProfile();
        if (!mounted) return;
        await _loadInitialData();
      } else {
        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _accountError = 'Authentication error: $e';
        _loadingAccount = false;
      });
    }
  }

  Future<void> _loadInitialData() async {
    await Future.wait([
      _refreshAccount(),
      _loadTransactions(),
      _loadPotsTotal(),
    ]);
    if (mounted) setState(() => _pullProgress = 0);
  }

  Future<void> _refreshAccount() async {
    if (!mounted) return;
    setState(() {
      _loadingAccount = true;
      _accountError = null;
    });

    try {
      await context.read<AuthCubit>().refreshProfile();
      final authState = context.read<AuthCubit>().state;

      if (!authState.authenticated) {
        throw Exception('User not authenticated');
      }

      final userId = authState.user?['id']?.toString() ?? '';
      if (userId.isEmpty) {
        throw Exception('User ID not found');
      }

      Map<String, dynamic>? acc;
      try {
        acc = await _accountRepo.getByUser(userId);
      } catch (e) {
        final msg = e.toString().toLowerCase();
        if (!msg.contains('404') && !msg.contains('not found')) {
          rethrow;
        }
        acc = null;
      }

      if (!mounted) return;
      setState(() {
        _account = acc;
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

  Future<void> _loadTransactions() async {
    if (!mounted) return;
    setState(() => _loadingTx = true);

    try {
      final auth = context.read<AuthCubit>().state;
      final userId = auth.user?['id']?.toString() ?? '';
      if (userId.isEmpty) {
        throw Exception('User not authenticated');
      }

      final accountId = (_account?['id'] ?? _account?['account_id'] ?? '').toString();
      final res = await _paymentsRepo.listTransactions(
        userId: userId,
        accountId: accountId.isEmpty ? null : accountId,
        page: 1,
        pageSize: 10,
        type: 'all',
        status: 'all',
      );

      final items = (res['items'] as List?)?.cast<Map<String, dynamic>>() ?? [];

      if (!mounted) return;
      setState(() {
        _transactions = items;
        _loadingTx = false;
      });
    } catch (e) {
      debugPrint('Transaction loading error: $e');
      if (mounted) setState(() => _loadingTx = false);
    }
  }

  Future<void> _loadPotsTotal() async {
    try {
      final auth = context.read<AuthCubit>().state;
      final uid = (auth.user?['id'] ?? '').toString();
      if (uid.isEmpty) return;

      final pots = await _potsRepo.listPots(uid);
      double total = 0;
      for (final p in pots) {
        final v = p['current_balance'] ?? p['current_amount'] ?? p['balance'] ?? p['amount'] ?? 0;
        if (v is num) {
          total += v.toDouble();
        } else {
          total += double.tryParse(v.toString()) ?? 0;
        }
      }
      if (mounted) setState(() => _potsTotalBalance = total);
    } catch (_) {
      // Quietly ignore; this metric is best-effort
    }
  }

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
        final s = v.toLowerCase().trim();
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

  String _getUserDisplayName(Map<String, dynamic>? user) {
    if (user == null) return 'User';

    final firstName = (user['first_name'] ?? user['firstName'] ?? '').toString().trim();
    final lastName = (user['last_name'] ?? user['lastName'] ?? '').toString().trim();

    final fullName = '$firstName $lastName'.trim();
    if (fullName.isNotEmpty) return fullName;

    final name = (user['name'] ?? user['displayName'] ?? '').toString().trim();
    return name.isNotEmpty ? name : 'User';
  }

  Future<void> _ensureAccount() async {
    setState(() {
      _loadingAccount = true;
      _accountError = null;
    });

    // Helper for async context usage
    String t(String key) {
      if (!mounted) return key;
      final isSw = context.read<LocaleCubit>().state.languageCode == 'sw';
      final translations = {
        'account_opened': isSw ? 'Akaunti ya kazi imefunguliwa kikamilifu' : 'Career account opened successfully',
        'account_failed': isSw ? 'Imeshindikana kufungua akaunti' : 'Failed to open account',
      };
      return translations[key] ?? key;
    }

    try {
      final acc = await _accountRepo.ensureAccount();
      if (!mounted) return;

      setState(() => _account = acc);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Text(t('account_opened'), style: const TextStyle(color: Colors.white)),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 3),
          ),
        );
      }

      await context.read<AuthCubit>().refreshProfile();
      await _loadInitialData();
    } catch (e) {
      if (!mounted) return;
      setState(() => _accountError = e.toString());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(child: Text(t('account_failed'), style: const TextStyle(color: Colors.white))),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingAccount = false);
    }
  }

  double _balanceValue() {
    final v = _account?['balance'] ??
        _account?['current_balance'] ??
        _account?['current_amount'] ??
        0;
    return (v is num) ? v.toDouble() : double.tryParse(v.toString()) ?? 0.0;
  }

  void _handleTabChange(int index) {
    setState(() {
      _selectedIndex = index;
      _tabController
        ..reset()
        ..forward();
    });
  }

  @override
  void dispose() {
    _heroTimer?.cancel();
    _heroController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listenWhen: (p, c) => p.authenticated != c.authenticated || p.user != c.user,
      buildWhen: (p, c) => p.checking != c.checking || p.authenticated != c.authenticated,
      listener: (context, state) async {
        if (!state.authenticated && !state.checking) {
          Navigator.of(context).pushReplacementNamed('/login');
        } else if (state.authenticated && !_loadingAccount) {
          await _loadInitialData();
        }
      },
      builder: (context, authState) {
        if (authState.checking) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!authState.authenticated) {
          return const Scaffold(body: SizedBox.shrink());
        }

        // Define translation helper locally to ensure reactive updates
        final isSw = context.watch<LocaleCubit>().state.languageCode == 'sw';
        String t(String key) {
          final translations = {
            'retry': isSw ? 'Jaribu Tena' : 'Retry',
            'auth_error': isSw ? 'Hitilafu ya uthibitishaji' : 'Authentication error',
            'welcome': isSw ? 'Karibu' : 'Welcome',
            'open_account_desc': isSw 
                ? 'Fungua akaunti yako ya Misana ili kuanza kuwekeza katika ukuaji wako wa kitaaluma.' 
                : 'Open your Misana career account to start investing in your professional growth.',
            'open_account_btn': isSw ? 'Fungua Akaunti' : 'Open Account',
            'account_opened': isSw ? 'Akaunti ya kazi imefunguliwa kikamilifu' : 'Career account opened successfully',
            'account_failed': isSw ? 'Imeshindikana kufungua akaunti' : 'Failed to open account',
            'action_deposit': isSw ? 'Lipa' : 'Pay',
            'action_returns': isSw ? 'Toa' : 'Withdraw',
            'action_returns_soon': isSw ? 'Utoaji - Inakuja hivi karibuni' : 'Withdraw - Coming soon',
            'action_history': isSw ? 'Historia' : 'History',
            'action_career': isSw ? 'Mipango ya Kazi' : 'Career Plans',
          };
          return translations[key] ?? key;
        }

        return Scaffold(
          body: SafeArea(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: _buildCurrentPage(authState, t),
                ),
              ),
            ),
          ),
          bottomNavigationBar: CurvedNavigationBar(
            key: _navKey,
            index: _selectedIndex,
            height: _navBarHeight,
            items: const [
              Icon(Icons.dashboard_rounded, size: 28, color: Colors.white),
              Icon(Icons.savings_rounded, size: 28, color: Colors.white),
              Icon(Icons.person_rounded, size: 28, color: Colors.white),
            ],
            color: BrandColors.orange,
            buttonBackgroundColor: BrandColors.orange,
            backgroundColor: Colors.transparent,
            animationCurve: Curves.easeOutBack,
            animationDuration: const Duration(milliseconds: 500),
            onTap: _handleTabChange,
          ),
        );
      },
    );
  }

  Widget _buildCurrentPage(AuthState authState, String Function(String) t) {
    final pages = [
      _buildDashboard(authState, t),
      PotsListPage(repo: _potsRepo),
      const ProfilePage(),
    ];

    return IndexedStack(
      index: _selectedIndex,
      children: pages,
    );
  }

  Widget _buildDashboard(AuthState authState, String Function(String) t) {
    if (_loadingAccount) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_accountError != null) {
      return _buildErrorView(t);
    }

    final kyc = _normalizeKycFromUser(authState.user);
    final kycVerified = kyc == 'verified';
    final displayName = _getUserDisplayName(authState.user);

    if (_account == null) {
      return _buildNoAccountState(kycVerified, displayName, t);
    }

    return RefreshIndicator.adaptive(
      onRefresh: _loadInitialData,
      notificationPredicate: (n) {
        if (n is OverscrollNotification) {
          final progress = (n.metrics.pixels / 140).clamp(0.0, 1.0);
          setState(() => _pullProgress = progress);
        }
        return true;
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          AccountHeader(
            accountNumber: (_account?['external_account_id'] ??
                    _account?['account_number'] ??
                    '—')
                .toString(),
            status: (_account?['status'] ?? 'Active').toString(),
            balance: _balanceValue(),
            potsTotal: _potsTotalBalance,
            showBalance: _showBalance,
            onToggleBalance: () => setState(() => _showBalance = !_showBalance),
            userName: displayName,
            actions: _buildQuickActions(kycVerified: kycVerified, hasAccount: true, t: t),
          ),
          const SizedBox(height: 16),
          HeroBanner(
            controller: _heroController,
            images: _heroImages,
            currentIndex: _heroIndex,
            onPageChanged: (index) => setState(() => _heroIndex = index),
            progress: _pullProgress,
          ),
          const SizedBox(height: 24),
          TransactionList(
            loading: _loadingTx,
            transactions: _transactions,
            onViewAll: () {
              Navigator.push(
                context,
                PageTransitions.slideUp(page: TransactionsPage(repo: _paymentsRepo)),
              ).then((_) => _loadTransactions());
            },
          ),
          SizedBox(height: _navBarHeight + 16),
        ],
      ),
    );
  }

  Widget _buildErrorView(String Function(String) t) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 12),
            Text(
              _accountError!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: _checkAuthAndLoad,
              icon: const Icon(Icons.refresh),
              label: Text(t('retry')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoAccountState(bool kycVerified, String displayName, String Function(String) t) {
    return RefreshIndicator(
      onRefresh: _loadInitialData,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(18, 28, 18, 28),
            decoration: const BoxDecoration(
              color: BrandColors.orange,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${t('welcome')}, $displayName',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  t('open_account_desc'),
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _ensureAccount,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: BrandColors.orange,
                    ),
                    icon: const Icon(Icons.add_circle_outline),
                    label: Text(t('open_account_btn')),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          HeroBanner(
            controller: _heroController,
            images: _heroImages,
            currentIndex: _heroIndex,
            onPageChanged: (index) => setState(() => _heroIndex = index),
          ),
          const SizedBox(height: 24),
          const TransactionList(loading: false, transactions: []),
          SizedBox(height: _navBarHeight + 16),
        ],
      ),
    );
  }

  List<Widget> _buildQuickActions({
    required bool kycVerified,
    required bool hasAccount,
    required String Function(String) t,
  }) {
    return [
      QuickActionButton(
        icon: Icons.add_rounded,
        label: t('action_deposit'),
        enabled: hasAccount,
        onTap: () {
          Navigator.push(
            context,
            PageTransitions.slideUp(
              page: DepositPage(
                paymentsRepo: _paymentsRepo,
                potsRepo: _potsRepo,
                flow: PaymentFlow.deposit,
              ),
            ),
          ).then((_) => _loadInitialData());
        },
      ),
      QuickActionButton(
        icon: Icons.arrow_downward_rounded,
        label: t('action_returns'),
        enabled: hasAccount,
        onTap: () {
          Navigator.push(
            context,
            PageTransitions.slideUp(
              page: DepositPage(
                paymentsRepo: _paymentsRepo,
                potsRepo: _potsRepo,
                flow: PaymentFlow.withdraw,
              ),
            ),
          ).then((_) => _loadInitialData());
        },
      ),
      QuickActionButton(
        icon: Icons.receipt_long_rounded,
        label: t('action_history'),
        enabled: hasAccount,
        onTap: () {
          Navigator.push(
            context,
            PageTransitions.fadeScale(page: TransactionsPage(repo: _paymentsRepo)),
          ).then((_) => _loadTransactions());
        },
      ),
      QuickActionButton(
        icon: Icons.account_balance_rounded,
        label: t('action_career'),
        enabled: hasAccount,
        onTap: () => _handleTabChange(1),
      ),
    ];
  }
}
