// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math';
import 'dart:sky';
import 'package:sky/framework/layout2.dart';

class RenderSolidColor extends RenderDecoratedBox {
  final int backgroundColor;

  RenderSolidColor(int backgroundColor)
      : super(new BoxDecoration(backgroundColor: backgroundColor)),
        backgroundColor = backgroundColor;

  BoxDimensions getIntrinsicDimensions(BoxConstraints constraints) {
    return new BoxDimensions.withConstraints(constraints, height: 200.0);
  }

  void layout(BoxConstraints constraints, { RenderNode relayoutSubtreeRoot }) {
    setWidth(constraints, constraints.maxWidth);
    setHeight(constraints, 200.0);
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

  var root = new RenderBlock(
      decoration: new BoxDecoration(backgroundColor: 0xFF00FFFF));

  root.add(new RenderSolidColor(0xFF00FF00));
  root.add(new RenderSolidColor(0xFF0000FF));

  renderView = new RenderView(root: root);
  renderView.layout(newWidth: view.width, newHeight: view.height);

  view.scheduleFrame();
}
