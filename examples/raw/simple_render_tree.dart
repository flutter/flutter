// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math';
import 'dart:sky';
import 'package:sky/framework/layout2.dart';

class RenderSolidColor extends RenderDecoratedBox {
  final double desiredHeight;
  final double desiredWidth;
  final int backgroundColor;

  RenderSolidColor(int backgroundColor, { double desiredHeight: double.INFINITY,
                                          double desiredWidth: double.INFINITY })
      : desiredHeight = desiredHeight,
        desiredWidth = desiredWidth,
        backgroundColor = backgroundColor,
        super(new BoxDecoration(backgroundColor: backgroundColor));

  BoxDimensions getIntrinsicDimensions(BoxConstraints constraints) {
    return new BoxDimensions.withConstraints(constraints,
                                             height: desiredHeight,
                                             width: desiredWidth);
  }

  void layout(BoxConstraints constraints, { RenderNode relayoutSubtreeRoot }) {
    width = constraints.constrainWidth(desiredWidth);
    height = constraints.constrainHeight(desiredHeight);
    layoutDone();
  }

  bool handlePointer(PointerEvent event, { double x: 0.0, double y: 0.0 }) {
    if (event.type == 'pointerdown') {
      setBoxDecoration(new BoxDecoration(backgroundColor: 0xFFFF0000));
      return true;
    }

    if (event.type == 'pointerup') {
      setBoxDecoration(new BoxDecoration(backgroundColor: backgroundColor));
      return true;
    }

    return false;
  }
}

RenderView renderView;

void beginFrame(double timeStamp) {
  RenderNode.flushLayout();

  renderView.paintFrame();
}

bool handleEvent(Event event) {
  if (event is! PointerEvent)
    return false;
  return renderView.handlePointer(event, x: event.x, y: event.y);
}

void main() {
  view.setEventCallback(handleEvent);
  view.setBeginFrameCallback(beginFrame);

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
  root.add(new RenderSolidColor(0x7700FFFF, desiredHeight: 100.0, desiredWidth: 100.0));

  // Green and cyan render block with padding
  var renderBlock = new RenderBlock(
      decoration: new BoxDecoration(backgroundColor: 0xFFFFFFFF),
      padding: const EdgeDims(10.0, 10.0, 10.0, 10.0));

  renderBlock.add(new RenderSolidColor(0xFF00FF00, desiredHeight: 50.0, desiredWidth: 100.0));
  renderBlock.add(new RenderSolidColor(0x7700FFFF, desiredHeight: 100.0, desiredWidth: 50.0));

  root.add(renderBlock);

  var row = new RenderFlex(
    direction: FlexDirection.Horizontal,
    decoration: new BoxDecoration(backgroundColor: 0xFF333333));

  // Purple and blue cells
  addFlexChild(row, 0x77FF00FF, flex: 1);
  addFlexChild(row, 0xFF0000FF, flex: 2);

  root.add(row);
  row.parentData.flex = 3;

  renderView = new RenderView(root: root);
  renderView.layout(newWidth: view.width, newHeight: view.height);

  view.scheduleFrame();
}
