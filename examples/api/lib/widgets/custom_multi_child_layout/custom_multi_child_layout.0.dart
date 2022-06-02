// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// This example shows a [CustomMultiChildLayout] being used to layout widgets
/// in a "snake" pattern where the child in the new row is placed directly under
/// the previous child and the layout direction is toggled between ltr or rtl.
///
/// It allows entry of the number of columns and column width and sets the
/// constraints of the Layout widget
/// 
/// Each child must be wrapped in a [LayoutId] widget to identify the widget for
/// the delegate.
///
/// {@tool dartpad}
/// This example shows a [CustomMultiChildLayout] widget being used to lay out
/// colored blocks in a "snake" pattern.
///
/// It allows entry of the number of columns and column width and sets the
/// constraints of the Layout widget
///
/// ** See code in examples/api/lib/widgets/basic/custom_multi_child_layout.1.dart **
/// {@end-tool}

import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static const String _title = 'Flutter Code Sample';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: _title,
      home: Scaffold(
        appBar: AppBar(title: const Text(_title)),
        body: const Center(
          key: Key('layoutParent'),
          child: ExampleWidget(),
        ),
      ),
    );
  }
}

class _SnakeLayoutDelegate extends MultiChildLayoutDelegate {
  _SnakeLayoutDelegate({
    required this.ids,
    required this.numCols,
    required this.colWidth,
    required this.rowHeight,
  });

  // In our case we only care about IDs since we just need something to refer to in the LayoutId widget in the build of the ExampleWidget.
  final List<String> ids;
  final int numCols;
  final double rowHeight;
  final double colWidth;

  @override
  void performLayout(Size size) {
    // Distribute children between numCols
    Offset childPosition = Offset.zero;
    // The layout direction changes depending on which row the children are being drawn on
    int direction = 1;
    // Position each child
    ids.asMap().forEach((int idx, String id) {
      final Size currentSize = layoutChild(
          id, BoxConstraints(maxHeight: rowHeight, maxWidth: colWidth));
      positionChild(id, childPosition);
      // Logic for checking if a new row has been reached and the appropriate behavior
      if ((idx + 1) % numCols == 0) {
        childPosition += Offset(0, currentSize.height);
        direction *= -1;
      } else {
        childPosition += Offset(direction * currentSize.width, 0);
      }
    });
  }

  @override
  Size getSize(BoxConstraints constraints) {
    return Size(colWidth * numCols, super.getSize(constraints).height);
  }

  @override
  bool shouldRelayout(covariant _SnakeLayoutDelegate oldDelegate) {
    return oldDelegate.numCols != numCols || oldDelegate.rowHeight != rowHeight;
  }
}

class ExampleWidget extends StatelessWidget {
  const ExampleWidget({super.key});
  static const Map<String, Color> _colors = <String, Color>{
    'Red': Colors.red,
    'Green': Colors.green,
    'Blue': Colors.blue,
    'Cyan': Colors.cyan,
    'Purple': Colors.purple,
    'Pink': Colors.pink,
    'Yellow': Colors.yellow,
  };
  @override
  Widget build(BuildContext context) {
    return CustomMultiChildLayout(
      key: const Key('multiChildLayout'),
      delegate: _SnakeLayoutDelegate(
        ids: _colors.keys.toList(),
        numCols: 3,
        colWidth: 100.0,
        rowHeight: 100.0,
      ),
      children: <Widget>[
        // Create all of the colored boxes in the colors map.
        for (MapEntry<String, Color> entry in _colors.entries)
          LayoutId(
            id: entry.key,
            child: Container(
              key: Key(entry.key),
              color: entry.value,
              width: 200.0,
              height: 200.0,
              alignment: Alignment.center,
              child: Text(entry.key),
            ),
          ),
      ],
    );
  }
}
