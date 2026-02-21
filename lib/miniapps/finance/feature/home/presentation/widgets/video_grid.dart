import 'package:flutter/material.dart';
import 'package:misana_finance_app/core/animations/animated_press.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:misana_finance_app/core/theme/app_theme.dart';

class VideoGrid extends StatelessWidget {
  final List<VideoItem> items;

  const VideoGrid({
    super.key,
    required this.items,
  });

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
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 16 / 9,
        ),
        itemBuilder: (context, index) {
          return VideoCard(item: items[index]);
        },
      ),
    );
  }
}

class VideoItem {
  final String title;
  final String thumbnailUrl;
  final String videoUrl;
  final String? description;

  const VideoItem({
    required this.title,
    required this.thumbnailUrl,
    required this.videoUrl,
    this.description,
  });
}

class VideoCard extends StatefulWidget {
  final VideoItem item;

  const VideoCard({
    super.key,
    required this.item,
  });

  @override
  State<VideoCard> createState() => _VideoCardState();
}

class _VideoCardState extends State<VideoCard> with SingleTickerProviderStateMixin {
  late final AnimationController _hoverController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: Curves.easeOutCubic,
    ));
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  void _handleHoverStart() => _hoverController.forward();
  void _handleHoverEnd() => _hoverController.reverse();

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _handleHoverStart(),
      onExit: (_) => _handleHoverEnd(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        ),
        child: AnimatedPress(
          scale: 0.98,
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            // Handle video tap
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Opening: ${widget.item.title}')),
            );
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: widget.item.thumbnailUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.black12,
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.black12,
                    child: const Icon(
                      Icons.error_outline,
                      color: Colors.white54,
                    ),
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              Center(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: BrandColors.orange,
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Icon(
                    Icons.play_arrow_rounded,
                    size: 28,
                    color: BrandColors.orange,
                  ),
                ),
              ),
              Positioned(
                left: 12,
                right: 12,
                bottom: 10,
                child: Text(
                  widget.item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    shadows: [
                      Shadow(
                        color: Colors.black54,
                        blurRadius: 3,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}