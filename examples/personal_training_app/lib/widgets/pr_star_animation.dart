import 'package:flutter/material.dart';
import 'dart:math';

class PRStarAnimation extends StatefulWidget {
  final VoidCallback? onCompleted;
  const PRStarAnimation({super.key, this.onCompleted});

  @override
  State<PRStarAnimation> createState() => _PRStarAnimationState();
}

class _PRStarAnimationState extends State<PRStarAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _burstAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _scaleAnim = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    _burstAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
    );
    _controller.forward().whenComplete(() => widget.onCompleted?.call());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      height: 160,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Bursting stars
          ...List.generate(8, (i) {
            final angle = (2 * pi / 8) * i;
            return AnimatedBuilder(
              animation: _burstAnim,
              builder: (context, child) {
                final radius = 60 * _burstAnim.value;
                return Positioned(
                  left: 80 + radius * cos(angle) - 12,
                  top: 80 + radius * sin(angle) - 12,
                  child: Opacity(
                    opacity: _burstAnim.value,
                    child: Icon(Icons.star, color: Colors.amber, size: 24),
                  ),
                );
              },
            );
          }),
          // Central star with text
          ScaleTransition(
            scale: _scaleAnim,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.star, color: Colors.amber, size: 64),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    'New PR!',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
