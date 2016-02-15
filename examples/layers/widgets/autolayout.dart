// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This example shows how to use the Cassowary autolayout system with widgets.

import 'package:cassowary/cassowary.dart' as al;
import 'package:flutter/widgets.dart';

class _MyAutoLayoutDelegate extends AutoLayoutDelegate {
  AutoLayoutParams p1 = new AutoLayoutParams();
  AutoLayoutParams p2 = new AutoLayoutParams();
  AutoLayoutParams p3 = new AutoLayoutParams();
  AutoLayoutParams p4 = new AutoLayoutParams();

  List<al.Constraint> getConstraints(AutoLayoutParams parentParams) {
    return <al.Constraint>[
      // Sum of widths of each box must be equal to that of the container
      (p1.width + p2.width + p3.width == parentParams.width) as al.Constraint,

      // The boxes must be stacked left to right
      p1.rightEdge <= p2.leftEdge,
      p2.rightEdge <= p3.leftEdge,

      // The widths of the first and the third boxes should be equal
      (p1.width == p3.width) as al.Constraint,

      // The width of the second box should be twice as much as that of the first
      // and third
      (p2.width * al.cm(2.0) == p1.width) as al.Constraint,

      // The height of the three boxes should be equal to that of the container
      (p1.height == p2.height) as al.Constraint,
      (p2.height == p3.height) as al.Constraint,
      (p3.height == parentParams.height) as al.Constraint,

      // The fourth box should be half as wide as the second and must be attached
      // to the right edge of the same (by its center)
      (p4.width == p2.width / al.cm(2.0)) as al.Constraint,
      (p4.height == al.cm(50.0)) as al.Constraint,
      (p4.horizontalCenter == p2.rightEdge) as al.Constraint,
      (p4.verticalCenter == p2.height / al.cm(2.0)) as al.Constraint,
    ];
  }

  bool shouldUpdateConstraints(AutoLayoutDelegate oldDelegate) => true;
}

class ColoredBox extends StatelessComponent {
  ColoredBox({ Key key, this.params, this.color }) : super(key: key);

  final AutoLayoutParams params;
  final Color color;

  Widget build(BuildContext context) {
    return new AutoLayoutChild(
      params: params,
      child: new DecoratedBox(
        decoration: new BoxDecoration(backgroundColor: color)
      )
    );
  }
}

class ColoredBoxes extends StatefulComponent {
  _ColoredBoxesState createState() => new _ColoredBoxesState();
}

class _ColoredBoxesState extends State<ColoredBoxes> {
  final _MyAutoLayoutDelegate delegate = new _MyAutoLayoutDelegate();

  Widget build(BuildContext context) {
    return new AutoLayout(
      delegate: delegate,
      children: <Widget>[
        new ColoredBox(params: delegate.p1, color: const Color(0xFFFF0000)),
        new ColoredBox(params: delegate.p2, color: const Color(0xFF00FF00)),
        new ColoredBox(params: delegate.p3, color: const Color(0xFF0000FF)),
        new ColoredBox(params: delegate.p4, color: const Color(0xFFFFFFFF)),
      ]
    );
  }
}

void main() {
  runApp(new ColoredBoxes());
}
