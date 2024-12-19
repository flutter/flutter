// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' show Quad, Vector3;

/// Flutter code sample for [InteractiveViewer.raw].

void main() => runApp(const IVRawExampleApp());

class IVRawExampleApp extends StatelessWidget {
  const IVRawExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('IV Raw Example'),
        ),
        body: const _IVRawExample(),
      ),
    );
  }
}

class _IVRawExample extends StatefulWidget {
  const _IVRawExample();

  @override
  State<_IVRawExample> createState() => _IVRawExampleState();
}

class _IVRawExampleState extends State<_IVRawExample> {
  final TransformationController controller = TransformationController();

  final List<Node> nodes = <Node>[
      Node(Colors.red, offset: Offset.zero),
      Node(Colors.green, offset: const Offset(30, 30)),
      Node(Colors.blue, offset: const Offset(150, 150)),
  ];

  // Returns the axis aligned bounding box for the given Quad, which might not
  // be axis aligned.
  Rect axisAlignedBoundingBox(Quad quad) {
    double xMin = quad.point0.x;
    double xMax = quad.point0.x;
    double yMin = quad.point0.y;
    double yMax = quad.point0.y;
    for (final Vector3 point in <Vector3>[
      quad.point1,
      quad.point2,
      quad.point3,
    ]) {
      if (point.x < xMin) {
        xMin = point.x;
      } else if (point.x > xMax) {
        xMax = point.x;
      }

      if (point.y < yMin) {
        yMin = point.y;
      } else if (point.y > yMax) {
        yMax = point.y;
      }
    }

    return Rect.fromLTRB(xMin, yMin, xMax, yMax);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: InteractiveViewer.raw(
        transformationController: controller,
        boundaryMargin: const EdgeInsets.all(double.infinity),
        builder: (BuildContext context, Quad viewport) {
          final ThemeData theme = Theme.of(context);
          return Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: GridBackgroundPainter(
                    colors: theme.colorScheme,
                    fonts: theme.textTheme,
                    transform: controller.value,
                    viewport: axisAlignedBoundingBox(viewport),
                  ),
                ),
              ),
              for (final Node node in nodes)
                AnimatedBuilder(
                  animation: node,
                  builder: (BuildContext context, Widget? child) {
                    Rect rect = node.rect;
                    rect = MatrixUtils.transformRect(controller.value, rect);
                    return Positioned.fromRect(
                      rect: rect,
                      child: GestureDetector(
                        onPanUpdate: (details) {
                          node.offset += details.delta /
                              controller.value.getMaxScaleOnAxis();
                        },
                        child: Container(
                          color: node.color,
                        ),
                      ),
                    );
                  },
                ),
            ],
          );
        },
      ),
    );
  }
}

class Node extends ChangeNotifier {
  final Color color;
  Node(this.color, {Offset offset = Offset.zero}): _offset = offset;
  Size size = const Size(100, 100);

  Offset _offset;
  Offset get offset => _offset;
  set offset(Offset value) {
    _offset = value;
    notifyListeners();
  }

  Rect get rect => offset & size;
}

class GridBackgroundPainter extends CustomPainter {
  final Matrix4 transform;
  final ColorScheme colors;
  final TextTheme fonts;
  final Rect viewport;
  final double dotDimension;
  final Size cellSize;

  GridBackgroundPainter({
    required this.colors,
    required this.fonts,
    required this.viewport,
    required this.transform,
    this.dotDimension = 5,
    this.cellSize = const Size.square(50),
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Size(width: cW, height: cH) = cellSize;
    final int firstRow = (viewport.top / cH).floor();
    final int lastRow = (viewport.bottom / cH).ceil();
    final int firstCol = (viewport.left / cW).floor();
    final int lastCol = (viewport.right / cW).ceil();
    final bgPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = colors.surface;
    final fgPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = colors.outlineVariant.withOpacity(0.6);
    final cellRadius = Radius.circular(dotDimension);

    canvas.drawRect(viewport, bgPaint);

    for (int row = firstRow; row < lastRow; row++) {
      for (int col = firstCol; col < lastCol; col++) {
        final offset = Offset(col * cW, row * cH);
        Rect rect = offset & Size.square(dotDimension);
        rect = MatrixUtils.transformRect(transform, rect);
        RRect rrect = RRect.fromRectAndRadius(rect, cellRadius);
        canvas.drawRRect(rrect, fgPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
