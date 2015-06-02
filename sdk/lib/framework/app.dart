// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:sky' as sky;
import 'rendering/box.dart';
import 'rendering/node.dart';
import 'scheduler.dart' as scheduler;

class AppView {

  AppView(RenderBox root) {
    sky.view.setEventCallback(_handleEvent);
    scheduler.init();
    scheduler.addPersistentFrameCallback(_beginFrame);

    _renderView = new RenderView(child: root);
    _renderView.attach();
    _renderView.layout(new ViewConstraints(width: sky.view.width,
                                           height: sky.view.height));

    scheduler.ensureVisualUpdate();
  }

  RenderView _renderView;

  Map<int, HitTestResult> _hitTestResultForPointer = new Map<int, HitTestResult>();

  RenderBox get root => _renderView.child;
  void set root(RenderBox value) {
    _renderView.child = value;
  }
  void _beginFrame(double timeStamp) {
    RenderNode.flushLayout();
    _renderView.paintFrame();
  }

  void _handleEvent(sky.Event event) {
    if (event is sky.PointerEvent)
      _handlePointerEvent(event);
  }

  void _handlePointerEvent(sky.PointerEvent event) {
    HitTestResult result;
    switch(event.type) {
      case 'pointerdown':
        result = new HitTestResult();
        _renderView.hitTest(result, position: new sky.Point(event.x, event.y));
        _hitTestResultForPointer[event.pointer] = result;
        break;
      case 'pointerup':
      case 'pointercancel':
        result = _hitTestResultForPointer[event.pointer];
        _hitTestResultForPointer.remove(event.pointer);
        break;
      case 'pointermove':
        result = _hitTestResultForPointer[event.pointer];
        // In the case of mouse hover we won't already have a cached down.
        if (result == null) {
          result = new HitTestResult();
          _renderView.hitTest(result, position: new sky.Point(event.x, event.y));
        }
        break;
    }
    dispatchPointerEvent(event, result);
  }

  void dispatchPointerEvent(sky.PointerEvent event, HitTestResult result) {
    assert(result != null);
    for (RenderNode node in result.path.reversed)
      node.handlePointer(event);
  }
}
