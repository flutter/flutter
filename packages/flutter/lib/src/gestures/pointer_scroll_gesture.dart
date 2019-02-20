// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'arena.dart';
import 'constants.dart';
import 'events.dart';
import 'pointer_scroll_details.dart';
import 'recognizer.dart';
import 'velocity_tracker.dart';

/// Signature for when a pointer scroll completes.
///
/// The velocity of the scroll at the time it ended is available in the
/// `details`.
///
/// See [PointerScrollGestureRecognizer.onEnd].
typedef void PointerScrollEndCallback(PointerScrollEndDetails details);

/// Signature for when the pointer that previously triggered a
/// [PointerScrollStartCallback] did not complete.
///
/// See [PointerScrollGestureRecognizer.onCancel].
typedef void PointerScrollCancelCallback();

// A wrapper for VelocityTracker that accepts deltas rather than absolute
// positions.
class _DeltaVelocityTracker {
  Offset _cumulativeDelta = Offset.zero;
  final VelocityTracker _velocityTracker = new VelocityTracker();

  _DeltaVelocityTracker(Duration initialTime) {
    addDelta(initialTime, Offset.zero);
  }

  void addDelta(Duration time, Offset delta) {
    _cumulativeDelta += delta;
    _velocityTracker.addPosition(time, _cumulativeDelta);
  }

  VelocityEstimate getVelocityEstimate() {
    return _velocityTracker.getVelocityEstimate();
  }
}

/// Recognizes pointer scrolls.
///
/// [PointerScrollGestureRecognizer] is not intended to be used directly.
/// Instead, consider using one of its subclasses to recognize specific types
/// for scroll gestures.
///
/// See also:
///
///  * [HorizontalPointerScrollGestureRecognizer], for scrolling left and right.
///  * [VerticalPointerScrollGestureRecognizer], for scrolling up and down.
///  * [PanPointerScrollRecognizer], for scrolls that are not locked to a single
///    axis.
abstract class PointerScrollGestureRecognizer
    extends OneSequenceGestureRecognizer {
  /// Initialize the object.
  PointerScrollGestureRecognizer({Object debugOwner})
      : super(debugOwner: debugOwner);

  /// A pointer scroll gesture has begun.
  ///
  /// The position of the pointer is provided in the callback's `details`
  /// argument, which is a [PointerScrollStartDetails] object.
  PointerScrollStartCallback onStart;

  /// A pointer scroll gesture has continued scrolling.
  ///
  /// The delta of the scroll since the last update is provided in the
  /// callback's `details` argument, which is a [PointerScrollUpdateDetails]
  /// object.
  PointerScrollUpdateCallback onUpdate;

  /// A pointer scroll gesture has ended.
  ///
  /// The velocity of the scroll at the time it ended is provided in the
  /// callback's `details` argument, which is a [PointerScrollEndDetails]
  /// object.
  PointerScrollEndCallback onEnd;

  /// The pointer that previously triggered [onStart] did not complete.
  PointerScrollCancelCallback onCancel;

  /// The minimum distance an pointer scroll must have scrolled to
  /// to be considered a fling gesture.
  ///
  /// This value is typically compared with the distance traveled along the
  /// scrolling axis. If null then [kTouchSlop] is used.
  double minFlingDistance;

  /// The minimum velocity for an input pointer scroll to be considered fling.
  ///
  /// This value is typically compared with the magnitude of fling gesture's
  /// velocity along the scrolling axis. If null then [kMinFlingVelocity]
  /// is used.
  double minFlingVelocity;

  /// Fling velocity magnitudes will be clamped to this value.
  ///
  /// If null then [kMaxFlingVelocity] is used.
  double maxFlingVelocity;

  bool _hasAccepted = false;

  Offset _initialEventPosition;
  Duration _initialEventTimestamp;

  _DeltaVelocityTracker _velocityTracker;

  bool _isFlingGesture(VelocityEstimate estimate);
  Offset _getDeltaForDetails(Offset delta);
  double _getPrimaryValueFromOffset(Offset value);

  @override
  bool get acceptsPointerSignals => true;

  @override
  void addPointer(PointerEvent event) {
    if (!(event is PointerScrollEvent))
      return;
    assert((event as PointerScrollEvent).gestureChange != null);

    startTrackingPointer(event.pointer);

    _initialEventPosition = event.position;
    _initialEventTimestamp = event.timeStamp;

    resolve(GestureDisposition.accepted);
  }

  @override
  void handleEvent(PointerEvent event) {
    if (!(event is PointerScrollEvent))
      return;
    final PointerScrollEvent pointerScrollEvent = event;
    assert(pointerScrollEvent.gestureChange != null);

    if (pointerScrollEvent.gestureChange == PointerChange.move) {
      assert(_hasAccepted);
      final Offset delta = pointerScrollEvent.scrollDelta;

      if (!pointerScrollEvent.synthesized) {
        assert(_velocityTracker != null);
        _velocityTracker.addDelta(pointerScrollEvent.timeStamp, delta);
      }

      if (onUpdate != null) {
        invokeCallback<void>(
            'onUpdate',
            () => onUpdate(new PointerScrollUpdateDetails(
                  sourceTimeStamp: pointerScrollEvent.timeStamp,
                  delta: _getDeltaForDetails(delta),
                  primaryDelta: _getPrimaryValueFromOffset(delta),
                  globalPosition: pointerScrollEvent.position,
                )));
      }
    }

    stopTrackingIfPointerNoLongerDown(event);
  }

  @override
  void acceptGesture(int pointer) {
    assert(!_hasAccepted);
    _hasAccepted = true;
    _velocityTracker = new _DeltaVelocityTracker(_initialEventTimestamp);

    if (onStart != null) {
      invokeCallback<void>(
          'onStart',
          () => onStart(new PointerScrollStartDetails(
                sourceTimeStamp: _initialEventTimestamp,
                globalPosition: _initialEventPosition,
              )));
    }
  }

  @override
  void rejectGesture(int pointer) {
    stopTrackingPointer(pointer);
  }

  @override
  void didStopTrackingLastPointer(int pointer) {
    if (!_hasAccepted) {
      resolve(GestureDisposition.rejected);
      if (onCancel != null) invokeCallback<void>('onCancel', onCancel);
      return;
    }
    _hasAccepted = false;
    if (onEnd != null) {
      assert(_velocityTracker != null);

      final VelocityEstimate estimate = _velocityTracker.getVelocityEstimate();
      if (estimate != null && _isFlingGesture(estimate)) {
        final Velocity velocity =
            new Velocity(pixelsPerSecond: estimate.pixelsPerSecond)
                .clampMagnitude(minFlingVelocity ?? kMinFlingVelocity,
                    maxFlingVelocity ?? kMaxFlingVelocity);
        invokeCallback<void>(
            'onEnd',
            () => onEnd(new PointerScrollEndDetails(
                  velocity: velocity,
                  primaryVelocity:
                      _getPrimaryValueFromOffset(velocity.pixelsPerSecond),
                )), debugReport: () {
          return '$estimate; fling at $velocity.';
        });
      } else {
        invokeCallback<void>(
            'onEnd',
            () => onEnd(new PointerScrollEndDetails(
                  velocity: Velocity.zero,
                  primaryVelocity: 0.0,
                )), debugReport: () {
          if (estimate == null) return 'Could not estimate velocity.';
          return '$estimate; judged to not be a fling.';
        });
      }
    }
    _velocityTracker = null;
  }

  @override
  void dispose() {
    _velocityTracker = null;
    super.dispose();
  }
}

/// Recognizes pointer scrolling in the vertical direction.
///
/// See also:
///
///  * [HorizontalPointerScrollGestureRecognizer], for a similar recognizer but for
///    horizontal movement.
///  * [PanPointerScrollGestureRecognizer], for a gesture recognizers that
///    handles scrolls on both axes.
class VerticalPointerScrollGestureRecognizer
    extends PointerScrollGestureRecognizer {
  /// Create a gesture recognizer for interactions in the vertical axis.
  VerticalPointerScrollGestureRecognizer({Object debugOwner})
      : super(debugOwner: debugOwner);

  @override
  bool _isFlingGesture(VelocityEstimate estimate) {
    final double minVelocity = minFlingVelocity ?? kMinFlingVelocity;
    final double minDistance = minFlingDistance ?? kTouchSlop;
    return estimate.pixelsPerSecond.dy.abs() > minVelocity &&
        estimate.offset.dy.abs() > minDistance;
  }

  @override
  Offset _getDeltaForDetails(Offset delta) => new Offset(0.0, delta.dy);

  @override
  double _getPrimaryValueFromOffset(Offset value) => value.dy;

  @override
  String get debugDescription => 'vertical scroll';
}

/// Recognizes pointer scrolling in the horizontal direction.
///
/// See also:
///
///  * [VerticalPointerScrollGestureRecognizer], for a similar recognizer but for
///    vertical movement.
///  * [PanPointerScrollGestureRecognizer], for a gesture recognizers that
///    handles scrolls on both axes.
class HorizontalPointerScrollGestureRecognizer
    extends PointerScrollGestureRecognizer {
  /// Create a gesture recognizer for interactions in the horizontal axis.
  HorizontalPointerScrollGestureRecognizer({Object debugOwner})
      : super(debugOwner: debugOwner);

  @override
  bool _isFlingGesture(VelocityEstimate estimate) {
    final double minVelocity = minFlingVelocity ?? kMinFlingVelocity;
    final double minDistance = minFlingDistance ?? kTouchSlop;
    return estimate.pixelsPerSecond.dx.abs() > minVelocity &&
        estimate.offset.dx.abs() > minDistance;
  }

  @override
  Offset _getDeltaForDetails(Offset delta) => new Offset(delta.dx, 0.0);

  @override
  double _getPrimaryValueFromOffset(Offset value) => value.dx;

  @override
  String get debugDescription => 'horizontal scroll';
}

/// Recognizes pointer scrolling both horizontally and vertically.
class PanPointerScrollGestureRecognizer extends PointerScrollGestureRecognizer {
  /// Create a gesture recognizer for tracking movement on a plane.
  PanPointerScrollGestureRecognizer({Object debugOwner})
      : super(debugOwner: debugOwner);

  @override
  bool _isFlingGesture(VelocityEstimate estimate) {
    final double minVelocity = minFlingVelocity ?? kMinFlingVelocity;
    final double minDistance = minFlingDistance ?? kTouchSlop;
    return estimate.pixelsPerSecond.distanceSquared >
            minVelocity * minVelocity &&
        estimate.offset.distanceSquared > minDistance * minDistance;
  }

  @override
  Offset _getDeltaForDetails(Offset delta) => delta;

  @override
  double _getPrimaryValueFromOffset(Offset value) => null;

  @override
  String get debugDescription => 'pan scroll';
}
