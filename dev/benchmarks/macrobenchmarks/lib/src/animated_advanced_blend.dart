// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

class _MultiplyPainter extends CustomPainter {
  _MultiplyPainter(this._color);

  final Color _color;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;

    final Paint yellowPaint = Paint()..color = Colors.yellow;
    canvas.drawRect(rect, yellowPaint);

    final Paint purplePaint = Paint()
      ..color = _color
      ..blendMode = BlendMode.multiply;
    canvas.drawRect(rect, purplePaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}

class AnimatedAdvancedBlend extends StatefulWidget {
  const AnimatedAdvancedBlend({ super.key });

  @override
  State<AnimatedAdvancedBlend> createState() => _AnimatedBlurBackdropFilterState();
}

class _AnimatedBlurBackdropFilterState extends State<AnimatedAdvancedBlend> with SingleTickerProviderStateMixin {
  late final AnimationController controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 5000));
  late final Animation<double> animation = controller.drive(Tween<double>(begin: 0.0, end: 1.0));
  Color _color = const Color.fromARGB(255, 255, 0, 255);

  @override
  void initState() {
    super.initState();
    controller.repeat();
    animation.addListener(() {
      setState(() {
        _color = Color.fromARGB((animation.value * 255).floor(), 255, 0, 255);
      });
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        home: Scaffold(
      body: CustomPaint(
        painter: _MultiplyPainter(_color),
        child: Container(),
      ),
    ));
  }
}
