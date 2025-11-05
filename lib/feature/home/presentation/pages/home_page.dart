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

// Home widgets
import 'package:misana_finance_app/feature/home/presentation/widgets/account_header.dart';
import 'package:misana_finance_app/feature/home/presentation/widgets/hero_banner.dart';
import 'package:misana_finance_app/feature/home/presentation/widgets/video_grid.dart';
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

  // Animations
  late final AnimationController _tabController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;

  // Bottom tabs
  int _selectedIndex = 0;

  // UI state
  bool _showBalance = false;

  // Banners
  final _heroController = PageController(viewportFraction: 0.9);
  Timer? _heroTimer;
  int _heroIndex = 0;

  // Account state
  bool _loadingAccount = true;
  String? _accountError;
  Map<String, dynamic>? _account;

  // Tx state
  bool _loadingTx = true;
  List<Map<String, dynamic>> _transactions = const [];

  // Repos
  AccountRepository get _accountRepo => context.read<AccountRepository>();
  PaymentsRepository get _paymentsRepo => context.read<PaymentsRepository>();
  PotsRepository get _potsRepo => context.read<PotsRepository>();

  // Banners images
  final List<String> _heroImages = const [
    'https://picsum.photos/seed/misana2/1200/600',
    'https://picsum.photos/seed/misana3/1200/600',
  ];

  // Videos
  final List<VideoItem> _videos = const [
    VideoItem(
      title: 'Jinsi ya kuweka akiba',
      thumbnailUrl: 'https://picsum.photos/seed/video2/800/450',
      videoUrl: 'https://example.com/video2',
    ),
    VideoItem(
      title: 'Faida za Misana Saving',
      thumbnailUrl: 'https://picsum.photos/seed/video3/800/450',
      videoUrl: 'https://example.com/video3',
    ),
    VideoItem(
      title: 'Jinsi ya kutoa fedha',
      thumbnailUrl: 'https://picsum.photos/seed/video1/800/450',
      videoUrl: 'https://example.com/video1',
    ),
    VideoItem(
      title: 'Bonasi na promosheni',
      thumbnailUrl: 'https://picsum.photos/seed/video4/800/450',
      videoUrl: 'https://example.com/video4',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startHeroAutoSwipe();
    _checkAuthAndLoad();
  }

  void _setupAnimations() {
    _tabController = AnimationController(duration: const Duration(milliseconds: 300), vsync: this);
    _fadeAnimation = CurvedAnimation(parent: _tabController, curve: Curves.easeOutCubic);
    _scaleAnimation = Tween(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _tabController, curve: Curves.easeOutCubic),
    );
    _tabController.forward();
  }

  void _startHeroAutoSwipe() {
    _heroTimer?.cancel();
    _heroTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || _heroImages.isEmpty) return;
      setState(() {
        _heroIndex = (_heroIndex + 1) % _heroImages.length;
        _heroController.animateToPage(
          _heroIndex,
          duration: const Duration(milliseconds: 580),
          curve: Curves.easeOutCubic,
        );
      });
    });
  }

  Future<void> _checkAuthAndLoad() async {
    try {
      await context.read<AuthCubit>().checkSession();
      final auth = context.read<AuthCubit>().state;
      if (!mounted) return;
      if (auth.authenticated) {
        await _loadInitialData();
      } else {
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
    await _refreshAccount();
    await _loadTransactions();
  }

  Future<void> _refreshAccount() async {
    if (!mounted) return;
    setState(() {
      _loadingAccount = true;
      _accountError = null;
    });

    try {
      // Ensure we have updated user profile
      await context.read<AuthCubit>().refreshProfile();
      final authState = context.read<AuthCubit>().state;

      if (!authState.authenticated) {
        throw Exception('User not authenticated');
      }

      final userId = authState.user?['id']?.toString() ?? '';
      if (userId.isEmpty) {
        throw Exception('User not authenticated');
      }

      Map<String, dynamic>? acc;
      try {
        acc = await _accountRepo.getByUser(userId);
      } catch (e) {
        // If backend returns 404 or similar, treat as no account (null)
        final msg = e.toString().toLowerCase();
        if (msg.contains('404') || msg.contains('not found')) {
          acc = null;
        } else {
          rethrow;
        }
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
      final items = (res['items'] as List?)?.cast<Map<String, dynamic>>() ?? const <Map<String, dynamic>>[];

      if (!mounted) return;
      setState(() {
        _transactions = items;
        _loadingTx = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingTx = false);
    }
  }

  // Normalizes KYC status from various potential fields
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

  Future<void> _ensureAccount() async {
    final auth = context.read<AuthCubit>().state;
    final kyc = _normalizeKycFromUser(auth.user);
    if (kyc != 'verified') {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Complete verification first.')),
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Account opened')),
      );
      await context.read<AuthCubit>().refreshProfile();
      await _loadInitialData();
    } catch (e) {
      if (!mounted) return;
      setState(() => _accountError = e.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to open account: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _loadingAccount = false);
      }
    }
  }

  // UI helpers
  double _balanceValue() {
    final v = _account?['balance'] ?? _account?['current_balance'] ?? _account?['current_amount'] ?? 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
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
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (!authState.authenticated) {
          // While navigation happens, keep a blank safe view
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
            color: BrandColors.purple,
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
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
              const SizedBox(height: 12),
              Text(_accountError!, textAlign: TextAlign.center),
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

    final kyc = _normalizeKycFromUser(authState.user);
    final kycVerified = kyc == 'verified';

    // No account yet
    if (_account == null) {
      return _noAccountState(kycVerified);
    }

    // Account dashboard
    return RefreshIndicator(
      onRefresh: _loadInitialData,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          AccountHeader(
            accountNumber: (_account?['external_account_id'] ?? _account?['account_number'] ?? '—').toString(),
            status: (_account?['status'] ?? 'Active').toString(),
            balance: _balanceValue(),
            showBalance: _showBalance,
            onToggleBalance: () => setState(() => _showBalance = !_showBalance),
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
          VideoGrid(items: _videos),
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

  Widget _noAccountState(bool kycVerified) {
    return RefreshIndicator(
      onRefresh: _loadInitialData,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          // A simple header (without balance) that invites opening an account
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(18, 28, 18, 28),
            decoration: const BoxDecoration(
              color: BrandPalette.purple,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Misana Saving', style: TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 6),
                const Text(
                  'Welcome 👋',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18),
                ),
                const SizedBox(height: 12),
                Text(
                  kycVerified
                      ? 'Open your Misana saving account to start saving securely.'
                      : 'Complete your verification (KYC) to open a Misana saving account.',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: kycVerified ? _ensureAccount : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: BrandPalette.orange,
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.add_circle_outline),
                        label: const Text('Open Account'),
                      ),
                    ),
                  ],
                ),
                if (!kycVerified) ...[
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () => Navigator.of(context).pushNamed('/kyc').then((_) => _loadInitialData()),
                    icon: const Icon(Icons.verified_outlined, color: Colors.white),
                    label: const Text('Complete verification', style: TextStyle(color: Colors.white)),
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
          VideoGrid(items: _videos),
          const SizedBox(height: 24),
          // No transactions yet section
          const TransactionList(loading: false, transactions: []),
          SizedBox(height: _navBarHeight + 16),
        ],
      ),
    );
  }

  List<Widget> _buildQuickActions({required bool kycVerified, required bool hasAccount}) {
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
        onTap: () => Navigator.pushNamed(context, '/withdraw').then((_) => _loadInitialData()),
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