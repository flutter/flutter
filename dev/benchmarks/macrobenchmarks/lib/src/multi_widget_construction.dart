// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

class MultiWidgetConstructTable extends StatefulWidget {
  const MultiWidgetConstructTable(this.column, this.row, {Key key})
      : super(key: key);

  final int column;
  final int row;

  @override
  _MultiWidgetConstructTableState createState() =>
      _MultiWidgetConstructTableState();
}

class _MultiWidgetConstructTableState extends State<MultiWidgetConstructTable> {
  int counter = 0;
  static const List<MaterialColor> colorList = <MaterialColor>[
    Colors.pink, Colors.red, Colors.deepOrange, Colors.orange, Colors.amber,
    Colors.yellow, Colors.lime, Colors.lightGreen, Colors.green, Colors.teal,
    Colors.cyan, Colors.lightBlue, Colors.blue, Colors.indigo, Colors.purple,
  ];

  @override
  Widget build(BuildContext context) {
    final Color baseColor = colorList[counter % colorList.length][900];
    final int totalLength = widget.row * widget.column;
    final int widgetCounter = counter * totalLength;
    final double height = MediaQuery.of(context).size.height / widget.column;
    counter++;
    return Scaffold(
      body: Table(
        children: List<TableRow>.generate(
          widget.row,
          (int row) => TableRow(
            children: List<Widget>.generate(
              widget.column,
              (int column) {
                final int label = row * widget.column + column;
                return Container(
                  key: ValueKey<int>(widgetCounter + label),
                  color: Color.lerp(Colors.white, baseColor, label / totalLength),
                  child: Text('${widgetCounter + label}: ${9 * label ~/ totalLength * 100}'),
                  constraints: BoxConstraints.expand(height: height),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
