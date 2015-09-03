// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:sky' as sky;

import 'package:sky/gestures/arena.dart';
import 'package:sky/gestures/recognizer.dart';
import 'package:sky/gestures/constants.dart';

enum ScrollState {
  ready,
  possible,
  accepted
}

typedef void GestureScrollStartCallback();
typedef void GestureScrollUpdateCallback(double scrollDelta);
typedef void GestureScrollEndCallback();

typedef void GesturePanStartCallback();
typedef void GesturePanUpdateCallback(sky.Offset scrollDelta);
typedef void GesturePanEndCallback();

typedef void _GesturePolymorphicUpdateCallback<T>(T scrollDelta);

abstract class _ScrollGestureRecognizer<T extends dynamic> extends GestureRecognizer {
  _ScrollGestureRecognizer({ PointerRouter router, this.onStart, this.onUpdate, this.onEnd })
    : super(router: router);

  GestureScrollStartCallback onStart;
  _GesturePolymorphicUpdateCallback<T> onUpdate;
  GestureScrollEndCallback onEnd;

  ScrollState _state = ScrollState.ready;
  T _pendingScrollDelta;

  T get _initialPendingScrollDelta;
  T _getScrollDelta(sky.PointerEvent event);
  bool get _hasSufficientPendingScrollDeltaToAccept;

  void addPointer(sky.PointerEvent event) {
    startTrackingPointer(event.pointer);
    if (_state == ScrollState.ready) {
      _state = ScrollState.possible;
      _pendingScrollDelta = _initialPendingScrollDelta;
    }
  }

  void handleEvent(sky.PointerEvent event) {
    assert(_state != ScrollState.ready);
    if (event.type == 'pointermove') {
      T delta = _getScrollDelta(event);
      if (_state == ScrollState.accepted) {
        if (onUpdate != null)
          onUpdate(delta);
      } else {
        _pendingScrollDelta += delta;
        if (_hasSufficientPendingScrollDeltaToAccept)
          resolve(GestureDisposition.accepted);
      }
    }
    stopTrackingIfPointerNoLongerDown(event);
  }

  void acceptGesture(int pointer) {
    if (_state != ScrollState.accepted) {
      _state = ScrollState.accepted;
      T delta = _pendingScrollDelta;
      _pendingScrollDelta = null;
      if (onStart != null)
        onStart();
      if (delta != _initialPendingScrollDelta && onUpdate != null)
        onUpdate(delta);
    }
  }

  void didStopTrackingLastPointer() {
    if (_state == ScrollState.possible) {
      resolve(GestureDisposition.rejected);
      _state = ScrollState.ready;
      return;
    }
    bool wasAccepted = (_state == ScrollState.accepted);
    _state = ScrollState.ready;
    if (wasAccepted && onEnd != null)
      onEnd();
  }
}

class VerticalScrollGestureRecognizer extends _ScrollGestureRecognizer<double> {
  VerticalScrollGestureRecognizer({
    PointerRouter router,
    GestureScrollStartCallback onStart,
    GestureScrollUpdateCallback onUpdate,
    GestureScrollEndCallback onEnd
  }) : super(router: router, onStart: onStart, onUpdate: onUpdate, onEnd: onEnd);

  double get _initialPendingScrollDelta => 0.0;
  // Notice that we negate dy because scroll offsets go in the opposite direction.
  double _getScrollDelta(sky.PointerEvent event) => -event.dy;
  bool get _hasSufficientPendingScrollDeltaToAccept => _pendingScrollDelta.abs() > kTouchSlop;
}

class HorizontalScrollGestureRecognizer extends _ScrollGestureRecognizer<double> {
  HorizontalScrollGestureRecognizer({
    PointerRouter router,
    GestureScrollStartCallback onStart,
    GestureScrollUpdateCallback onUpdate,
    GestureScrollEndCallback onEnd
  }) : super(router: router, onStart: onStart, onUpdate: onUpdate, onEnd: onEnd);

  double get _initialPendingScrollDelta => 0.0;
  double _getScrollDelta(sky.PointerEvent event) => -event.dx;
  bool get _hasSufficientPendingScrollDeltaToAccept => _pendingScrollDelta.abs() > kTouchSlop;
}

class PanGestureRecognizer extends _ScrollGestureRecognizer<sky.Offset> {
  PanGestureRecognizer({
    PointerRouter router,
    GesturePanStartCallback onStart,
    GesturePanUpdateCallback onUpdate,
    GesturePanEndCallback onEnd
  }) : super(router: router, onStart: onStart, onUpdate: onUpdate, onEnd: onEnd);

  sky.Offset get _initialPendingScrollDelta => sky.Offset.zero;
  // Notice that we negate dy because scroll offsets go in the opposite direction.
  sky.Offset _getScrollDelta(sky.PointerEvent event) => new sky.Offset(event.dx, -event.dy);
  bool get _hasSufficientPendingScrollDeltaToAccept {
    return _pendingScrollDelta.dx.abs() > kTouchSlop || _pendingScrollDelta.dy.abs() > kTouchSlop;
  }
}
