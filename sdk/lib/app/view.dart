// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:sky' as sky;

import '../rendering/box.dart';
import '../rendering/object.dart';
import 'scheduler.dart' as scheduler;

class PointerState {
  HitTestResult result;
  Point lastPosition;

  PointerState({ this.result, this.lastPosition });
}

class AppView {

  AppView({ RenderBox root: null, RenderView renderViewOverride }) {
    assert(_app == null);
    _app = this;

    sky.view.setEventCallback(_handleEvent);
    sky.view.setMetricsChangedCallback(_handleMetricsChanged);
    scheduler.init();
    scheduler.addPersistentFrameCallback(_beginFrame);

    if (renderViewOverride == null) {
      _renderView = new RenderView(child: root);
      _renderView.attach();
      _renderView.rootConstraints = _viewConstraints;
      _renderView.scheduleInitialLayout();
    } else {
      _renderView = renderViewOverride;
    }
    assert(_renderView != null);

    assert(_app == this);
  }

  static AppView _app; // used to enforce that we're a singleton

  RenderView _renderView;

  ViewConstraints get _viewConstraints =>
      new ViewConstraints(width: sky.view.width, height: sky.view.height);

  Map<int, PointerState> _stateForPointer = new Map<int, PointerState>();

  Function onFrame;

  List<sky.EventListener> eventListeners = new List<sky.EventListener>();

  RenderBox get root => _renderView.child;
  void set root(RenderBox value) {
    _renderView.child = value;
  }
  void _beginFrame(double timeStamp) {
    if (onFrame != null)
      onFrame();
    RenderObject.flushLayout();
    _renderView.paintFrame();
  }

  void _handleEvent(sky.Event event) {
    if (event is sky.PointerEvent) {
      _handlePointerEvent(event);
    } else if (event is sky.GestureEvent) {
      HitTestResult result = new HitTestResult();
      _renderView.hitTest(result, position: new Point(event.x, event.y));
      dispatchEvent(event, result);
    } else {
      for (sky.EventListener listener in eventListeners) {
        listener(event);
      }
    }
  }

  void _handleMetricsChanged() {
    _renderView.rootConstraints = _viewConstraints;
  }

  PointerState _createStateForPointer(sky.PointerEvent event, Point position) {
    HitTestResult result = new HitTestResult();
    _renderView.hitTest(result, position: position);
    PointerState state = new PointerState(result: result, lastPosition: position);
    _stateForPointer[event.pointer] = state;
    return state;
  }

  void _handlePointerEvent(sky.PointerEvent event) {
    Point position = new Point(event.x, event.y);

    PointerState state;
    switch(event.type) {
      case 'pointerdown':
        state = _createStateForPointer(event, position);
        break;
      case 'pointerup':
      case 'pointercancel':
        state = _stateForPointer[event.pointer];
        _stateForPointer.remove(event.pointer);
        break;
      case 'pointermove':
        state = _stateForPointer[event.pointer];
        // In the case of mouse hover we won't already have a cached down.
        if (state == null)
          state = _createStateForPointer(event, position);
        break;
    }
    event.dx = position.x - state.lastPosition.x;
    event.dy = position.y - state.lastPosition.y;
    state.lastPosition = position;

    dispatchEvent(event, state.result);
  }

  void dispatchEvent(sky.Event event, HitTestResult result) {
    assert(result != null);
    for (HitTestEntry entry in result.path.reversed)
      entry.target.handleEvent(event, entry);
  }

  String toString() => 'Render Tree:\n${_renderView}';

  void debugDumpRenderTree() {
    toString().split('\n').forEach(print);
  }
  
}
