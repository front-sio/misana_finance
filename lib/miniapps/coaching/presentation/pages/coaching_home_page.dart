import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../coaching_routes.dart';
import '../../data/models.dart';
import '../bloc/coaches_bloc.dart';
import '../bloc/coaches_event.dart';
import '../bloc/coaches_state.dart';

class CoachingHomePage extends StatefulWidget {
  const CoachingHomePage({super.key});

  @override
  State<CoachingHomePage> createState() => _CoachingHomePageState();
}

class _CoachingHomePageState extends State<CoachingHomePage> {
  @override
  void initState() {
    super.initState();
    context.read<CoachesBloc>().add(const LoadCoaches());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Coaching & Sessions'),
        centerTitle: true,
      ),
      body: BlocBuilder<CoachesBloc, CoachesState>(
        builder: (context, state) {
          if (state is CoachesLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is CoachesFailure) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(state.message, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () =>
                          context.read<CoachesBloc>().add(const LoadCoaches()),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }
          if (state is CoachesLoaded) {
            return _CoachProfileView(
              profile: state.profile,
              onRefresh: () async =>
                  context.read<CoachesBloc>().add(const LoadCoaches()),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _CoachProfileView extends StatelessWidget {
  final CoachProfile profile;
  final Future<void> Function() onRefresh;

  const _CoachProfileView({required this.profile, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [scheme.primary, scheme.secondary],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: scheme.primary.withValues(alpha: 0.22),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: Colors.white.withValues(alpha: 0.18),
                      child: Text(
                        profile.name.isNotEmpty
                            ? profile.name[0].toUpperCase()
                            : 'C',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (profile.headline != null)
                            Text(
                              profile.headline!,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.flash_on, color: Colors.white, size: 16),
                          SizedBox(width: 6),
                          Text(
                            'Live 1:1',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (profile.bio != null && profile.bio!.trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    profile.bio!,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    _StatChip(
                      label: 'Topics',
                      value: '${profile.topics.length}',
                    ),
                    const SizedBox(width: 10),
                    if (profile.topics.isNotEmpty)
                      _StatChip(
                        label: 'From',
                        value:
                            '${profile.topics.first.price15.toStringAsFixed(0)} ${profile.topics.first.currency}',
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Pick a topic',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          ...profile.topics.map((topic) => _TopicTile(topic: topic)),
        ],
      ),
    );
  }
}

class _TopicTile extends StatelessWidget {
  final Topic topic;

  const _TopicTile({required this.topic});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.of(
            context,
          ).pushNamed(CoachingRoutes.topic, arguments: topic);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: scheme.primary.withValues(alpha: 0.12),
                ),
                child: Icon(Icons.headphones, color: scheme.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      topic.title,
                      style: TextStyle(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      topic.description ?? 'Personal coaching session',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _priceChip(
                          '${topic.price15.toStringAsFixed(0)} ${topic.currency} · 15m',
                          scheme,
                        ),
                        _priceChip(
                          '${topic.price30.toStringAsFixed(0)} ${topic.currency} · 30m',
                          scheme,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  Widget _priceChip(String text, ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: scheme.onSurface,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;

  const _StatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 12,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
