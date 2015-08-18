// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:sky' as sky;

import 'package:sky/base/hit_test.dart';
import 'package:sky/base/scheduler.dart' as scheduler;
import 'package:sky/rendering/box.dart';
import 'package:sky/rendering/object.dart';
import 'package:sky/rendering/view.dart';

int _hammingWeight(int value) {
  if (value == 0)
    return 0;
  int weight = 0;
  for (int i = 0; i < value.bitLength; ++i) {
    if (value & (1 << i) != 0)
      ++weight;
  }
  return weight;
}

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
    scheduler.addPersistentFrameCallback(beginFrame);

    assert(_instance == this);
  }

  static SkyBinding _instance; // used to enforce that we're a singleton
  static SkyBinding get instance => _instance;

  RenderView _renderView;
  RenderView get renderView => _renderView;

  ViewConstraints _createConstraints() {
    return new ViewConstraints(size: new Size(sky.view.width, sky.view.height));
  }
  void _handleMetricsChanged() {
    _renderView.rootConstraints = _createConstraints();
  }

  RenderBox get root => _renderView.child;
  void set root(RenderBox value) {
    _renderView.child = value;
  }
  void beginFrame(double timeStamp) {
    RenderObject.flushLayout();
    _renderView.updateCompositingBits();
    RenderObject.flushPaint();
    _renderView.paintFrame();
    _renderView.compositeFrame();
  }

  final List<EventListener> _eventListeners = new List<EventListener>();
  void addEventListener(EventListener e) => _eventListeners.add(e);
  bool removeEventListener(EventListener e) => _eventListeners.remove(e);

  void _handleEvent(sky.Event event) {
    if (event is sky.PointerEvent) {
      _handlePointerEvent(event);
    } else if (event is sky.GestureEvent) {
      dispatchEvent(event, hitTest(new Point(event.x, event.y)));
    } else {
      for (EventListener e in _eventListeners)
        e(event);
    }
  }

  Map<int, PointerState> _stateForPointer = new Map<int, PointerState>();

  PointerState _createStateForPointer(sky.PointerEvent event, Point position) {
    HitTestResult result = hitTest(position);
    PointerState state = new PointerState(result: result, lastPosition: position);
    _stateForPointer[event.pointer] = state;
    return state;
  }

  PointerState _getOrCreateStateForPointer(event, position) {
    PointerState state = _stateForPointer[event.pointer];
    if (state == null)
      state = _createStateForPointer(event, position);
    return state;
  }

  EventDisposition _handlePointerEvent(sky.PointerEvent event) {
    Point position = new Point(event.x, event.y);

    PointerState state = _getOrCreateStateForPointer(event, position);

    if (event.type == 'pointerup' || event.type == 'pointercancel') {
      if (_hammingWeight(event.buttons) <= 1)
        _stateForPointer.remove(event.pointer);
    }

    event.dx = position.x - state.lastPosition.x;
    event.dy = position.y - state.lastPosition.y;
    state.lastPosition = position;

    return dispatchEvent(event, state.result);
  }

  HitTestResult hitTest(Point position) {
    HitTestResult result = new HitTestResult();
    _renderView.hitTest(result, position: position);
    return result;
  }

  EventDisposition dispatchEvent(sky.Event event, HitTestResult result) {
    assert(result != null);
    EventDisposition disposition = EventDisposition.ignored;
    for (HitTestEntry entry in result.path.reversed) {
      EventDisposition entryDisposition = entry.target.handleEvent(event, entry);
      if (entryDisposition == EventDisposition.consumed)
        return EventDisposition.consumed;
      else if (entryDisposition == EventDisposition.processed)
        disposition = EventDisposition.processed;
    }
    return disposition;
  }

  String toString() => 'Render Tree:\n${_renderView}';

  void debugDumpRenderTree() {
    toString().split('\n').forEach(print);
  }

}
