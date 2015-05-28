// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../resources/third_party/unittest/unittest.dart';
import '../resources/unit.dart';
import 'dart:sky' as sky;
import 'package:sky/framework/app.dart';
import 'package:sky/framework/layout2.dart';

class RenderSolidColor extends RenderDecoratedBox {
  final sky.Size desiredSize;
  final int backgroundColor;

  RenderSolidColor(int backgroundColor, { this.desiredSize: const sky.Size.infinite() })
      : backgroundColor = backgroundColor,
        super(new BoxDecoration(backgroundColor: backgroundColor)) {
  }

  BoxDimensions getIntrinsicDimensions(BoxConstraints constraints) {
    return new BoxDimensions.withConstraints(constraints,
                                             width: desiredSize.width,
                                             height: desiredSize.height);
  }

  void performLayout() {
    size = constraints.constrain(desiredSize);
  }

  void handlePointer(sky.PointerEvent event) {
    if (event.type == 'pointerdown')
      decoration = new BoxDecoration(backgroundColor: 0xFFFF0000);
    else if (event.type == 'pointerup')
      decoration = new BoxDecoration(backgroundColor: backgroundColor);
  }
}

AppView app;

void main() {
  initUnit();

  test("should flex", () {
    var root = new RenderFlex(
        direction: FlexDirection.Vertical,
        decoration: new BoxDecoration(backgroundColor: 0xFF000000));

    void addFlexChild(RenderFlex parent, int backgroundColor, { int flex: 0 }) {
      RenderNode child = new RenderSolidColor(backgroundColor);
      parent.add(child);
      child.parentData.flex = flex;
    }

    // Yellow bar at top
    addFlexChild(root, 0xFFFFFF00, flex: 1);

    // Turquoise box
    root.add(new RenderSolidColor(0x7700FFFF, desiredSize: new sky.Size(100.0, 100.0)));

    // Green and cyan render block with padding
    var renderBlock = new RenderBlock(decoration: new BoxDecoration(backgroundColor: 0xFFFFFFFF));

    renderBlock.add(new RenderSolidColor(0xFF00FF00, desiredSize: new sky.Size(100.0, 50.0)));
    renderBlock.add(new RenderSolidColor(0x7700FFFF, desiredSize: new sky.Size(50.0, 100.0)));

    root.add(new RenderPadding(const EdgeDims(10.0, 10.0, 10.0, 10.0), renderBlock));

    var row = new RenderFlex(
      direction: FlexDirection.Horizontal,
      decoration: new BoxDecoration(backgroundColor: 0xFF333333));

    // Purple and blue cells
    addFlexChild(row, 0x77FF00FF, flex: 1);
    addFlexChild(row, 0xFF0000FF, flex: 2);

    root.add(row);
    row.parentData.flex = 3;

    app = new AppView(root);

    expect(root.size.width, equals(sky.view.width));
    expect(root.size.height, equals(sky.view.height));
    expect(renderBlock.size.width, equals(sky.view.width - 20.0));
  });
}
