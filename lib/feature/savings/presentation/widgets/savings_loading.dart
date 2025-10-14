import 'package:flutter/material.dart';

class SavingsLoadingView extends StatelessWidget {
  const SavingsLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Container(
            height: 168,
            decoration: BoxDecoration(
              color: scheme.surfaceVariant.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: scheme.outlineVariant.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Container(
                  height: 70,
                  decoration: BoxDecoration(
                    color: scheme.surfaceVariant.withOpacity(0.3),
                    borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        _Shimmer(width: 120, height: 24, color: scheme.surfaceVariant),
                        _Shimmer(width: 80, height: 24, color: scheme.surfaceVariant),
                      ]),
                      const SizedBox(height: 16),
                      _Shimmer(width: double.infinity, height: 10, color: scheme.surfaceVariant),
                    ]),
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

class _Shimmer extends StatefulWidget {
  final double width;
  final double height;
  final Color color;

  const _Shimmer({required this.width, required this.height, required this.color});

  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat();
    _animation =
        Tween<double>(begin: 0.3, end: 0.8).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (_, __) => Container(
        width: widget.width,
        height: widget.height,
        decoration:
            BoxDecoration(color: widget.color.withOpacity(_animation.value), borderRadius: BorderRadius.circular(4)),
      ),
    );
  }
}