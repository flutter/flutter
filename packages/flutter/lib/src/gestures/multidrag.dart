// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:ui' show Point, Offset;

import 'arena.dart';
import 'binding.dart';
import 'constants.dart';
import 'events.dart';
import 'recognizer.dart';
import 'velocity_tracker.dart';

typedef Drag GestureMultiDragStartCallback(Point position);

class Drag {
  void move(Offset offset) { }
  void end(Velocity velocity) { }
  void cancel() { }
}

abstract class MultiDragPointerState {
  MultiDragPointerState(this.initialPosition);

  final Point initialPosition;

  final VelocityTracker _velocityTracker = new VelocityTracker();
  Drag _client;

  Offset get pendingDelta => _pendingDelta;
  Offset _pendingDelta = Offset.zero;

  GestureArenaEntry _arenaEntry;
  void _setArenaEntry(GestureArenaEntry entry) {
    assert(_arenaEntry == null);
    assert(pendingDelta != null);
    assert(_client == null);
    _arenaEntry = entry;
  }

  void resolve(GestureDisposition disposition) {
    _arenaEntry.resolve(disposition);
  }

  void _move(PointerMoveEvent event) {
    assert(_arenaEntry != null);
    _velocityTracker.addPosition(event.timeStamp, event.position);
    if (_client != null) {
      assert(pendingDelta == null);
      _client.move(event.delta);
    } else {
      assert(pendingDelta != null);
      _pendingDelta += event.delta;
      checkForResolutionAfterMove();
    }
    return null;
  }

  /// Override this to call resolve() if the drag should be accepted or rejected.
  /// This is called when a pointer movement is received, but only if the gesture
  /// has not yet been resolved.
  void checkForResolutionAfterMove() { }

  /// Called when the gesture was accepted.
  ///
  /// Either immediately or at some future point before the gesture is disposed,
  /// call starter(), passing it initialPosition, to start the drag.
  void accepted(GestureMultiDragStartCallback starter);

  /// Called when the gesture was rejected.
  ///
  /// [dispose()] will be called immediately following this.
  void rejected() {
    assert(_arenaEntry != null);
    assert(_client == null);
    assert(pendingDelta != null);
    _pendingDelta = null;
    _arenaEntry = null;
  }

  void _startDrag(Drag client) {
    assert(_arenaEntry != null);
    assert(_client == null);
    assert(client != null);
    assert(pendingDelta != null);
    _client = client;
    _client.move(pendingDelta);
    _pendingDelta = null;
  }

  void _up() {
    assert(_arenaEntry != null);
    if (_client != null) {
      assert(pendingDelta == null);
      _client.end(_velocityTracker.getVelocity());
      _client = null;
    } else {
      assert(pendingDelta != null);
      _pendingDelta = null;
    }
    _arenaEntry = null;
  }

  void _cancel() {
    assert(_arenaEntry != null);
    if (_client != null) {
      assert(pendingDelta == null);
      _client.cancel();
      _client = null;
    } else {
      assert(pendingDelta != null);
      _pendingDelta = null;
    }
    _arenaEntry = null;
  }

  void dispose() {
    assert(() { _pendingDelta = null; return true; });
  }
}

abstract class MultiDragGestureRecognizer<T extends MultiDragPointerState> extends GestureRecognizer {
  GestureMultiDragStartCallback onStart;

  Map<int, T> _pointers = <int, T>{};

  @override
  void addPointer(PointerDownEvent event) {
    assert(_pointers != null);
    assert(event.pointer != null);
    assert(event.position != null);
    assert(!_pointers.containsKey(event.pointer));
    T state = createNewPointerState(event);
    _pointers[event.pointer] = state;
    GestureBinding.instance.pointerRouter.addRoute(event.pointer, handleEvent);
    state._setArenaEntry(GestureBinding.instance.gestureArena.add(event.pointer, this));
  }

  T createNewPointerState(PointerDownEvent event);

  void handleEvent(PointerEvent event) {
    assert(_pointers != null);
    assert(event.pointer != null);
    assert(event.timeStamp != null);
    assert(event.position != null);
    assert(_pointers.containsKey(event.pointer));
    T state = _pointers[event.pointer];
    if (event is PointerMoveEvent) {
      state._move(event);
    } else if (event is PointerUpEvent) {
      assert(event.delta == Offset.zero);
      state._up();
      _removeState(event.pointer);
    } else if (event is PointerCancelEvent) {
      assert(event.delta == Offset.zero);
      state._cancel();
      _removeState(event.pointer);
    } else if (event is! PointerDownEvent) {
      // we get the PointerDownEvent that resulted in our addPointer gettig called since we
      // add ourselves to the pointer router then (before the pointer router has heard of
      // the event).
      assert(false);
    }
  }

  @override
  void acceptGesture(int pointer) {
    assert(_pointers != null);
    T state = _pointers[pointer];
    assert(state != null);
    state.accepted((Point initialPosition) => _startDrag(initialPosition, pointer));
  }

  Drag _startDrag(Point initialPosition, int pointer) {
    assert(_pointers != null);
    T state = _pointers[pointer];
    assert(state != null);
    assert(state._pendingDelta != null);
    Drag drag;
    if (onStart != null)
      drag = onStart(initialPosition);
    if (drag != null) {
      state._startDrag(drag);
    } else {
      _removeState(pointer);
    }
    return drag;
  }

  @override
  void rejectGesture(int pointer) {
    assert(_pointers != null);
    if (_pointers.containsKey(pointer)) {
      T state = _pointers[pointer];
      assert(state != null);
      state.rejected();
      _removeState(pointer);
    } // else we already preemptively forgot about it (e.g. we got an up event)
  }

  void _removeState(int pointer) {
    assert(_pointers != null);
    assert(_pointers.containsKey(pointer));
    GestureBinding.instance.pointerRouter.removeRoute(pointer, handleEvent);
    _pointers[pointer].dispose();
    _pointers.remove(pointer);
  }

  @override
  void dispose() {
    for (int pointer in _pointers.keys)
      _removeState(pointer);
    _pointers = null;
    super.dispose();
  }

}


class _ImmediatePointerState extends MultiDragPointerState {
  _ImmediatePointerState(Point initialPosition) : super(initialPosition);

  @override
  void checkForResolutionAfterMove() {
    assert(pendingDelta != null);
    if (pendingDelta.distance > kTouchSlop)
      resolve(GestureDisposition.accepted);
  }

  @override
  void accepted(GestureMultiDragStartCallback starter) {
    starter(initialPosition);
  }
}

class ImmediateMultiDragGestureRecognizer extends MultiDragGestureRecognizer<_ImmediatePointerState> {
  @override
  _ImmediatePointerState createNewPointerState(PointerDownEvent event) {
    return new _ImmediatePointerState(event.position);
  }

  @override
  String toStringShort() => 'multidrag';
}


class _HorizontalPointerState extends MultiDragPointerState {
  _HorizontalPointerState(Point initialPosition) : super(initialPosition);

  @override
  void checkForResolutionAfterMove() {
    assert(pendingDelta != null);
    if (pendingDelta.dx.abs() > kTouchSlop)
      resolve(GestureDisposition.accepted);
  }

  @override
  void accepted(GestureMultiDragStartCallback starter) {
    starter(initialPosition);
  }
}

class HorizontalMultiDragGestureRecognizer extends MultiDragGestureRecognizer<_HorizontalPointerState> {
  @override
  _HorizontalPointerState createNewPointerState(PointerDownEvent event) {
    return new _HorizontalPointerState(event.position);
  }

  @override
  String toStringShort() => 'horizontal multidrag';
}


class _VerticalPointerState extends MultiDragPointerState {
  _VerticalPointerState(Point initialPosition) : super(initialPosition);

  @override
  void checkForResolutionAfterMove() {
    assert(pendingDelta != null);
    if (pendingDelta.dy.abs() > kTouchSlop)
      resolve(GestureDisposition.accepted);
  }

  @override
  void accepted(GestureMultiDragStartCallback starter) {
    starter(initialPosition);
  }
}

class VerticalMultiDragGestureRecognizer extends MultiDragGestureRecognizer<_VerticalPointerState> {
  @override
  _VerticalPointerState createNewPointerState(PointerDownEvent event) {
    return new _VerticalPointerState(event.position);
  }

  @override
  String toStringShort() => 'vertical multidrag';
}


class _DelayedPointerState extends MultiDragPointerState {
  _DelayedPointerState(Point initialPosition, Duration delay) : super(initialPosition) {
    assert(delay != null);
    _timer = new Timer(delay, _delayPassed);
  }

  Timer _timer;
  GestureMultiDragStartCallback _starter;

  void _delayPassed() {
    assert(_timer != null);
    assert(pendingDelta != null);
    assert(pendingDelta.distance <= kTouchSlop);
    _timer = null;
    if (_starter != null) {
      _starter(initialPosition);
      _starter = null;
    } else {
      resolve(GestureDisposition.accepted);
    }
    assert(_starter == null);
  }

  @override
  void accepted(GestureMultiDragStartCallback starter) {
    assert(_starter == null);
    if (_timer == null)
      starter(initialPosition);
    else
      _starter = starter;
  }

  @override
  void checkForResolutionAfterMove() {
    assert(_timer != null);
    assert(pendingDelta != null);
    if (pendingDelta.distance > kTouchSlop)
      resolve(GestureDisposition.rejected);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timer = null;
    super.dispose();
  }
}

class DelayedMultiDragGestureRecognizer extends MultiDragGestureRecognizer<_DelayedPointerState> {
  DelayedMultiDragGestureRecognizer({
    Duration delay: kLongPressTimeout
  }) : _delay = delay {
    assert(delay != null);
  }

  Duration get delay => _delay;
  Duration _delay;
  void set delay(Duration value) {
    assert(value != null);
    _delay = value;
  }

  @override
  _DelayedPointerState createNewPointerState(PointerDownEvent event) {
    return new _DelayedPointerState(event.position, _delay);
  }

  @override
  String toStringShort() => 'long multidrag';
}
