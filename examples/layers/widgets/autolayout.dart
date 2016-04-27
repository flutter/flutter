// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This example shows how to use the Cassowary autolayout system with widgets.

import 'package:flutter/cassowary.dart' as al;
import 'package:flutter/widgets.dart';

class _MyAutoLayoutDelegate extends AutoLayoutDelegate {
  AutoLayoutRect p1 = new AutoLayoutRect();
  AutoLayoutRect p2 = new AutoLayoutRect();
  AutoLayoutRect p3 = new AutoLayoutRect();
  AutoLayoutRect p4 = new AutoLayoutRect();

  @override
  List<al.Constraint> getConstraints(AutoLayoutRect parent) {
    return <al.Constraint>[
      // Sum of widths of each box must be equal to that of the container
      parent.width.equals(p1.width + p2.width + p3.width),

      // The boxes must be stacked left to right
      p1.right <= p2.left,
      p2.right <= p3.left,

      // The widths of the first and the third boxes should be equal
      p1.width.equals(p3.width),

      // The width of the first box should be twice as much as that of the second
      p1.width.equals(p2.width * al.cm(2.0)),

      // The height of the three boxes should be equal to that of the container
      p1.height.equals(p2.height),
      p2.height.equals(p3.height),
      p3.height.equals(parent.height),

      // The fourth box should be half as wide as the second and must be attached
      // to the right edge of the same (by its center)
      p4.width.equals(p2.width / al.cm(2.0)),
      p4.height.equals(al.cm(50.0)),
      p4.horizontalCenter.equals(p2.right),
      p4.verticalCenter.equals(p2.height / al.cm(2.0)),
    ];
  }

  @override
  bool shouldUpdateConstraints(_MyAutoLayoutDelegate oldDelegate) => true;
}

class ColoredBoxes extends StatefulWidget {
  @override
  _ColoredBoxesState createState() => new _ColoredBoxesState();
}

class _ColoredBoxesState extends State<ColoredBoxes> {
  final _MyAutoLayoutDelegate delegate = new _MyAutoLayoutDelegate();

  @override
  Widget build(BuildContext context) {
    return new AutoLayout(
      delegate: delegate,
      children: <Widget>[
        new AutoLayoutChild(
          rect: delegate.p1,
          child: new DecoratedBox(
            decoration: new BoxDecoration(backgroundColor: const Color(0xFFFF0000))
          )
        ),
        new AutoLayoutChild(
          rect: delegate.p2,
          child: new DecoratedBox(
            decoration: new BoxDecoration(backgroundColor: const Color(0xFF00FF00))
          )
        ),
        new AutoLayoutChild(
          rect: delegate.p3,
          child: new DecoratedBox(
            decoration: new BoxDecoration(backgroundColor: const Color(0xFF0000FF))
          )
        ),
        new AutoLayoutChild(
          rect: delegate.p4,
          child: new DecoratedBox(
            decoration: new BoxDecoration(backgroundColor: const Color(0xFFFFFFFF))
          )
        ),
      ]
    );
  }
}

void main() {
  runApp(new ColoredBoxes());
}
