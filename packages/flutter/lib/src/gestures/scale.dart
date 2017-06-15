// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'arena.dart';
import 'constants.dart';
import 'events.dart';
import 'recognizer.dart';
import 'velocity_tracker.dart';

/// The possible states of a [ScaleGestureRecognizer].
enum _ScaleState {
  /// The recognizer is ready to start recognizing a gesture.
  ready,

  /// The sequence of pointer events seen thus far is consistent with a scale
  /// gesture but the gesture has not been accepted definitively.
  possible,

  /// The sequence of pointer events seen thus far has been accepted
  /// definitively as a scale gesture.
  accepted,

  /// The sequence of pointer events seen thus far has been accepted
  /// definitively as a scale gesture and the pointers established a focal point
  /// and initial scale.
  started,
}

/// Details for [GestureScaleStartCallback].
class ScaleStartDetails {
  /// Creates details for [GestureScaleStartCallback].
  ///
  /// The [focalPoint] argument must not be null.
  ScaleStartDetails({ this.focalPoint: Offset.zero })
    : assert(focalPoint != null);

  /// The initial focal point of the pointers in contact with the screen.
  /// Reported in global coordinates.
  final Offset focalPoint;

  @override
  String toString() => 'ScaleStartDetails(focalPoint: $focalPoint)';
}

/// Details for [GestureScaleUpdateCallback].
class ScaleUpdateDetails {
  /// Creates details for [GestureScaleUpdateCallback].
  ///
  /// The [focalPoint] and [scale] arguments must not be null. The [scale]
  /// argument must be greater than or equal to zero.
  ScaleUpdateDetails({
    this.focalPoint: Offset.zero,
    this.scale: 1.0,
  }) : assert(focalPoint != null),
       assert(scale != null && scale >= 0.0);

  /// The focal point of the pointers in contact with the screen. Reported in
  /// global coordinates.
  final Offset focalPoint;

  /// The scale implied by the pointers in contact with the screen. A value
  /// greater than or equal to zero.
  final double scale;

  @override
  String toString() => 'ScaleUpdateDetails(focalPoint: $focalPoint, scale: $scale)';
}

/// Details for [GestureScaleEndCallback].
class ScaleEndDetails {
  /// Creates details for [GestureScaleEndCallback].
  ///
  /// The [velocity] argument must not be null.
  ScaleEndDetails({ this.velocity: Velocity.zero })
    : assert(velocity != null);

  /// The velocity of the last pointer to be lifted off of the screen.
  final Velocity velocity;

  @override
  String toString() => 'ScaleEndDetails(velocity: $velocity)';
}

/// Signature for when the pointers in contact with the screen have established
/// a focal point and initial scale of 1.0.
typedef void GestureScaleStartCallback(ScaleStartDetails details);

/// Signature for when the pointers in contact with the screen have indicated a
/// new focal point and/or scale.
typedef void GestureScaleUpdateCallback(ScaleUpdateDetails details);

/// Signature for when the pointers are no longer in contact with the screen.
typedef void GestureScaleEndCallback(ScaleEndDetails details);

bool _isFlingGesture(Velocity velocity) {
  assert(velocity != null);
  final double speedSquared = velocity.pixelsPerSecond.distanceSquared;
  return speedSquared > kMinFlingVelocity * kMinFlingVelocity;
}

/// Recognizes a scale gesture.
///
/// [ScaleGestureRecognizer] tracks the pointers in contact with the screen and
/// calculates their focal point and indiciated scale. When a focal pointer is
/// established, the recognizer calls [onStart]. As the focal point and scale
/// change, the recognizer calls [onUpdate]. When the pointers are no longer in
/// contact with the screen, the recognizer calls [onEnd].
class ScaleGestureRecognizer extends OneSequenceGestureRecognizer {
  /// The pointers in contact with the screen have established a focal point and
  /// initial scale of 1.0.
  GestureScaleStartCallback onStart;

  /// The pointers in contact with the screen have indicated a new focal point
  /// and/or scale.
  GestureScaleUpdateCallback onUpdate;

  /// The pointers are no longer in contact with the screen.
  GestureScaleEndCallback onEnd;

  _ScaleState _state = _ScaleState.ready;

  Offset _initialFocalPoint;
  Offset _currentFocalPoint;
  double _initialSpan;
  double _currentSpan;
  Map<int, Offset> _pointerLocations;
  final Map<int, VelocityTracker> _velocityTrackers = <int, VelocityTracker>{};

  double get _scaleFactor => _initialSpan > 0.0 ? _currentSpan / _initialSpan : 1.0;

  @override
  void addPointer(PointerEvent event) {
    startTrackingPointer(event.pointer);
    _velocityTrackers[event.pointer] = new VelocityTracker();
    if (_state == _ScaleState.ready) {
      _state = _ScaleState.possible;
      _initialSpan = 0.0;
      _currentSpan = 0.0;
      _pointerLocations = <int, Offset>{};
    }
  }

  @override
  void handleEvent(PointerEvent event) {
    assert(_state != _ScaleState.ready);
    bool didChangeConfiguration = false;
    bool shouldStartIfAccepted = false;
    if (event is PointerMoveEvent) {
      final VelocityTracker tracker = _velocityTrackers[event.pointer];
      assert(tracker != null);
      tracker.addPosition(event.timeStamp, event.position);
      _pointerLocations[event.pointer] = event.position;
      shouldStartIfAccepted = true;
    } else if (event is PointerDownEvent) {
      _pointerLocations[event.pointer] = event.position;
      didChangeConfiguration = true;
      shouldStartIfAccepted = true;
    } else if (event is PointerUpEvent || event is PointerCancelEvent) {
      _pointerLocations.remove(event.pointer);
      didChangeConfiguration = true;
    }

    _update();
    if (!didChangeConfiguration || _reconfigure(event.pointer))
      _advanceStateMachine(shouldStartIfAccepted);
    stopTrackingIfPointerNoLongerDown(event);
  }

  void _update() {
    final int count = _pointerLocations.keys.length;

    // Compute the focal point
    Offset focalPoint = Offset.zero;
    for (int pointer in _pointerLocations.keys)
      focalPoint += _pointerLocations[pointer];
    _currentFocalPoint = count > 0 ? focalPoint / count.toDouble() : Offset.zero;

    // Span is the average deviation from focal point
    double totalDeviation = 0.0;
    for (int pointer in _pointerLocations.keys)
      totalDeviation += (_currentFocalPoint - _pointerLocations[pointer]).distance;
    _currentSpan = count > 0 ? totalDeviation / count : 0.0;
  }

  bool _reconfigure(int pointer) {
    _initialFocalPoint = _currentFocalPoint;
    _initialSpan = _currentSpan;
    if (_state == _ScaleState.started) {
      if (onEnd != null) {
        final VelocityTracker tracker = _velocityTrackers[pointer];
        assert(tracker != null);

        Velocity velocity = tracker.getVelocity();
        if (_isFlingGesture(velocity)) {
          final Offset pixelsPerSecond = velocity.pixelsPerSecond;
          if (pixelsPerSecond.distanceSquared > kMaxFlingVelocity * kMaxFlingVelocity)
            velocity = new Velocity(pixelsPerSecond: (pixelsPerSecond / pixelsPerSecond.distance) * kMaxFlingVelocity);
          invokeCallback<Null>('onEnd', () => onEnd(new ScaleEndDetails(velocity: velocity))); // ignore: STRONG_MODE_INVALID_CAST_FUNCTION_EXPR, https://github.com/dart-lang/sdk/issues/27504
        } else {
          invokeCallback<Null>('onEnd', () => onEnd(new ScaleEndDetails(velocity: Velocity.zero))); // ignore: STRONG_MODE_INVALID_CAST_FUNCTION_EXPR, https://github.com/dart-lang/sdk/issues/27504
        }
      }
      _state = _ScaleState.accepted;
      return false;
    }
    return true;
  }

  void _advanceStateMachine(bool shouldStartIfAccepted) {
    if (_state == _ScaleState.ready)
      _state = _ScaleState.possible;

    if (_state == _ScaleState.possible) {
      final double spanDelta = (_currentSpan - _initialSpan).abs();
      final double focalPointDelta = (_currentFocalPoint - _initialFocalPoint).distance;
      if (spanDelta > kScaleSlop || focalPointDelta > kPanSlop)
        resolve(GestureDisposition.accepted);
    } else if (_state.index >= _ScaleState.accepted.index) {
      resolve(GestureDisposition.accepted);
    }

    if (_state == _ScaleState.accepted && shouldStartIfAccepted) {
      _state = _ScaleState.started;
      _dispatchOnStartCallbackIfNeeded();
    }

    if (_state == _ScaleState.started && onUpdate != null)
      invokeCallback<Null>('onUpdate', () => onUpdate(new ScaleUpdateDetails(scale: _scaleFactor, focalPoint: _currentFocalPoint))); // ignore: STRONG_MODE_INVALID_CAST_FUNCTION_EXPR, https://github.com/dart-lang/sdk/issues/27504
  }

  void _dispatchOnStartCallbackIfNeeded() {
    assert(_state == _ScaleState.started);
    if (onStart != null)
      invokeCallback<Null>('onStart', () => onStart(new ScaleStartDetails(focalPoint: _currentFocalPoint))); // ignore: STRONG_MODE_INVALID_CAST_FUNCTION_EXPR, https://github.com/dart-lang/sdk/issues/27504
  }

  @override
  void acceptGesture(int pointer) {
    if (_state == _ScaleState.possible) {
      _state = _ScaleState.started;
      _dispatchOnStartCallbackIfNeeded();
    }
  }

  @override
  void rejectGesture(int pointer) {
    stopTrackingPointer(pointer);
  }

  @override
  void didStopTrackingLastPointer(int pointer) {
    switch(_state) {
      case _ScaleState.possible:
        resolve(GestureDisposition.rejected);
        break;
      case _ScaleState.ready:
        assert(false);  // We should have not seen a pointer yet
        break;
      case _ScaleState.accepted:
        break;
      case _ScaleState.started:
        assert(false);  // We should be in the accepted state when user is done
        break;
    }
    _state = _ScaleState.ready;
  }

  @override
  void dispose() {
    _velocityTrackers.clear();
    super.dispose();
  }

  @override
  String toStringShort() => 'scale';
}
