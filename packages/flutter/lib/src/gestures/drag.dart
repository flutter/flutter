// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;

import 'arena.dart';
import 'recognizer.dart';
import 'constants.dart';
import 'events.dart';

enum DragState {
  ready,
  possible,
  accepted
}

typedef void GestureDragStartCallback();
typedef void GestureDragUpdateCallback(double delta);
typedef void GestureDragEndCallback(ui.Offset velocity);

typedef void GesturePanStartCallback();
typedef void GesturePanUpdateCallback(ui.Offset delta);
typedef void GesturePanEndCallback(ui.Offset velocity);

typedef void _GesturePolymorphicUpdateCallback<T>(T delta);

int _eventTime(PointerInputEvent event) => (event.timeStamp * 1000.0).toInt(); // microseconds

bool _isFlingGesture(ui.GestureVelocity velocity) {
  double velocitySquared = velocity.x * velocity.x + velocity.y * velocity.y;
  return velocity.isValid &&
    velocitySquared > kMinFlingVelocity * kMinFlingVelocity &&
    velocitySquared < kMaxFlingVelocity * kMaxFlingVelocity;
}

abstract class _DragGestureRecognizer<T extends dynamic> extends GestureRecognizer {
  _DragGestureRecognizer({ PointerRouter router, this.onStart, this.onUpdate, this.onEnd })
    : super(router: router);

  GestureDragStartCallback onStart;
  _GesturePolymorphicUpdateCallback<T> onUpdate;
  GestureDragEndCallback onEnd;

  DragState _state = DragState.ready;
  T _pendingDragDelta;

  T get _initialPendingDragDelta;
  T _getDragDelta(PointerInputEvent event);
  bool get _hasSufficientPendingDragDeltaToAccept;

  final ui.VelocityTracker _velocityTracker = new ui.VelocityTracker();

  void addPointer(PointerInputEvent event) {
    startTrackingPointer(event.pointer);
    if (_state == DragState.ready) {
      _state = DragState.possible;
      _pendingDragDelta = _initialPendingDragDelta;
    }
  }

  void handleEvent(PointerInputEvent event) {
    assert(_state != DragState.ready);
    if (event.type == 'pointermove') {
      _velocityTracker.addPosition(_eventTime(event), event.pointer, event.x, event.y);
      T delta = _getDragDelta(event);
      if (_state == DragState.accepted) {
        if (onUpdate != null)
          onUpdate(delta);
      } else {
        _pendingDragDelta += delta;
        if (_hasSufficientPendingDragDeltaToAccept)
          resolve(GestureDisposition.accepted);
      }
    }
    stopTrackingIfPointerNoLongerDown(event);
  }

  void acceptGesture(int pointer) {
    if (_state != DragState.accepted) {
      _state = DragState.accepted;
      T delta = _pendingDragDelta;
      _pendingDragDelta = _initialPendingDragDelta;
      if (onStart != null)
        onStart();
      if (delta != _initialPendingDragDelta && onUpdate != null)
        onUpdate(delta);
    }
  }

  void didStopTrackingLastPointer(int pointer) {
    if (_state == DragState.possible) {
      resolve(GestureDisposition.rejected);
      _state = DragState.ready;
      return;
    }
    bool wasAccepted = (_state == DragState.accepted);
    _state = DragState.ready;
    if (wasAccepted && onEnd != null) {
      ui.GestureVelocity gestureVelocity = _velocityTracker.getVelocity(pointer);
      ui.Offset velocity = ui.Offset.zero;
      if (_isFlingGesture(gestureVelocity))
        velocity = new ui.Offset(gestureVelocity.x, gestureVelocity.y);
      onEnd(velocity);
    }
    _velocityTracker.reset();
  }

  void dispose() {
    _velocityTracker.reset();
    super.dispose();
  }
}

class VerticalDragGestureRecognizer extends _DragGestureRecognizer<double> {
  VerticalDragGestureRecognizer({
    PointerRouter router,
    GestureDragStartCallback onStart,
    GestureDragUpdateCallback onUpdate,
    GestureDragEndCallback onEnd
  }) : super(router: router, onStart: onStart, onUpdate: onUpdate, onEnd: onEnd);

  double get _initialPendingDragDelta => 0.0;
  double _getDragDelta(PointerInputEvent event) => event.dy;
  bool get _hasSufficientPendingDragDeltaToAccept => _pendingDragDelta.abs() > kTouchSlop;
}

class HorizontalDragGestureRecognizer extends _DragGestureRecognizer<double> {
  HorizontalDragGestureRecognizer({
    PointerRouter router,
    GestureDragStartCallback onStart,
    GestureDragUpdateCallback onUpdate,
    GestureDragEndCallback onEnd
  }) : super(router: router, onStart: onStart, onUpdate: onUpdate, onEnd: onEnd);

  double get _initialPendingDragDelta => 0.0;
  double _getDragDelta(PointerInputEvent event) => event.dx;
  bool get _hasSufficientPendingDragDeltaToAccept => _pendingDragDelta.abs() > kTouchSlop;
}

class PanGestureRecognizer extends _DragGestureRecognizer<ui.Offset> {
  PanGestureRecognizer({
    PointerRouter router,
    GesturePanStartCallback onStart,
    GesturePanUpdateCallback onUpdate,
    GesturePanEndCallback onEnd
  }) : super(router: router, onStart: onStart, onUpdate: onUpdate, onEnd: onEnd);

  ui.Offset get _initialPendingDragDelta => ui.Offset.zero;
  ui.Offset _getDragDelta(PointerInputEvent event) => new ui.Offset(event.dx, event.dy);
  bool get _hasSufficientPendingDragDeltaToAccept {
    return _pendingDragDelta.distance > kPanSlop;
  }
}
