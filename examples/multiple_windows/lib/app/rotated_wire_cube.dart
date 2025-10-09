// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart';
import 'dart:math';

class RotatedWireCube extends StatefulWidget {
  const RotatedWireCube({required this.cubeColor, super.key});

  final Color cubeColor;

  @override
  State<StatefulWidget> createState() => _RotatedWireCubeState();
}

class _RotatedWireCubeState extends State<RotatedWireCube>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animation;

  @override
  void initState() {
    super.initState();
    _animation = AnimationController(
      vsync: this,
      lowerBound: 0,
      upperBound: 2 * pi,
      duration: const Duration(seconds: 15),
    )..repeat();
  }

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(200, 200),
          painter: _RotatedWireCubePainter(
            angle: _animation.value,
            color: widget.cubeColor,
          ),
        );
      },
    );
  }
}

class _RotatedWireCubePainter extends CustomPainter {
  static List<Vector3> vertices = [
    Vector3(-0.5, -0.5, -0.5),
    Vector3(0.5, -0.5, -0.5),
    Vector3(0.5, 0.5, -0.5),
    Vector3(-0.5, 0.5, -0.5),
    Vector3(-0.5, -0.5, 0.5),
    Vector3(0.5, -0.5, 0.5),
    Vector3(0.5, 0.5, 0.5),
    Vector3(-0.5, 0.5, 0.5),
  ];

  static const List<List<int>> edges = [
    [0, 1], [1, 2], [2, 3], [3, 0], // Front face
    [4, 5], [5, 6], [6, 7], [7, 4], // Back face
    [0, 4], [1, 5], [2, 6], [3, 7], // Connecting front and back
  ];

  final double angle;
  final Color color;

  _RotatedWireCubePainter({required this.angle, required this.color});

  Offset scaleAndCenter(Vector3 point, double size, Offset center) {
    final scale = size / 2;
    return Offset(center.dx + point.x * scale, center.dy - point.y * scale);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final rotatedVertices = vertices
        .map((vertex) => Matrix4.rotationX(angle).transformed3(vertex))
        .map((vertex) => Matrix4.rotationY(angle).transformed3(vertex))
        .map((vertex) => Matrix4.rotationZ(angle).transformed3(vertex))
        .toList();

    final center = Offset(size.width / 2, size.height / 2);

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (var edge in edges) {
      final p1 = scaleAndCenter(rotatedVertices[edge[0]], size.width, center);
      final p2 = scaleAndCenter(rotatedVertices[edge[1]], size.width, center);
      canvas.drawLine(p1, p2, paint);
    }
  }

  @override
  bool shouldRepaint(_RotatedWireCubePainter oldDelegate) => true;
}
