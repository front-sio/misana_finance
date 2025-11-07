import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';

import 'package:misana_finance_app/core/theme/app_theme.dart';
import 'package:misana_finance_app/core/transitions/page_transition.dart';

import 'package:misana_finance_app/feature/session/auth_cubit.dart';
import 'package:misana_finance_app/feature/session/auth_state.dart';

import 'package:misana_finance_app/feature/account/domain/account_repository.dart';
import 'package:misana_finance_app/feature/payments/domain/payments_repository.dart';
import 'package:misana_finance_app/feature/pots/domain/pots_repository.dart';

import 'package:misana_finance_app/feature/auth/presentation/pages/profile_page.dart';
import 'package:misana_finance_app/feature/pots/presentation/pages/pots_list_page.dart';
import 'package:misana_finance_app/feature/payments/presentation/pages/deposit_page.dart';
import 'package:misana_finance_app/feature/payments/presentation/pages/transactions_page.dart';

import 'package:misana_finance_app/feature/home/presentation/widgets/account_header.dart';
import 'package:misana_finance_app/feature/home/presentation/widgets/hero_banner.dart';
import 'package:misana_finance_app/feature/home/presentation/widgets/quick_action_button.dart';
import 'package:misana_finance_app/feature/home/presentation/widgets/transction_list.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

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

  bool _loadingTx = true;
  List<Map<String, dynamic>> _transactions = const [];

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
    ]);
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

      final kyc = _normalizeKycFromUser(authState.user);
      if (kyc != 'verified') {
        if (!mounted) return;
        setState(() {
          _account = null;
          _loadingAccount = false;
        });
        return;
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

      final kyc = _normalizeKycFromUser(auth.user);
      if (kyc != 'verified') {
        if (mounted) setState(() => _loadingTx = false);
        return;
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
    final auth = context.read<AuthCubit>().state;
    final kyc = _normalizeKycFromUser(auth.user);

    if (kyc != 'verified') {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Complete verification first')),
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

      setState(() => _account = acc);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                SizedBox(width: 12),
                Text('Account opened successfully', style: TextStyle(color: Colors.white)),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(16),
            duration: Duration(seconds: 3),
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
                Icon(Icons.error_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(child: Text('Failed to open account', style: const TextStyle(color: Colors.white))),
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

        return Scaffold(
          body: SafeArea(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: _buildCurrentPage(authState),
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

  Widget _buildCurrentPage(AuthState authState) {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboard(authState);
      case 1:
        return PotsListPage(repo: _potsRepo);
      case 2:
        return const ProfilePage();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildDashboard(AuthState authState) {
    if (_loadingAccount) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_accountError != null) {
      return _buildErrorView();
    }

    final kyc = _normalizeKycFromUser(authState.user);
    final kycVerified = kyc == 'verified';
    final displayName = _getUserDisplayName(authState.user);

    if (_account == null) {
      return _buildNoAccountState(kycVerified, displayName);
    }

    return RefreshIndicator(
      onRefresh: _loadInitialData,
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
            showBalance: _showBalance,
            onToggleBalance: () => setState(() => _showBalance = !_showBalance),
            userName: displayName,
            actions: _buildQuickActions(kycVerified: kycVerified, hasAccount: true),
          ),
          const SizedBox(height: 16),
          HeroBanner(
            controller: _heroController,
            images: _heroImages,
            currentIndex: _heroIndex,
            onPageChanged: (index) => setState(() => _heroIndex = index),
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

  Widget _buildErrorView() {
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
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoAccountState(bool kycVerified, String displayName) {
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
                  'Welcome, $displayName',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  kycVerified
                      ? 'Open your Misana saving account to start saving securely.'
                      : 'Complete your verification (KYC) to open a Misana saving account.',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: kycVerified ? _ensureAccount : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: BrandColors.orange,
                    ),
                    icon: const Icon(Icons.add_circle_outline),
                    label: const Text('Open Account'),
                  ),
                ),
                if (!kycVerified) ...[
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () => Navigator.of(context)
                        .pushNamed('/kyc')
                        .then((_) => _loadInitialData()),
                    icon: const Icon(Icons.verified_outlined, color: Colors.white),
                    label: const Text(
                      'Complete verification',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
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
  }) {
    return [
      QuickActionButton(
        icon: Icons.add_rounded,
        label: 'Deposit',
        enabled: kycVerified && hasAccount,
        onTap: () {
          Navigator.push(
            context,
            PageTransitions.slideUp(
              page: DepositPage(paymentsRepo: _paymentsRepo, potsRepo: _potsRepo),
            ),
          ).then((_) => _loadInitialData());
        },
      ),
      QuickActionButton(
        icon: Icons.arrow_upward_rounded,
        label: 'Withdraw',
        enabled: kycVerified && hasAccount,
        onTap: () =>
            Navigator.pushNamed(context, '/withdraw').then((_) => _loadInitialData()),
      ),
      QuickActionButton(
        icon: Icons.receipt_long_rounded,
        label: 'History',
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
        label: 'Pots',
        enabled: kycVerified && hasAccount,
        onTap: () => _handleTabChange(1),
      ),
    ];
  }
}