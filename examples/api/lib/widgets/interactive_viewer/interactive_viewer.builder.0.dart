// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Flutter code sample for InteractiveViewer.builder

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
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

  // Returns true iff the given cell is currently visible. Caches viewport
  // calculations.
  Quad? _cachedViewport;
  late int _firstVisibleRow;
  late int _firstVisibleColumn;
  late int _lastVisibleRow;
  late int _lastVisibleColumn;
  bool _isCellVisible(int row, int column, Quad viewport) {
    if (viewport != _cachedViewport) {
      final Rect aabb = _axisAlignedBoundingBox(viewport);
      _cachedViewport = viewport;
      _firstVisibleRow = (aabb.top / _cellHeight).floor();
      _firstVisibleColumn = (aabb.left / _cellWidth).floor();
      _lastVisibleRow = (aabb.bottom / _cellHeight).floor();
      _lastVisibleColumn = (aabb.right / _cellWidth).floor();
    }
    return row >= _firstVisibleRow &&
        row <= _lastVisibleRow &&
        column >= _firstVisibleColumn &&
        column <= _lastVisibleColumn;
  }

  // Returns the axis aligned bounding box for the given Quad, which might not
  // be axis aligned.
  Rect _axisAlignedBoundingBox(Quad quad) {
    double? xMin;
    double? xMax;
    double? yMin;
    double? yMax;
    for (final Vector3 point in <Vector3>[
      quad.point0,
      quad.point1,
      quad.point2,
      quad.point3
    ]) {
      if (xMin == null || point.x < xMin) {
        xMin = point.x;
      }
      if (xMax == null || point.x > xMax) {
        xMax = point.x;
      }
      if (yMin == null || point.y < yMin) {
        yMin = point.y;
      }
      if (yMax == null || point.y > yMax) {
        yMax = point.y;
      }
    }
    return Rect.fromLTRB(xMin!, yMin!, xMax!, yMax!);
  }

  void _onChangeTransformation() {
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _transformationController.addListener(_onChangeTransformation);
  }

  @override
  void dispose() {
    _transformationController.removeListener(_onChangeTransformation);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          return InteractiveViewer.builder(
            alignPanAxis: true,
            scaleEnabled: false,
            transformationController: _transformationController,
            builder: (BuildContext context, Quad viewport) {
              // A simple extension of Table that builds cells.
              return _TableBuilder(
                  rowCount: 60,
                  columnCount: 6,
                  cellWidth: _cellWidth,
                  builder: (BuildContext context, int row, int column) {
                    if (!_isCellVisible(row, column, viewport)) {
                      debugPrint('removing cell ($row, $column)');
                      return Container(height: _cellHeight);
                    }
                    debugPrint('building cell ($row, $column)');
                    return Container(
                      height: _cellHeight,
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
    required this.rowCount,
    required this.columnCount,
    required this.cellWidth,
    required this.builder,
  })  : assert(rowCount > 0),
        assert(columnCount > 0);

  final int rowCount;
  final int columnCount;
  final double cellWidth;
  final _CellBuilder builder;

  @override
  Widget build(BuildContext context) {
    return Table(
      // ignore: prefer_const_literals_to_create_immutables
      columnWidths: <int, TableColumnWidth>{
        for (int column = 0; column < columnCount; column++)
          column: FixedColumnWidth(cellWidth),
      },
      // ignore: prefer_const_literals_to_create_immutables
      children: <TableRow>[
        for (int row = 0; row < rowCount; row++)
          // ignore: prefer_const_constructors
          TableRow(
            // ignore: prefer_const_literals_to_create_immutables
            children: <Widget>[
              for (int column = 0; column < columnCount; column++)
                builder(context, row, column),
            ],
          ),
      ],
    );
  }
}
