// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Flutter code sample for CustomMultiChildLayout. This example creates a parent widget that takes in children, the number of columns wanted, and the row height wanted, then creates a layout that lists the children in a "snake" pattern where the child in the new row is placed directly under the previous child and the layout direction is toggled between ltr or rtl.

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
        body: const ExampleWidget(),
      ),
    );
  }
}

class _SnakeLayoutDelegate extends MultiChildLayoutDelegate {
  _SnakeLayoutDelegate({
    required this.ids,
    required this.numCols,
    required this.rowHeight,
  });

  // In our case we only care about IDs since we just need something to refer to in the LayoutId widget in the build of the ExampleWidget.
  final List<String> ids;
  final int numCols;
  // Not sure how to access the greatest height of children to make a max height so here I hardcode the rowHeight value
  final double rowHeight;

  @override
  void performLayout(Size size) {
    // Distribute children between numCols
    final double columnWidth = size.width / numCols;
    Offset childPosition = Offset.zero;
    // The layout direction changes depending on which row the children are being drawn on
    int direction = 1;
    // Position each child
    ids.asMap().forEach((int idx, String id) {
      final Size currentSize = layoutChild(
          id, BoxConstraints(maxHeight: rowHeight, maxWidth: columnWidth));
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
      delegate: _SnakeLayoutDelegate(
        ids: _colors.keys.toList(),
        numCols: 3,
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
