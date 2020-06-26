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

class _MultiWidgetConstructTableState extends State<MultiWidgetConstructTable>
    with SingleTickerProviderStateMixin {
  static const List<MaterialColor> colorList = <MaterialColor>[
    Colors.pink, Colors.red, Colors.deepOrange, Colors.orange, Colors.amber,
    Colors.yellow, Colors.lime, Colors.lightGreen, Colors.green, Colors.teal,
    Colors.cyan, Colors.lightBlue, Colors.blue, Colors.indigo, Colors.purple,
  ];
  int counter = 0;
  Color baseColor = colorList[0][900];

  AnimationController controller;
  CurvedAnimation curve;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 10000));
    curve = CurvedAnimation(parent: controller, curve: Curves.linear)
      ..addListener(() {
        final double colorPosition = curve.value;
        final int c1Position = (colorPosition * (colorList.length + 1)).floor();
        final Color c1 = colorList[c1Position % colorList.length][900];
        final Color c2 = colorList[(c1Position + 1) % colorList.length][900];
        setState(() {
          baseColor = Color.lerp(
              c1, c2, colorPosition * (colorList.length + 1) - c1Position);
        });
      })
      ..addStatusListener((AnimationStatus state) {
        if (state == AnimationStatus.completed) {
          controller.reverse();
        } else if (state == AnimationStatus.dismissed) {
          controller.reset();
          controller.forward();
        }
      });

    controller.forward();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                return counter % 2 == 0
                    ? Container(
                        // This key forces rebuilding the element
                        key: ValueKey<int>(widgetCounter + label),
                        color: Color.lerp(
                            Colors.white, baseColor, label / totalLength),
                        child: Text('${widgetCounter + label}'),
                        constraints: BoxConstraints.expand(height: height),
                      )
                    : MyContainer(
                        // This key forces rebuilding the element
                        key: ValueKey<int>(widgetCounter + label),
                        color: Color.lerp(
                            Colors.white, baseColor, label / totalLength),
                        child: Text('${widgetCounter + label}'),
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

// This class is intended to break the original Widget tree
class MyContainer extends StatelessWidget {
  const MyContainer({this.color, this.child, this.constraints, Key key})
      : super(key: key);
  final Color color;
  final Widget child;
  final BoxConstraints constraints;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color,
      child: child,
      constraints: constraints,
    );
  }
}
