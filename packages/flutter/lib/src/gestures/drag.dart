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

/// Details for [GestureDragDownCallback].
class DragDownDetails {
  /// Creates details for a [GestureDragDownCallback].
  ///
  /// The [globalPosition] argument must not be null.
  DragDownDetails({ this.globalPosition: Point.origin }) {
    assert(globalPosition != null);
  }

  /// The global position at which the pointer contacted the screen.
  final Point globalPosition;
}

/// Signature for when a pointer has contacted the screen and might begin to move.
///
/// See [DragGestureRecognizer.onDown].
typedef void GestureDragDownCallback(DragDownDetails details);

/// Details for [GestureDragStartCallback].
class DragStartDetails {
  /// Creates details for a [GestureDragStartCallback].
  ///
  /// The [globalPosition] argument must not be null.
  DragStartDetails({ this.globalPosition: Point.origin }) {
    assert(globalPosition != null);
  }

  /// The global position at which the pointer contacted the screen.
  final Point globalPosition;
}

/// Signature for when a pointer has contacted the screen and has begun to move.
///
/// See [DragGestureRecognizer.onStart].
typedef void GestureDragStartCallback(DragStartDetails details);

/// Details for [GestureDragUpdateCallback].
class DragUpdateDetails {
  /// Creates details for a [DragUpdateDetails].
  ///
  /// The [delta] argument must not be null.
  ///
  /// If [primaryDelta] is non-null, then its value must match one of the
  /// coordinates of [delta] and the other coordinate must be zero.
  DragUpdateDetails({
    this.delta: Offset.zero,
    this.primaryDelta,
    this.globalPosition
  }) {
    assert(primaryDelta == null
        || (primaryDelta == delta.dx && delta.dy == 0.0)
        || (primaryDelta == delta.dy && delta.dx == 0.0));
  }

  /// The amount the pointer has moved since the previous update.
  ///
  /// If the [GestureDragUpdateCallback] is for a one-dimensional drag (e.g.,
  /// a horizontal or vertical drag), then this offset contains only the delta
  /// in that direction (i.e., the coordinate in the other direction is zero).
  final Offset delta;

  /// The amount the pointer has moved along the primary axis since the previous
  /// update.
  ///
  /// If the [GestureDragUpdateCallback] is for a one-dimensional drag (e.g.,
  /// a horizontal or vertical drag), then this value contains the component of
  /// [delta] along the primary axis (e.g., horizontal or vertical,
  /// respectively). Otherwise, if the [GestureDragUpdateCallback] is for a
  /// two-dimensional drag (e.g., a pan), then this value is null.
  final double primaryDelta;

  /// The pointer's global position.
  final Point globalPosition;
}

/// Signature for when a pointer that is in contact with the screen and moving
/// has moved again.
///
/// See [DragGestureRecognizer.onUpdate].
typedef void GestureDragUpdateCallback(DragUpdateDetails details);

/// Details for [GestureDragEndCallback].
class DragEndDetails {
  /// Creates details for a [GestureDragEndCallback].
  ///
  /// The [velocity] argument must not be null.
  DragEndDetails({ this.velocity: Velocity.zero }) {
    assert(velocity != null);
  }

  /// The velocity the pointer was moving when it stopped contacting the screen.
  final Velocity velocity;
}

/// Signature for when a pointer that was previously in contact with the screen
/// and moving is no longer in contact with the screen.
///
/// The velocity at which the pointer was moving when it stopped contacting
/// the screen is available in the `details`.
///
/// See [DragGestureRecognizer.onEnd].
typedef void GestureDragEndCallback(DragEndDetails details);

/// Signature for when the pointer that previously triggered a
/// [GestureDragDownCallback] did not complete.
///
/// See [DragGestureRecognizer.onCancel].
typedef void GestureDragCancelCallback();

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
abstract class DragGestureRecognizer extends OneSequenceGestureRecognizer {
  /// A pointer has contacted the screen and might begin to move.
  GestureDragDownCallback onDown;

  /// A pointer has contacted the screen and has begun to move.
  GestureDragStartCallback onStart;

  /// A pointer that is in contact with the screen and moving has moved again.
  GestureDragUpdateCallback onUpdate;

  /// A pointer that was previously in contact with the screen and moving is no
  /// longer in contact with the screen and was moving at a specific velocity
  /// when it stopped contacting the screen.
  GestureDragEndCallback onEnd;

  /// The pointer that previously triggered [onDown] did not complete.
  GestureDragCancelCallback onCancel;

  _DragState _state = _DragState.ready;
  Point _initialPosition;
  Offset _pendingDragOffset;

  Offset _getDeltaForDetails(Offset delta);
  double _getPrimaryDeltaForDetails(Offset delta);
  bool get _hasSufficientPendingDragDeltaToAccept;

  Map<int, VelocityTracker> _velocityTrackers = new Map<int, VelocityTracker>();

  @override
  void addPointer(PointerEvent event) {
    startTrackingPointer(event.pointer);
    _velocityTrackers[event.pointer] = new VelocityTracker();
    if (_state == _DragState.ready) {
      _state = _DragState.possible;
      _initialPosition = event.position;
      _pendingDragOffset = Offset.zero;
      if (onDown != null)
        invokeCallback/*<Null>*/('onDown', () => onDown(new DragDownDetails(globalPosition: _initialPosition))); // ignore: STRONG_MODE_INVALID_CAST_FUNCTION_EXPR, https://github.com/dart-lang/sdk/issues/27504
    }
  }

  @override
  void handleEvent(PointerEvent event) {
    assert(_state != _DragState.ready);
    if (event is PointerMoveEvent) {
      VelocityTracker tracker = _velocityTrackers[event.pointer];
      assert(tracker != null);
      tracker.addPosition(event.timeStamp, event.position);
      Offset delta = event.delta;
      if (_state == _DragState.accepted) {
        if (onUpdate != null) {
          invokeCallback/*<Null>*/('onUpdate', () => onUpdate(new DragUpdateDetails( // ignore: STRONG_MODE_INVALID_CAST_FUNCTION_EXPR, https://github.com/dart-lang/sdk/issues/27504
            delta: _getDeltaForDetails(delta),
            primaryDelta: _getPrimaryDeltaForDetails(delta),
            globalPosition: event.position
          )));
        }
      } else {
        _pendingDragOffset += delta;
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
      Offset delta = _pendingDragOffset;
      _pendingDragOffset = Offset.zero;
      if (onStart != null)
        invokeCallback/*<Null>*/('onStart', () => onStart(new DragStartDetails(globalPosition: _initialPosition))); // ignore: STRONG_MODE_INVALID_CAST_FUNCTION_EXPR, https://github.com/dart-lang/sdk/issues/27504
      if (delta != Offset.zero && onUpdate != null) {
        invokeCallback/*<Null>*/('onUpdate', () => onUpdate(new DragUpdateDetails( // ignore: STRONG_MODE_INVALID_CAST_FUNCTION_EXPR, https://github.com/dart-lang/sdk/issues/27504
          delta: _getDeltaForDetails(delta),
          primaryDelta: _getPrimaryDeltaForDetails(delta)
        )));
      }
    }
  }

  @override
  void rejectGesture(int pointer) {
    stopTrackingPointer(pointer);
  }

  @override
  void didStopTrackingLastPointer(int pointer) {
    if (_state == _DragState.possible) {
      resolve(GestureDisposition.rejected);
      _state = _DragState.ready;
      if (onCancel != null)
        invokeCallback/*<Null>*/('onCancel', onCancel); // ignore: STRONG_MODE_INVALID_CAST_FUNCTION_EXPR, https://github.com/dart-lang/sdk/issues/27504
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
        invokeCallback/*<Null>*/('onEnd', () => onEnd(new DragEndDetails(velocity: velocity))); // ignore: STRONG_MODE_INVALID_CAST_FUNCTION_EXPR, https://github.com/dart-lang/sdk/issues/27504
      } else {
        invokeCallback/*<Null>*/('onEnd', () => onEnd(new DragEndDetails(velocity: Velocity.zero))); // ignore: STRONG_MODE_INVALID_CAST_FUNCTION_EXPR, https://github.com/dart-lang/sdk/issues/27504
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
class VerticalDragGestureRecognizer extends DragGestureRecognizer {
  @override
  bool get _hasSufficientPendingDragDeltaToAccept => _pendingDragOffset.dy.abs() > kTouchSlop;

  @override
  Offset _getDeltaForDetails(Offset delta) => new Offset(0.0, delta.dy);

  @override
  double _getPrimaryDeltaForDetails(Offset delta) => delta.dy;

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
class HorizontalDragGestureRecognizer extends DragGestureRecognizer {
  @override
  bool get _hasSufficientPendingDragDeltaToAccept => _pendingDragOffset.dx.abs() > kTouchSlop;

  @override
  Offset _getDeltaForDetails(Offset delta) => new Offset(delta.dx, 0.0);

  @override
  double _getPrimaryDeltaForDetails(Offset delta) => delta.dx;

  @override
  String toStringShort() => 'horizontal drag';
}

/// Recognizes movement both horizontally and vertically.
///
/// See also:
///
///  * [ImmediateMultiDragGestureRecognizer]
///  * [DelayedMultiDragGestureRecognizer]
class PanGestureRecognizer extends DragGestureRecognizer {
  @override
  bool get _hasSufficientPendingDragDeltaToAccept {
    return _pendingDragOffset.distance > kPanSlop;
  }

  @override
  Offset _getDeltaForDetails(Offset delta) => delta;

  @override
  double _getPrimaryDeltaForDetails(Offset delta) => null;

  @override
  String toStringShort() => 'pan';
}
