// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A widget that continuously animates a simple canvas draw so GPU work is in
/// flight when the [FlutterEngine] is destroyed.
class AnimatedTeardownStress extends StatefulWidget {
  const AnimatedTeardownStress({super.key, this.onResourcesReady});

  /// Called once the animation is running and has painted a frame.
  final VoidCallback? onResourcesReady;

  @override
  State<AnimatedTeardownStress> createState() => _AnimatedTeardownStressState();
}

class _AnimatedTeardownStressState extends State<AnimatedTeardownStress>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spin;

  @override
  void initState() {
    super.initState();
    _spin = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onResourcesReady?.call();
    });
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _spin,
      builder: (BuildContext context, Widget? child) {
        return CustomPaint(
          painter: _SpinPainter(phase: _spin.value),
        );
      },
    );
  }
}

class _SpinPainter extends CustomPainter {
  _SpinPainter({required this.phase});

  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(phase * 2 * math.pi);
    canvas.drawRect(
      Rect.fromCenter(center: Offset.zero, width: size.width * 0.6, height: size.height * 0.6),
      Paint()..color = Colors.orange,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_SpinPainter oldDelegate) => oldDelegate.phase != phase;
}
