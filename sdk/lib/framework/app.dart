// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:sky' as sky;
import 'rendering/box.dart';
import 'rendering/node.dart';
import 'scheduler.dart' as scheduler;

class PointerState {
  HitTestResult result;
  sky.Point lastPosition;

  PointerState({ this.result, this.lastPosition });
}

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

  Map<int, PointerState> _stateForPointer = new Map<int, PointerState>();

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
    sky.Point position = new sky.Point(event.x, event.y);

    PointerState state;
    switch(event.type) {
      case 'pointerdown':
        HitTestResult result = new HitTestResult();
        _renderView.hitTest(result, position: position);
        state = new PointerState(result: result, lastPosition: position);
        _stateForPointer[event.pointer] = state;
        break;
      case 'pointerup':
      case 'pointercancel':
        state = _stateForPointer[event.pointer];
        _stateForPointer.remove(event.pointer);
        break;
      case 'pointermove':
        state = _stateForPointer[event.pointer];
        // In the case of mouse hover we won't already have a cached down.
        if (state.result == null) {
          state.result = new HitTestResult();
          _renderView.hitTest(state.result, position: position);
        }
        break;
    }
    event.dx = position.x - state.lastPosition.x;
    event.dy = position.y - state.lastPosition.y;
    state.lastPosition = position;

    dispatchPointerEvent(event, state.result);
  }

  void dispatchPointerEvent(sky.PointerEvent event, HitTestResult result) {
    assert(result != null);
    for (RenderNode node in result.path.reversed)
      node.handlePointer(event);
  }
}
