import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import '../services/api_service.dart';
import 'accounts_screen.dart';
import 'deposit_screen.dart';
import 'withdraw_screen.dart';
import 'profile_screen.dart';

final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with RouteAware {
  final ApiService api = ApiService();

  int _selectedIndex = 0;
  bool _isLoading = true;
  List<Map<String, dynamic>> _accounts = [];
  int _selectedAccountIndex = 0;
  bool _showBalance = false;

  final GlobalKey<CurvedNavigationBarState> _bottomNavigationKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)! as PageRoute);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    setState(() => _isLoading = true);
    try {
      final accounts = await api.getAccounts();
      if (!mounted) return;
      setState(() {
        _accounts = accounts;
        _selectedAccountIndex = accounts.isNotEmpty ? 0 : 0;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load accounts: $e")),
      );
    }
  }

  void _toggleBalance() => setState(() => _showBalance = !_showBalance);

  void _changeAccount(int? index) {
    if (index != null) setState(() => _selectedAccountIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _buildDashboard(context),
      const AccountsScreen(),
      // NOTE: ProfileScreen now derives account status internally, keep constructor empty
      const ProfileScreen(),
    ];

    return Scaffold(
      extendBody: true,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        transitionBuilder: (child, animation) {
          final offsetAnimation = Tween<Offset>(
            begin: const Offset(0.1, 0.1),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));

          final fadeAnimation = CurvedAnimation(
            parent: animation,
            curve: Curves.easeIn,
          );

          return SlideTransition(
            position: offsetAnimation,
            child: FadeTransition(
              opacity: fadeAnimation,
              child: child,
            ),
          );
        },
        child: pages[_selectedIndex],
      ),
      bottomNavigationBar: CurvedNavigationBar(
        key: _bottomNavigationKey,
        index: _selectedIndex,
        height: 60,
        items: const <Widget>[
          Icon(Icons.dashboard, size: 30, color: Colors.white),
          Icon(Icons.account_balance, size: 30, color: Colors.white),
          Icon(Icons.person, size: 30, color: Colors.white),
        ],
        color: Colors.blue.shade800,
        buttonBackgroundColor: Colors.blue.shade600,
        backgroundColor: Colors.transparent,
        animationCurve: Curves.elasticOut,
        animationDuration: const Duration(milliseconds: 600),
        onTap: (index) => setState(() => _selectedIndex = index),
        letIndexChange: (index) => true,
      ),
    );
  }

  // ---------- Dashboard ----------
  Widget _buildDashboard(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Lottie.asset('assets/loader.json', width: 100, height: 100),
        ),
      );
    }

    final hasAccounts = _accounts.isNotEmpty;
    Map<String, dynamic>? selectedAccount =
        hasAccounts ? _accounts[_selectedAccountIndex] : null;

    double totalSaved = (selectedAccount?['balance'] ?? 0).toDouble();

    // read pots (from backend response)
    List pots = selectedAccount?['pots'] ?? [];

    return hasAccounts
        ? RefreshIndicator(
            onRefresh: _loadAccounts,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  // Balance Section
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOutCubic,
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF1565C0), Color(0xFF1E88E5)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            DropdownButton<int>(
                              dropdownColor: Colors.blue.shade700,
                              value: _selectedAccountIndex,
                              style: const TextStyle(color: Colors.white, fontSize: 16),
                              underline: const SizedBox(),
                              iconEnabledColor: Colors.white,
                              items: List.generate(_accounts.length, (index) {
                                return DropdownMenuItem(
                                  value: index,
                                  child: Text(_accounts[index]['phone'] ?? "Account"),
                                );
                              }),
                              onChanged: _changeAccount,
                            ),
                            const SizedBox(width: 16),
                            InkWell(
                              onTap: _toggleBalance,
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 400),
                                transitionBuilder: (child, anim) =>
                                    ScaleTransition(scale: anim, child: child),
                                child: Icon(
                                  _showBalance ? Icons.visibility : Icons.visibility_off,
                                  key: ValueKey(_showBalance),
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 600),
                          transitionBuilder: (child, anim) =>
                              ScaleTransition(scale: anim, child: child),
                          child: _showBalance
                              ? TweenAnimationBuilder<double>(
                                  key: ValueKey(totalSaved),
                                  tween: Tween(begin: 0.0, end: totalSaved),
                                  duration: const Duration(milliseconds: 1000),
                                  curve: Curves.easeOutCubic,
                                  builder: (_, value, __) => Text(
                                    "TZS ${value.toStringAsFixed(2)}",
                                    style: const TextStyle(
                                        fontSize: 30,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white),
                                  ),
                                )
                              : const Text(
                                  "TZS *****",
                                  key: ValueKey("hidden"),
                                  style: TextStyle(
                                      fontSize: 30,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white),
                                ),
                        ),
                        const SizedBox(height: 30),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildCircleActionButton(
                              context,
                              Icons.file_download,
                              "Deposit",
                              DepositScreen(accountId: selectedAccount!['id']),
                            ),
                            _buildCircleActionButton(
                              context,
                              Icons.file_upload,
                              "Withdraw",
                              WithdrawScreen(accountId: selectedAccount['id']),
                            ),
                            _buildCircleActionButton(
                              context,
                              Icons.account_balance,
                              "My Accounts",
                              const AccountsScreen(),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // My Savings Pots Section
                  Container(
                    color: Colors.white,
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "My Savings Pots",
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black),
                        ),
                        const SizedBox(height: 16),
                        pots.isEmpty
                            ? const Text(
                                "No pots found. Create one to start saving!",
                                style: TextStyle(color: Colors.grey),
                              )
                            : Column(
                                children: pots.map((pot) {
                                  double saved = (pot['saved'] ?? 0).toDouble();
                                  double goal = (pot['goal'] ?? 0).toDouble();
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: _buildSavingPotItem(
                                      pot['name'] ?? "Pot",
                                      goal,
                                      saved,
                                      Icons.savings,
                                      Colors.blue.withOpacity(0.2),
                                      Colors.blue,
                                    ),
                                  );
                                }).toList(),
                              ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
        : Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.account_balance_outlined, size: 56, color: Colors.blue.shade700),
                  const SizedBox(height: 12),
                  Text(
                    // Requirement 1: show only message when there is NO account (hide "Create Saving Account")
                    "You don’t have an account yet. Please open an account to start saving.",
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  // Optional helper: let user go to Accounts
                  OutlinedButton.icon(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AccountsScreen()),
                      );
                      _loadAccounts();
                    },
                    icon: const Icon(Icons.open_in_new),
                    label: const Text("Go to Accounts"),
                  ),
                ],
              ),
            ),
          );
  }

  // ---------- Reusable Widgets ----------
  Widget _buildCircleActionButton(
      BuildContext context, IconData icon, String label, Widget page) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => page,
          transitionsBuilder: (context, anim, secAnim, child) {
            final offsetAnimation = Tween<Offset>(
              begin: const Offset(0.2, 0.2),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic));
            return SlideTransition(
              position: offsetAnimation,
              child: FadeTransition(opacity: anim, child: child),
            );
          },
        ),
      ),
      borderRadius: BorderRadius.circular(50),
      child: Column(
        children: [
          Container(
            decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
            padding: const EdgeInsets.all(16),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildSavingPotItem(
      String name, double goal, double saved, IconData icon, Color bgColor, Color progressColor) {
    double progress = goal == 0 ? 0 : saved / goal;
    return Card(
      color: bgColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: progressColor,
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: const TextStyle(
                          color: Colors.black87, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: progress),
                    duration: const Duration(milliseconds: 600),
                    builder: (context, value, _) => LinearProgressIndicator(
                      value: value,
                      color: progressColor,
                      backgroundColor: Colors.black12,
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Saved: TZS ${saved.toStringAsFixed(0)} / Goal: TZS ${goal.toStringAsFixed(0)}",
                    style: const TextStyle(color: Colors.black54, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.black54, size: 16),
          ],
        ),
      ),
    );
  }
}