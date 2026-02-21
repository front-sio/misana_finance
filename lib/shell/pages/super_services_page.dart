import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:misana_finance_app/miniapps/mini_app_contract.dart';
import 'package:misana_finance_app/miniapps/mini_app_registry.dart';

class SuperServicesPage extends StatefulWidget {
  const SuperServicesPage({super.key});

  @override
  State<SuperServicesPage> createState() => _SuperServicesPageState();
}

class _SuperServicesPageState extends State<SuperServicesPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int _columnsForWidth(double width) {
    if (width >= 1100) return 4;
    if (width >= 860) return 3;
    if (width >= 620) return 2;
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    final apps = MiniAppRegistry.all();
    final query = _query.trim().toLowerCase();
    final visibleApps = query.isEmpty
        ? apps
        : apps
            .where((app) =>
                app.title.toLowerCase().contains(query) ||
                app.description.toLowerCase().contains(query))
            .toList();
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Services',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: scheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Choose a mini app to get started.',
                          style: TextStyle(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  CircleAvatar(
                    backgroundColor: scheme.primary.withValues(alpha: 0.12),
                    child: Icon(Icons.apps_rounded, color: scheme.primary),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search services',
                  prefixIcon: const Icon(Icons.search_rounded),
                  filled: true,
                  fillColor: scheme.surfaceContainerHighest,
                ),
                onChanged: (value) => setState(() => _query = value),
              ),
            ),
            Expanded(
              child: FadeTransition(
                opacity: _fade,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = _columnsForWidth(constraints.maxWidth);
                    return GridView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: columns == 1 ? 1.6 : 1.2,
                      ),
                      itemCount: visibleApps.length,
                      itemBuilder: (context, index) {
                        final app = visibleApps[index];
                        final intervalStart = (index * 0.1).clamp(0.0, 0.6);
                        final itemAnim = CurvedAnimation(
                          parent: _controller,
                          curve: Interval(intervalStart, 1.0, curve: Curves.easeOut),
                        );
                        return FadeTransition(
                          opacity: itemAnim,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.08),
                              end: Offset.zero,
                            ).animate(itemAnim),
                            child: _MiniAppCard(app: app),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniAppCard extends StatelessWidget {
  final MiniAppContract app;

  const _MiniAppCard({required this.app});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => app.buildEntry()),
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: Ink(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              app.accentColor.withValues(alpha: 0.2),
              scheme.surface,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: scheme.outlineVariant),
          boxShadow: [
            BoxShadow(
              color: app.accentColor.withValues(alpha: 0.2),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: Icon(Icons.arrow_outward_rounded, color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 12),
              CircleAvatar(
                radius: 22,
                backgroundColor: app.accentColor.withValues(alpha: 0.2),
                child: Icon(app.icon, color: app.accentColor),
              ),
              const Spacer(),
              Text(
                app.title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                app.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: scheme.onSurfaceVariant,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    'Open',
                    style: TextStyle(
                      color: scheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(Icons.arrow_forward_rounded, color: scheme.primary, size: 16),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
