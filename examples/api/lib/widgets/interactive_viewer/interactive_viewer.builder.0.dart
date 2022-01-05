// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Flutter code sample for InteractiveViewer.builder

import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' show Quad, Vector3;

void main() => runApp(const IVBuilderExampleApp());

class IVBuilderExampleApp extends StatelessWidget {
  const IVBuilderExampleApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('IV Builder Example'),
        ),
        body: _IVBuilderExample(),
      ),
    );
  }
}

class _IVBuilderExample extends StatefulWidget {
  @override
  State<_IVBuilderExample> createState() => _IVBuilderExampleState();
}

class _IVBuilderExampleState extends State<_IVBuilderExample> {
  final TransformationController _transformationController =
      TransformationController();

  static const double _cellWidth = 200.0;
  static const double _cellHeight = 26.0;

  // Returns the axis aligned bounding box for the given Quad, which might not be axis aligned.
  Rect axisAlignedBoundingBox(Quad quad) {
    double xMin = quad.point0.x;
    double xMax = quad.point0.x;
    double yMin = quad.point0.y;
    double yMax = quad.point0.y;
    for (final Vector3 point in <Vector3>[
      quad.point1,
      quad.point2,
      quad.point3
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
    return Center(
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          return InteractiveViewer.builder(
            boundaryMargin: const EdgeInsets.all(double.infinity),
            transformationController: _transformationController,
            builder: (BuildContext context, Quad viewport) {
              // A simple extension of Table that builds cells.
              return _TableBuilder(
                  cellWidth: _cellWidth,
                  cellHeight: _cellHeight,
                  viewport: axisAlignedBoundingBox(viewport),
                  builder: (BuildContext context, int row, int column) {
                    return Container(
                      height: _cellHeight,
                      width: _cellWidth,
                      color: row % 2 + column % 2 == 1
                          ? Colors.white
                          : Colors.grey.withOpacity(0.1),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text('$row x $column'),
                      ),
                    );
                  });
            },
          );
        },
      ),
    );
  }
}

typedef _CellBuilder = Widget Function(
    BuildContext context, int row, int column);

class _TableBuilder extends StatelessWidget {
  const _TableBuilder({
    required this.cellWidth,
    required this.cellHeight,
    required this.viewport,
    required this.builder,
  });

  final double cellWidth;
  final double cellHeight;
  final Rect viewport;
  final _CellBuilder builder;

  @override
  Widget build(BuildContext context) {
    final int firstRow = (viewport.top / cellHeight).floor();
    final int lastRow = (viewport.bottom / cellHeight).ceil();
    final int firstCol = (viewport.left / cellWidth).floor();
    final int lastCol = (viewport.right / cellWidth).ceil();

    final int totalCells = (lastRow - firstRow) * (lastCol - firstCol);
    debugPrint('Total cells: $totalCells');

    return SizedBox(
        // Stack needs constraints, even though we then Clip.none outside of them.
        width: 1,
        height: 1,
        child: Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            for (int row = firstRow; row < lastRow; row++)
              for (int col = firstCol; col < lastCol; col++)
                Positioned(
                    left: col * cellWidth,
                    top: row * cellHeight,
                    child: builder(context, row, col)),
          ],
        ));
  }
}
