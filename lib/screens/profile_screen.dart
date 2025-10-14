import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../services/api_service.dart';
import 'settings_screen.dart';
import 'update_profile_screen.dart';
import 'change_pin_screen.dart';
import 'change_password_screen.dart';
import 'login_screen.dart';
import 'accounts_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService api = ApiService();
  bool _loading = true;
  Map<String, dynamic>? _user;
  String? _error;

  // Account state
  bool _accountLoading = true;
  String _accountStatus = 'no-account';
  String? _externalAccountId;

  @override
  void initState() {
    super.initState();
    _fetchAll();
  }

  Future<void> _fetchAll() async {
    setState(() {
      _loading = true;
      _accountLoading = true;
      _error = null;
    });

    try {
      final profile = await api.getUserProfile();
      final accounts = await api.getAccounts(); // expects List<Map>
      String status = 'no-account';
      String? ext;
      if (accounts.isNotEmpty) {
        final acc = accounts.first;
        status = (acc['status'] ?? 'unknown').toString();
        ext = (acc['external_account_id'] ?? '').toString();
      }
      if (!mounted) return;
      setState(() {
        _user = profile;
        _loading = false;
        _accountStatus = status;
        _externalAccountId = ext?.isNotEmpty == true ? ext : null;
        _accountLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
        _accountLoading = false;
      });
    }
  }

  void _navigateTo(Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    ).then((_) => _fetchAll());
  }

  Color _statusColor(String status, Brightness b) {
    final s = status.toLowerCase();
    final dark = b == Brightness.dark;
    if (s == 'active' || s == 'approved' || s == 'verified') {
      return dark ? Colors.greenAccent : Colors.green;
    }
    if (s == 'pending') return dark ? Colors.amberAccent : Colors.amber;
    if (s == 'blocked' || s == 'closed' || s == 'rejected' || s == 'no-account') {
      return dark ? Colors.redAccent : Colors.red;
    }
    return dark ? Colors.blueGrey.shade200 : Colors.blueGrey;
  }

  IconData _statusIcon(String status) {
    final s = status.toLowerCase();
    if (s == 'active' || s == 'approved' || s == 'verified') return Icons.verified;
    if (s == 'pending') return Icons.hourglass_top;
    if (s == 'blocked' || s == 'closed' || s == 'rejected' || s == 'no-account') {
      return Icons.error_outline;
    }
    return Icons.info_outline;
  }

  String _statusText(String status) {
    final s = status.toLowerCase();
    if (s == 'no-account') return 'No Account';
    if (s == 'active' || s == 'approved' || s == 'verified') return 'Active';
    if (s == 'pending') return 'Pending';
    if (s == 'blocked') return 'Blocked';
    if (s == 'closed') return 'Closed';
    return status;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: _loading
          ? Center(
              child: Lottie.asset(
                'assets/loader.json',
                width: 120,
                height: 120,
                fit: BoxFit.contain,
              ),
            )
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Error: $_error",
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchAll,
                        child: const Text("Retry"),
                      ),
                    ],
                  ),
                )
              : CustomScrollView(
                  slivers: [
                    SliverAppBar(
                      pinned: true,
                      expandedHeight: 250,
                      backgroundColor: Colors.blue.shade800,
                      flexibleSpace: FlexibleSpaceBar(
                        background: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.blue.shade700,
                                Colors.blue.shade900
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(height: 20),
                              CircleAvatar(
                                radius: 45,
                                backgroundColor: Colors.white,
                                child: Icon(
                                  Icons.person,
                                  size: 50,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _user?['name'] ?? "",
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _user?['phone'] ?? "",
                                style: const TextStyle(color: Colors.white70),
                              ),
                              Text(
                                _user?['email'] ?? "",
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SliverList(
                      delegate: SliverChildListDelegate([
                        const SizedBox(height: 20),

                        // Account status card (Requirement 2: show Account status instead of KYC)
                        _accountStatusCard(context),

                        if (_externalAccountId != null) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Row(
                              children: [
                                const Icon(Icons.link, size: 16),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    "Linked Selcom ID: ${_externalAccountId!}",
                                    style: TextStyle(color: scheme.onSurfaceVariant),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 10),
                        _buildOption(
                          icon: Icons.edit,
                          title: "Update Profile",
                          onTap: () => _navigateTo(
                            UpdateProfileScreen(user: _user!),
                          ),
                        ),
                        _buildDivider(),
                        _buildOption(
                          icon: Icons.lock,
                          title: _user?['hasPin'] == true ? "Change PIN" : "Add PIN",
                          onTap: () {
                            if (_user != null) {
                              _navigateTo(
                                ChangePinScreen(hasPin: _user!['hasPin'] == true),
                              );
                            }
                          },
                        ),
                        _buildDivider(),
                        _buildOption(
                          icon: Icons.password,
                          title: "Change Password",
                          onTap: () => _navigateTo(const ChangePasswordScreen()),
                        ),
                        _buildDivider(),
                        _buildOption(
                          icon: Icons.settings,
                          title: "App Settings",
                          onTap: () => _navigateTo(const SettingsScreen()),
                        ),
                        _buildDivider(),
                        _buildOption(
                          icon: Icons.logout_outlined,
                          title: "Logout",
                          onTap: () async {
                            await api.logout(context);
                          },
                        ),
                        const SizedBox(height: 20),
                      ]),
                    )
                  ],
                ),
    );
  }

  Widget _accountStatusCard(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final statusText = _statusText(_accountStatus);
    final color = _statusColor(_accountStatus, brightness);
    final icon = _statusIcon(_accountStatus);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        elevation: 1.5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: color.withOpacity(0.12),
            child: Icon(icon, color: color),
          ),
          title: const Text("Account status"),
          subtitle: _accountLoading
              ? const Text("Checking...")
              : Text(statusText),
          trailing: _accountStatus == 'no-account'
              ? TextButton.icon(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AccountsScreen()),
                    );
                    _fetchAll();
                  },
                  icon: const Icon(Icons.open_in_new),
                  label: const Text("Open account"),
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue.shade700),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  Widget _buildDivider() => const Divider(height: 1);
}