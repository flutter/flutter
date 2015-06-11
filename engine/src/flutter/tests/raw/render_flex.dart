// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:sky' as sky;

import 'package:sky/framework/app.dart';
import 'package:sky/framework/rendering/block.dart';
import 'package:sky/framework/rendering/box.dart';
import 'package:sky/framework/rendering/flex.dart';

import '../resources/display_list.dart';
import '../resources/third_party/unittest/unittest.dart';
import '../resources/unit.dart';

class RenderSolidColor extends RenderDecoratedBox {
  final sky.Size desiredSize;
  final sky.Color backgroundColor;

  RenderSolidColor(sky.Color backgroundColor, { this.desiredSize: sky.Size.infinite })
      : backgroundColor = backgroundColor,
        super(decoration: new BoxDecoration(backgroundColor: backgroundColor)) {
  }

  double getMinIntrinsicWidth(BoxConstraints constraints) {
    return constraints.constrainWidth(desiredSize.width);
  }

  double getMaxIntrinsicWidth(BoxConstraints constraints) {
    return constraints.constrainWidth(desiredSize.width);
  }

  double getMinIntrinsicHeight(BoxConstraints constraints) {
    return constraints.constrainHeight(desiredSize.height);
  }

  double getMaxIntrinsicHeight(BoxConstraints constraints) {
    return constraints.constrainHeight(desiredSize.height);
  }

  void performLayout() {
    size = constraints.constrain(desiredSize);
  }

  void handleEvent(sky.Event event, BoxHitTestEntry entry) {
    if (event.type == 'pointerdown')
      decoration = new BoxDecoration(backgroundColor: const sky.Color(0xFFFF0000));
    else if (event.type == 'pointerup')
      decoration = new BoxDecoration(backgroundColor: backgroundColor);
  }
}

void main() {
  initUnit();

  test("should flex", () {
    RenderFlex flexRoot = new RenderFlex(direction: FlexDirection.vertical);

    RenderDecoratedBox root = new RenderDecoratedBox(
      decoration: new BoxDecoration(backgroundColor: const sky.Color(0xFF000000)),
      child: flexRoot
    );

    void addFlexChildSolidColor(RenderFlex parent, sky.Color backgroundColor, { int flex: 0 }) {
      RenderSolidColor child = new RenderSolidColor(backgroundColor);
      parent.add(child);
      child.parentData.flex = flex;
    }

    // Yellow bar at top
    addFlexChildSolidColor(flexRoot, const sky.Color(0xFFFFFF00), flex: 1);

    // Turquoise box
    flexRoot.add(new RenderSolidColor(const sky.Color(0x7700FFFF), desiredSize: new sky.Size(100.0, 100.0)));

    // Green and cyan render block with padding
    var renderBlock = new RenderBlock();

    renderBlock.add(new RenderSolidColor(const sky.Color(0xFF00FF00), desiredSize: new sky.Size(100.0, 50.0)));
    renderBlock.add(new RenderSolidColor(const sky.Color(0x7700FFFF), desiredSize: new sky.Size(50.0, 100.0)));

    var renderDecoratedBlock = new RenderDecoratedBox(
      decoration: new BoxDecoration(backgroundColor: const sky.Color(0xFFFFFFFF)),
      child: renderBlock
    );

    flexRoot.add(new RenderPadding(padding: const EdgeDims.all(10.0), child: renderDecoratedBlock));

    var row = new RenderFlex(direction: FlexDirection.horizontal);

    // Purple and blue cells
    addFlexChildSolidColor(row, const sky.Color(0x77FF00FF), flex: 1);
    addFlexChildSolidColor(row, const sky.Color(0xFF0000FF), flex: 2);

    var decoratedRow = new RenderDecoratedBox(
      decoration: new BoxDecoration(backgroundColor: const sky.Color(0xFF333333)),
      child: row
    );

    flexRoot.add(decoratedRow);
    decoratedRow.parentData.flex = 3;

    new TestRenderView(root);

    expect(root.size.width, equals(sky.view.width));
    expect(root.size.height, equals(sky.view.height));
    expect(renderBlock.size.width, equals(sky.view.width - 20.0));

  });
}
