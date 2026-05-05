import 'package:flutter/material.dart';

/// A simple shimmer placeholder — animated gradient sweep over a rounded box.
/// Used to replace CircularProgressIndicator in loading states.
class ShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  final double radius;

  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.radius = 8,
  });

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        final t = _ctrl.value;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              begin: Alignment(t - 1.2, 0),
              end: Alignment(t + 0.2, 0),
              colors: const [
                Color(0xFFE8E0D4),
                Color(0xFFF4F0E8),
                Color(0xFFE8E0D4),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Full shimmer placeholder for a collection grid card (mimics ItemCard shape).
class ShimmerItemCard extends StatelessWidget {
  const ShimmerItemCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const ShimmerBox(width: double.infinity, height: 120, radius: 8),
        const SizedBox(height: 8),
        const ShimmerBox(width: 100, height: 14, radius: 4),
        const SizedBox(height: 4),
        const ShimmerBox(width: 60, height: 12, radius: 4),
      ],
    );
  }
}

/// Shimmer placeholder for a list tile (mimics a collection list entry).
class ShimmerListTile extends StatelessWidget {
  const ShimmerListTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const ShimmerBox(width: 44, height: 44, radius: 8),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                ShimmerBox(width: 160, height: 14, radius: 4),
                SizedBox(height: 6),
                ShimmerBox(width: 100, height: 12, radius: 4),
              ],
            ),
          ),
          const ShimmerBox(width: 80, height: 28, radius: 6),
        ],
      ),
    );
  }
}

/// Shimmer for the home screen hero area (progress ring + greeting).
class ShimmerHomeHero extends StatelessWidget {
  const ShimmerHomeHero({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          ShimmerBox(width: 120, height: 120, radius: 60),
          SizedBox(height: 16),
          ShimmerBox(width: 200, height: 18, radius: 4),
          SizedBox(height: 8),
          ShimmerBox(width: 140, height: 14, radius: 4),
        ],
      ),
    );
  }
}
