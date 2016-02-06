// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'arena.dart';
import 'recognizer.dart';
import 'constants.dart';
import 'events.dart';
import 'velocity_tracker.dart';

enum DragState {
  ready,
  possible,
  accepted
}

typedef void GestureDragDownCallback(Point globalPosition);
typedef void GestureDragStartCallback(Point globalPosition);
typedef void GestureDragUpdateCallback(double delta);
typedef void GestureDragEndCallback(Offset velocity);
typedef void GestureDragCancelCallback();

typedef void GesturePanDownCallback(Point globalPosition);
typedef void GesturePanStartCallback(Point globalPosition);
typedef void GesturePanUpdateCallback(Offset delta);
typedef void GesturePanEndCallback(Offset velocity);
typedef void GesturePanCancelCallback();

typedef void _GesturePolymorphicUpdateCallback<T>(T delta);

bool _isFlingGesture(Offset velocity) {
  assert(velocity != null);
  double velocitySquared = velocity.dx * velocity.dx + velocity.dy * velocity.dy;
  return velocitySquared > kMinFlingVelocity * kMinFlingVelocity
      && velocitySquared < kMaxFlingVelocity * kMaxFlingVelocity;
}

abstract class _DragGestureRecognizer<T extends dynamic> extends OneSequenceGestureRecognizer {
  _DragGestureRecognizer({
    PointerRouter router,
    GestureArena gestureArena,
    this.onDown,
    this.onStart,
    this.onUpdate,
    this.onEnd,
    this.onCancel
  }) : super(
    router: router,
    gestureArena: gestureArena
  );

  GestureDragDownCallback onDown;
  GestureDragStartCallback onStart;
  _GesturePolymorphicUpdateCallback<T> onUpdate;
  GestureDragEndCallback onEnd;
  GestureDragCancelCallback onCancel;

  DragState _state = DragState.ready;
  Point _initialPosition;
  T _pendingDragDelta;
  bool _sentDown = false;
  Timer _timer;

  T get _initialPendingDragDelta;
  T _getDragDelta(PointerEvent event);
  bool get _hasSufficientPendingDragDeltaToAccept;

  Map<int, VelocityTracker> _velocityTrackers = new Map<int, VelocityTracker>();

  void addPointer(PointerEvent event) {
    startTrackingPointer(event.pointer);
    _velocityTrackers[event.pointer] = new VelocityTracker();
    if (_state == DragState.ready) {
      _state = DragState.possible;
      _initialPosition = event.position;
      _pendingDragDelta = _initialPendingDragDelta;
      _timer = new Timer(kPressTimeout, _checkDown);
    }
  }

  void _checkDown() {
    if (!_sentDown) {
      if (onDown != null)
        onDown(_initialPosition);
      _sentDown = true;
    }
  }

  void handleEvent(PointerEvent event) {
    assert(_state != DragState.ready);
    if (event is PointerMoveEvent) {
      VelocityTracker tracker = _velocityTrackers[event.pointer];
      assert(tracker != null);
      tracker.addPosition(event.timeStamp, event.position);
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
      _checkDown();
      if (onStart != null)
        onStart(_initialPosition);
      if (delta != _initialPendingDragDelta && onUpdate != null)
        onUpdate(delta);
    }
  }

  void rejectGesture(int pointer) {
    ensureNotTrackingPointer(pointer);
  }

  void didStopTrackingLastPointer(int pointer) {
    if (_state == DragState.possible) {
      resolve(GestureDisposition.rejected);
      _state = DragState.ready;
      _timer?.cancel();
      _timer = null;
      if (_sentDown && onCancel != null)
        onCancel();
      return;
    }
    bool wasAccepted = (_state == DragState.accepted);
    _state = DragState.ready;
    if (wasAccepted && onEnd != null) {
      VelocityTracker tracker = _velocityTrackers[pointer];
      assert(tracker != null);

      Offset velocity = tracker.getVelocity();
      if (velocity != null && _isFlingGesture(velocity))
        onEnd(velocity);
      else
        onEnd(Offset.zero);
    }
    _velocityTrackers.clear();
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
    _velocityTrackers.clear();
    super.dispose();
  }
}

class VerticalDragGestureRecognizer extends _DragGestureRecognizer<double> {
  VerticalDragGestureRecognizer({
    PointerRouter router,
    GestureArena gestureArena,
    GestureDragDownCallback onDown,
    GestureDragStartCallback onStart,
    GestureDragUpdateCallback onUpdate,
    GestureDragEndCallback onEnd,
    GestureDragCancelCallback onCancel
  }) : super(
    router: router,
    gestureArena: gestureArena,
    onDown: onDown,
    onStart: onStart,
    onUpdate: onUpdate,
    onEnd: onEnd,
    onCancel: onCancel
  );

  double get _initialPendingDragDelta => 0.0;
  double _getDragDelta(PointerEvent event) => event.delta.dy;
  bool get _hasSufficientPendingDragDeltaToAccept => _pendingDragDelta.abs() > kTouchSlop;
}

class HorizontalDragGestureRecognizer extends _DragGestureRecognizer<double> {
  HorizontalDragGestureRecognizer({
    PointerRouter router,
    GestureArena gestureArena,
    GestureDragDownCallback onDown,
    GestureDragStartCallback onStart,
    GestureDragUpdateCallback onUpdate,
    GestureDragEndCallback onEnd,
    GestureDragCancelCallback onCancel
  }) : super(
    router: router,
    gestureArena: gestureArena,
    onDown: onDown,
    onStart: onStart,
    onUpdate: onUpdate,
    onEnd: onEnd,
    onCancel: onCancel
  );

  double get _initialPendingDragDelta => 0.0;
  double _getDragDelta(PointerEvent event) => event.delta.dx;
  bool get _hasSufficientPendingDragDeltaToAccept => _pendingDragDelta.abs() > kTouchSlop;
}

class PanGestureRecognizer extends _DragGestureRecognizer<Offset> {
  PanGestureRecognizer({
    PointerRouter router,
    GestureArena gestureArena,
    GesturePanDownCallback onDown,
    GesturePanStartCallback onStart,
    GesturePanUpdateCallback onUpdate,
    GesturePanEndCallback onEnd,
    GesturePanCancelCallback onCancel
  }) : super(
    router: router,
    gestureArena: gestureArena,
    onDown: onDown,
    onStart: onStart,
    onUpdate: onUpdate,
    onEnd: onEnd,
    onCancel: onCancel
  );

  Offset get _initialPendingDragDelta => Offset.zero;
  Offset _getDragDelta(PointerEvent event) => event.delta;
  bool get _hasSufficientPendingDragDeltaToAccept {
    return _pendingDragDelta.distance > kPanSlop;
  }
}
