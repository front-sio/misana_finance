import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:misana_finance_app/auth/session/auth_cubit.dart';
import 'package:misana_finance_app/auth/session/auth_state.dart';
import 'package:misana_finance_app/miniapps/finance/finance_app.dart';
import 'package:misana_finance_app/miniapps/mini_app_contract.dart';
import 'package:misana_finance_app/miniapps/mini_app_registry.dart';

class SuperHomePage extends StatefulWidget {
  final VoidCallback onExploreServices;

  const SuperHomePage({super.key, required this.onExploreServices});

  @override
  State<SuperHomePage> createState() => _SuperHomePageState();
}

class _SuperHomePageState extends State<SuperHomePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _heroFade;
  late final Animation<Offset> _heroSlide;
  late final Animation<double> _sectionFade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _heroFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );
    _heroSlide = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.1, 0.8, curve: Curves.easeOutCubic),
          ),
        );
    _sectionFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _displayName(Map<String, dynamic>? user) {
    if (user == null || user.isEmpty) return 'Guest';
    final first = (user['first_name'] ?? user['firstName'] ?? '')
        .toString()
        .trim();
    final last = (user['last_name'] ?? user['lastName'] ?? '')
        .toString()
        .trim();
    final combined = [first, last].where((v) => v.isNotEmpty).join(' ');
    if (combined.isNotEmpty) return combined;
    final username = (user['username'] ?? user['email'] ?? user['phone'] ?? '')
        .toString()
        .trim();
    return username.isNotEmpty ? username : 'Member';
  }

  void _openFinanceRoute(String route) {
    HapticFeedback.selectionClick();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FinanceApp(
          embedded: true,
          useParentAuthCubit: true,
          initialRoute: route,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final apps = MiniAppRegistry.all();
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          final displayName = _displayName(state.user);
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                expandedHeight: 220,
                elevation: 0,
                backgroundColor: scheme.surface,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          scheme.primary.withValues(alpha: 0.95),
                          scheme.tertiary.withValues(alpha: 0.85),
                          scheme.secondary.withValues(alpha: 0.8),
                        ],
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          top: -40,
                          right: -30,
                          child: Container(
                            width: 160,
                            height: 160,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.12),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: -30,
                          left: -20,
                          child: Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.08),
                            ),
                          ),
                        ),
                        SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                            child: FadeTransition(
                              opacity: _heroFade,
                              child: SlideTransition(
                                position: _heroSlide,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _greeting(),
                                      style: TextStyle(
                                        color: Colors.white.withValues(
                                          alpha: 0.9,
                                        ),
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      displayName,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 26,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(
                                          alpha: 0.18,
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.auto_awesome,
                                            color: Colors.white,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Your super app hub',
                                            style: TextStyle(
                                              color: Colors.white.withValues(
                                                alpha: 0.95,
                                              ),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _sectionFade,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionHeader(
                          title: 'Quick actions',
                          action: 'Customize',
                          onAction: () {
                            HapticFeedback.selectionClick();
                          },
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _QuickActionCard(
                                icon: Icons.add_card_rounded,
                                label: 'Top up',
                                accent: scheme.primary,
                                onTap: () => _openFinanceRoute('/deposit'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _QuickActionCard(
                                icon: Icons.swap_horiz_rounded,
                                label: 'Transfer',
                                accent: scheme.secondary,
                                onTap: () => _openFinanceRoute('/pots'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _QuickActionCard(
                                icon: Icons.receipt_long_rounded,
                                label: 'Bills',
                                accent: scheme.tertiary,
                                onTap: () => _openFinanceRoute('/transactions'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _SectionHeader(
                          title: 'Mini apps',
                          action: 'View all',
                          onAction: widget.onExploreServices,
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 190,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: apps.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 12),
                            itemBuilder: (context, index) {
                              final app = apps[index];
                              return _MiniAppPreviewCard(app: app);
                            },
                          ),
                        ),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                scheme.surfaceContainerHighest,
                                scheme.surface,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: scheme.outlineVariant),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: scheme.primary.withValues(
                                  alpha: 0.15,
                                ),
                                child: Icon(
                                  Icons.workspace_premium_rounded,
                                  color: scheme.primary,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Unlock more with Misana+',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: scheme.onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Priority support, exclusive sessions, and premium tools.',
                                      style: TextStyle(
                                        color: scheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String action;
  final VoidCallback onAction;

  const _SectionHeader({
    required this.title,
    required this.action,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: scheme.onSurface,
          ),
        ),
        TextButton(
          onPressed: onAction,
          style: TextButton.styleFrom(
            foregroundColor: scheme.primary,
            textStyle: const TextStyle(fontWeight: FontWeight.w700),
          ),
          child: Text(action),
        ),
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accent;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accent.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: accent, size: 24),
            const SizedBox(height: 10),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _MiniAppPreviewCard extends StatelessWidget {
  final MiniAppContract app;

  const _MiniAppPreviewCard({required this.app});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 170,
      child: InkWell(
        onTap: () {
          if (app.comingSoon) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${app.title} is coming soon'),
                duration: const Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
              ),
            );
            return;
          }
          HapticFeedback.lightImpact();
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => app.buildEntry()));
        },
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [app.accentColor.withValues(alpha: 0.18), scheme.surface],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: scheme.outlineVariant),
            boxShadow: [
              BoxShadow(
                color: app.accentColor.withValues(alpha: 0.18),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: app.accentColor.withValues(alpha: 0.2),
                      child: Icon(app.icon, color: app.accentColor),
                    ),
                    const Spacer(),
                    if (app.comingSoon)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: scheme.onSurface.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: scheme.outlineVariant),
                        ),
                        child: Text(
                          'Soon',
                          style: TextStyle(
                            color: scheme.onSurface,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ),
                  ],
                ),
                const Spacer(),
                Text(
                  app.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  app.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
