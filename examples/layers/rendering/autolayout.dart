// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This example shows how to use the Cassowary autolayout system directly in the
// underlying render tree.

import 'package:flutter/cassowary.dart' as al;
import 'package:flutter/rendering.dart';

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
  bool shouldUpdateConstraints(AutoLayoutDelegate oldDelegate) => true;
}

void main() {
  RenderDecoratedBox c1 = new RenderDecoratedBox(
    decoration: new BoxDecoration(backgroundColor: const Color(0xFFFF0000))
  );

  RenderDecoratedBox c2 = new RenderDecoratedBox(
    decoration: new BoxDecoration(backgroundColor: const Color(0xFF00FF00))
  );

  RenderDecoratedBox c3 = new RenderDecoratedBox(
    decoration: new BoxDecoration(backgroundColor: const Color(0xFF0000FF))
  );

  RenderDecoratedBox c4 = new RenderDecoratedBox(
    decoration: new BoxDecoration(backgroundColor: const Color(0xFFFFFFFF))
  );

  _MyAutoLayoutDelegate delegate = new _MyAutoLayoutDelegate();

  RenderAutoLayout root = new RenderAutoLayout(
    delegate: delegate,
    children: <RenderBox>[c1, c2, c3, c4]
  );

  AutoLayoutParentData parentData1 = c1.parentData;
  AutoLayoutParentData parentData2 = c2.parentData;
  AutoLayoutParentData parentData3 = c3.parentData;
  AutoLayoutParentData parentData4 = c4.parentData;

  parentData1.rect = delegate.p1;
  parentData2.rect = delegate.p2;
  parentData3.rect = delegate.p3;
  parentData4.rect = delegate.p4;

  new RenderingFlutterBinding(root: root);
}
