// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:sky' as sky;

import '../base/scheduler.dart' as scheduler;
import '../base/hit_test.dart';
import 'box.dart';
import 'object.dart';

class PointerState {
  PointerState({ this.result, this.lastPosition });
  HitTestResult result;
  Point lastPosition;
}

typedef void EventListener(sky.Event event);

class SkyBinding {

  SkyBinding({ RenderBox root: null, RenderView renderViewOverride }) {
    assert(_instance == null);
    _instance = this;

    sky.view.setEventCallback(_handleEvent);

    sky.view.setMetricsChangedCallback(_handleMetricsChanged);
    scheduler.init();
    if (renderViewOverride == null) {
      _renderView = new RenderView(child: root);
      _renderView.attach();
      _renderView.rootConstraints = _createConstraints();
      _renderView.scheduleInitialLayout();
    } else {
      _renderView = renderViewOverride;
    }
    assert(_renderView != null);
    scheduler.addPersistentFrameCallback(_beginFrame);

    assert(_instance == this);
  }

  static SkyBinding _instance; // used to enforce that we're a singleton
  static SkyBinding get instance => _instance;

  RenderView _renderView;
  RenderView get renderView => _renderView;

  ViewConstraints _createConstraints() {
    return new ViewConstraints(width: sky.view.width, height: sky.view.height);
  }
  void _handleMetricsChanged() {
    _renderView.rootConstraints = _createConstraints();
  }

  Function onFrame;
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

  final List<EventListener> _eventListeners = new List<EventListener>();
  void addEventListener(EventListener e) => _eventListeners.add(e);
  bool removeEventListener(EventListener e) => _eventListeners.remove(e);

  void _handleEvent(sky.Event event) {
    if (event is sky.PointerEvent) {
      _handlePointerEvent(event);
    } else if (event is sky.GestureEvent) {
      HitTestResult result = new HitTestResult();
      _renderView.hitTest(result, position: new Point(event.x, event.y));
      dispatchEvent(event, result);
    } else {
      for (EventListener e in _eventListeners)
        e(event);
    }
  }

  Map<int, PointerState> _stateForPointer = new Map<int, PointerState>();

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
