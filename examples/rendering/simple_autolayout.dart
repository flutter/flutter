// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:cassowary/cassowary.dart' as al;
import 'package:flutter/rendering.dart';

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

  RenderAutoLayout root = new RenderAutoLayout(children: <RenderBox>[c1, c2, c3, c4]);

  AutoLayoutParentData p1 = c1.parentData;
  AutoLayoutParentData p2 = c2.parentData;
  AutoLayoutParentData p3 = c3.parentData;
  AutoLayoutParentData p4 = c4.parentData;

  root.addConstraints(<al.Constraint>[
    // Sum of widths of each box must be equal to that of the container
    (p1.width + p2.width + p3.width == root.width) as al.Constraint,

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
    (p3.height == root.height) as al.Constraint,

    // The fourth box should be half as wide as the second and must be attached
    // to the right edge of the same (by its center)
    (p4.width == p2.width / al.cm(2.0)) as al.Constraint,
    (p4.height == al.cm(50.0)) as al.Constraint,
    (p4.horizontalCenter == p2.rightEdge) as al.Constraint,
    (p4.verticalCenter == p2.height / al.cm(2.0)) as al.Constraint,
  ]);

  new RenderingFlutterBinding(root: root);
}
