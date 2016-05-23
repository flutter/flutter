// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'arena.dart';
import 'recognizer.dart';
import 'constants.dart';
import 'events.dart';
import 'velocity_tracker.dart';

enum _DragState {
  ready,
  possible,
  accepted,
}

/// Signature for when a pointer has contacted the screen and might begin to move.
typedef void GestureDragDownCallback(Point globalPosition);

/// Signature for when a pointer has contacted the screen and has begun to move.
typedef void GestureDragStartCallback(Point globalPosition);

/// Signature for when a pointer that is in contact with the screen and moving
/// in a direction (e.g., vertically or horizontally) has moved in that
/// direction.
typedef void GestureDragUpdateCallback(double delta);

/// Signature for when a pointer that was previously in contact with the screen
/// and moving in a direction (e.g., vertically or horizontally) is no longer in
/// contact with the screen and was moving at a specific velocity when it
/// stopped contacting the screen.
typedef void GestureDragEndCallback(Velocity velocity);

/// Signature for when the pointer that previously triggered a
/// [GestureDragDownCallback] did not complete.
typedef void GestureDragCancelCallback();

/// Signature for when a pointer has contacted the screen and might begin to move.
typedef void GesturePanDownCallback(Point globalPosition);

/// Signature for when a pointer has contacted the screen and has begun to move.
typedef void GesturePanStartCallback(Point globalPosition);

/// Signature for when a pointer that is in contact with the screen and moving
/// has moved again.
typedef void GesturePanUpdateCallback(Offset delta);

/// Signature for when a pointer that was previously in contact with the screen
/// and moving is no longer in contact with the screen and was moving at a
/// specific velocity when it stopped contacting the screen.
typedef void GesturePanEndCallback(Velocity velocity);

/// Signature for when the pointer that previously triggered a
/// [GesturePanDownCallback] did not complete.
typedef void GesturePanCancelCallback();

/// Signature for when a pointer that is in contact with the screen and moving
/// has moved again. For one-dimensional drags (e.g., horizontal or vertical),
/// T is `double`, as in [GestureDragUpdateCallback]. For two-dimensional drags
/// (e.g., pans), T is `Offset`, as in GesturePanUpdateCallback.
typedef void GesturePolymorphicUpdateCallback<T>(T delta);

bool _isFlingGesture(Velocity velocity) {
  assert(velocity != null);
  final double speedSquared = velocity.pixelsPerSecond.distanceSquared;
  return speedSquared > kMinFlingVelocity * kMinFlingVelocity;
}

/// Recognizes movement.
///
/// In contrast to [MultiDragGestureRecognizer], [DragGestureRecognizer]
/// recognizes a single gesture sequence for all the pointers it watches, which
/// means that the recognizer has at most one drag sequence active at any given
/// time regardless of how many pointers are in contact with the screen.
///
/// [DragGestureRecognizer] is not intended to be used directly. Instead,
/// consider using one of its subclasses to recognize specific types for drag
/// gestures.
///
/// See also:
///
///  * [HorizontalDragGestureRecognizer]
///  * [VerticalDragGestureRecognizer]
///  * [PanGestureRecognizer]
// Having T extend dynamic makes it possible to use the += operator on
// _pendingDragDelta without causing an analysis error.
abstract class DragGestureRecognizer<T extends dynamic> extends OneSequenceGestureRecognizer {
  /// A pointer has contacted the screen and might begin to move.
  GestureDragDownCallback onDown;

  /// A pointer has contacted the screen and has begun to move.
  GestureDragStartCallback onStart;

  /// A pointer that is in contact with the screen and moving has moved again.
  GesturePolymorphicUpdateCallback<T> onUpdate;

  /// A pointer that was previously in contact with the screen and moving is no
  /// longer in contact with the screen and was moving at a specific velocity
  /// when it stopped contacting the screen.
  GestureDragEndCallback onEnd;

  /// The pointer that previously triggered [onDown] did not complete.
  GestureDragCancelCallback onCancel;

  _DragState _state = _DragState.ready;
  Point _initialPosition;
  T _pendingDragDelta;

  T get _initialPendingDragDelta;
  T _getDragDelta(PointerEvent event);
  bool get _hasSufficientPendingDragDeltaToAccept;

  Map<int, VelocityTracker> _velocityTrackers = new Map<int, VelocityTracker>();

  @override
  void addPointer(PointerEvent event) {
    startTrackingPointer(event.pointer);
    _velocityTrackers[event.pointer] = new VelocityTracker();
    if (_state == _DragState.ready) {
      _state = _DragState.possible;
      _initialPosition = event.position;
      _pendingDragDelta = _initialPendingDragDelta;
      if (onDown != null)
        onDown(_initialPosition);
    }
  }

  @override
  void handleEvent(PointerEvent event) {
    assert(_state != _DragState.ready);
    if (event is PointerMoveEvent) {
      VelocityTracker tracker = _velocityTrackers[event.pointer];
      assert(tracker != null);
      tracker.addPosition(event.timeStamp, event.position);
      T delta = _getDragDelta(event);
      if (_state == _DragState.accepted) {
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

  @override
  void acceptGesture(int pointer) {
    if (_state != _DragState.accepted) {
      _state = _DragState.accepted;
      T delta = _pendingDragDelta;
      _pendingDragDelta = _initialPendingDragDelta;
      if (onStart != null)
        onStart(_initialPosition);
      if (delta != _initialPendingDragDelta && onUpdate != null)
        onUpdate(delta);
    }
  }

  @override
  void rejectGesture(int pointer) {
    ensureNotTrackingPointer(pointer);
  }

  @override
  void didStopTrackingLastPointer(int pointer) {
    if (_state == _DragState.possible) {
      resolve(GestureDisposition.rejected);
      _state = _DragState.ready;
      if (onCancel != null)
        onCancel();
      return;
    }
    bool wasAccepted = (_state == _DragState.accepted);
    _state = _DragState.ready;
    if (wasAccepted && onEnd != null) {
      VelocityTracker tracker = _velocityTrackers[pointer];
      assert(tracker != null);

      Velocity velocity = tracker.getVelocity();
      if (velocity != null && _isFlingGesture(velocity)) {
        final Offset pixelsPerSecond = velocity.pixelsPerSecond;
        if (pixelsPerSecond.distanceSquared > kMaxFlingVelocity * kMaxFlingVelocity)
          velocity = new Velocity(pixelsPerSecond: (pixelsPerSecond / pixelsPerSecond.distance) * kMaxFlingVelocity);
        onEnd(velocity);
      } else {
        onEnd(Velocity.zero);
      }
    }
    _velocityTrackers.clear();
  }

  @override
  void dispose() {
    _velocityTrackers.clear();
    super.dispose();
  }
}

/// Recognizes movement in the vertical direction.
///
/// Used for vertical scrolling.
///
/// See also:
///
///  * [VerticalMultiDragGestureRecognizer]
class VerticalDragGestureRecognizer extends DragGestureRecognizer<double> {
  @override
  double get _initialPendingDragDelta => 0.0;

  @override
  double _getDragDelta(PointerEvent event) => event.delta.dy;

  @override
  bool get _hasSufficientPendingDragDeltaToAccept => _pendingDragDelta.abs() > kTouchSlop;

  @override
  String toStringShort() => 'vertical drag';
}

/// Recognizes movement in the horizontal direction.
///
/// Used for horizontal scrolling.
///
/// See also:
///
///  * [HorizontalMultiDragGestureRecognizer]
class HorizontalDragGestureRecognizer extends DragGestureRecognizer<double> {
  @override
  double get _initialPendingDragDelta => 0.0;

  @override
  double _getDragDelta(PointerEvent event) => event.delta.dx;

  @override
  bool get _hasSufficientPendingDragDeltaToAccept => _pendingDragDelta.abs() > kTouchSlop;

  @override
  String toStringShort() => 'horizontal drag';
}

/// Recognizes movement both horizontally and vertically.
///
/// See also:
///
///  * [ImmediateMultiDragGestureRecognizer]
///  * [DelayedMultiDragGestureRecognizer]
class PanGestureRecognizer extends DragGestureRecognizer<Offset> {
  @override
  Offset get _initialPendingDragDelta => Offset.zero;

  @override
  Offset _getDragDelta(PointerEvent event) => event.delta;

  @override
  bool get _hasSufficientPendingDragDeltaToAccept {
    return _pendingDragDelta.distance > kPanSlop;
  }

  @override
  String toStringShort() => 'pan';
}
