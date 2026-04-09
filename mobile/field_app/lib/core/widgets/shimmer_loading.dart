import 'dart:math' as math;

import 'package:flutter/material.dart';

class ShimmerCard extends StatefulWidget {
  const ShimmerCard({
    super.key,
    this.height = 116,
    this.radius = 24,
  });

  final double height;
  final double radius;

  @override
  State<ShimmerCard> createState() => _ShimmerCardState();
}

class _ShimmerCardState extends State<ShimmerCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        final start = -1.4 + (2.6 * t);
        final end = start + 0.9;
        return Container(
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              begin: Alignment(math.max(-1, start), 0),
              end: Alignment(math.min(1, end), 0),
              colors: [
                cs.surfaceContainerLow,
                cs.surfaceContainerHighest,
                cs.surfaceContainerLow,
              ],
            ),
          ),
        );
      },
    );
  }
}

class ShimmerList extends StatelessWidget {
  const ShimmerList({
    super.key,
    this.count = 3,
    this.padding = const EdgeInsets.all(20),
  });

  final int count;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: padding,
      itemCount: count,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (_, __) => const ShimmerCard(),
    );
  }
}
