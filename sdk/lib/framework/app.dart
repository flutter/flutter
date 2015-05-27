// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'layout2.dart';
import 'dart:sky' as sky;

class AppView {

  AppView(RenderBox root) {
    sky.view.setEventCallback(_handleEvent);
    sky.view.setBeginFrameCallback(_beginFrame);

    _renderView = new RenderView(child: root);
    _renderView.attach();
    _renderView.layout(newWidth: sky.view.width, newHeight: sky.view.height);
  
    sky.view.scheduleFrame();
  }

  RenderView _renderView;

  RenderBox get root => _renderView.child;
  void set root(RenderBox value) {
    _renderView.child = value;
  }

  void _beginFrame(double timeStamp) {
    RenderNode.flushLayout();
    _renderView.paintFrame();
  }

  void _handleEvent(sky.Event event) {
    if (event is! sky.PointerEvent)
      return;
    HitTestResult result = new HitTestResult();
    _renderView.hitTest(result, x: event.x, y: event.y);
    result.path.reversed.forEach((RenderNode node) {
      node.handlePointer(event);
    });
  }

}
