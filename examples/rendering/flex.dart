// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'lib/solid_color_box.dart';

RenderBox buildFlexExample() {
  RenderFlex flexRoot = new RenderFlex(direction: FlexDirection.vertical);

  RenderDecoratedBox root = new RenderDecoratedBox(
    decoration: new BoxDecoration(backgroundColor: const ui.Color(0xFF000000)),
    child: flexRoot
  );

  void addFlexChildSolidColor(RenderFlex parent, ui.Color backgroundColor, { int flex: 0 }) {
    RenderSolidColorBox child = new RenderSolidColorBox(backgroundColor);
    parent.add(child);
    final FlexParentData childParentData = child.parentData;
    childParentData.flex = flex;
  }

  // Yellow bar at top
  addFlexChildSolidColor(flexRoot, const ui.Color(0xFFFFFF00), flex: 1);

  // Turquoise box
  flexRoot.add(new RenderSolidColorBox(const ui.Color(0x7700FFFF), desiredSize: new ui.Size(100.0, 100.0)));

  var renderDecoratedBlock = new RenderDecoratedBox(
    decoration: new BoxDecoration(backgroundColor: const ui.Color(0xFFFFFFFF))
  );

  flexRoot.add(new RenderPadding(padding: const EdgeDims.all(10.0), child: renderDecoratedBlock));

  var row = new RenderFlex(direction: FlexDirection.horizontal);

  // Purple and blue cells
  addFlexChildSolidColor(row, const ui.Color(0x77FF00FF), flex: 1);
  addFlexChildSolidColor(row, const ui.Color(0xFF0000FF), flex: 2);

  var decoratedRow = new RenderDecoratedBox(
    decoration: new BoxDecoration(backgroundColor: const ui.Color(0xFF333333)),
    child: row
  );

  flexRoot.add(decoratedRow);
  final FlexParentData decoratedRowParentData = decoratedRow.parentData;
  decoratedRowParentData.flex = 3;

  return root;
}

void main() {
  new RenderingFlutterBinding(root: buildFlexExample());
}
