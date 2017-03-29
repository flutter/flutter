// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'arena.dart';
import 'constants.dart';
import 'events.dart';
import 'recognizer.dart';
import 'velocity_tracker.dart';

/// The possible states of a [ScaleGestureRecognizer].
enum ScaleState {
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
  ScaleStartDetails({ this.focalPoint: Point.origin }) {
    assert(focalPoint != null);
  }

  /// The initial focal point of the pointers in contact with the screen.
  /// Reported in global coordinates.
  final Point focalPoint;
}

/// Details for [GestureScaleUpdateCallback].
class ScaleUpdateDetails {
  /// Creates details for [GestureScaleUpdateCallback].
  ///
  /// The [focalPoint] and [scale] arguments must not be null. The [scale]
  /// argument must be greater than or equal to zero.
  ScaleUpdateDetails({ this.focalPoint: Point.origin, this.scale: 1.0 }) {
    assert(focalPoint != null);
    assert(scale != null && scale >= 0.0);
  }

  /// The focal point of the pointers in contact with the screen. Reported in
  /// global coordinates.
  final Point focalPoint;

  /// The scale implied by the pointers in contact with the screen. A value
  /// greater than or equal to zero.
  final double scale;
}

/// Details for [GestureScaleEndCallback].
class ScaleEndDetails {
  /// Creates details for [GestureScaleEndCallback].
  ///
  /// The [velocity] argument must not be null.
  ScaleEndDetails({ this.velocity: Velocity.zero }) {
    assert(velocity != null);
  }

  /// The velocity of the last pointer to be lifted off of the screen.
  final Velocity velocity;
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

  ScaleState _state = ScaleState.ready;

  double _initialSpan;
  double _currentSpan;
  Map<int, Point> _pointerLocations;
  final Map<int, VelocityTracker> _velocityTrackers = <int, VelocityTracker>{};

  double get _scaleFactor => _initialSpan > 0.0 ? _currentSpan / _initialSpan : 1.0;

  @override
  void addPointer(PointerEvent event) {
    startTrackingPointer(event.pointer);
    _velocityTrackers[event.pointer] = new VelocityTracker();
    if (_state == ScaleState.ready) {
      _state = ScaleState.possible;
      _initialSpan = 0.0;
      _currentSpan = 0.0;
      _pointerLocations = <int, Point>{};
    }
  }

  @override
  void handleEvent(PointerEvent event) {
    assert(_state != ScaleState.ready);
    bool configChanged = false;
    if (event is PointerMoveEvent) {
      final VelocityTracker tracker = _velocityTrackers[event.pointer];
      assert(tracker != null);
      tracker.addPosition(event.timeStamp, event.position);
      _pointerLocations[event.pointer] = event.position;
    } else if (event is PointerDownEvent) {
      configChanged = true;
      _pointerLocations[event.pointer] = event.position;
    } else if (event is PointerUpEvent) {
      configChanged = true;
      _pointerLocations.remove(event.pointer);
    }

    _update(configChanged, event.pointer);

    stopTrackingIfPointerNoLongerDown(event);
  }

  void _update(bool configChanged, int pointer) {
    final int count = _pointerLocations.keys.length;

    // Compute the focal point
    Point focalPoint = Point.origin;
    for (int pointer in _pointerLocations.keys)
      focalPoint += _pointerLocations[pointer].toOffset();
    focalPoint = new Point(focalPoint.x / count, focalPoint.y / count);

    // Span is the average deviation from focal point
    double totalDeviation = 0.0;
    for (int pointer in _pointerLocations.keys)
      totalDeviation += (focalPoint - _pointerLocations[pointer]).distance;
    _currentSpan = count > 0 ? totalDeviation / count : 0.0;

    if (configChanged) {
      _initialSpan = _currentSpan;
      if (_state == ScaleState.started) {
        if (onEnd != null) {
          final VelocityTracker tracker = _velocityTrackers[pointer];
          assert(tracker != null);

          Velocity velocity = tracker.getVelocity();
          if (velocity != null && _isFlingGesture(velocity)) {
            final Offset pixelsPerSecond = velocity.pixelsPerSecond;
            if (pixelsPerSecond.distanceSquared > kMaxFlingVelocity * kMaxFlingVelocity)
              velocity = new Velocity(pixelsPerSecond: (pixelsPerSecond / pixelsPerSecond.distance) * kMaxFlingVelocity);
            invokeCallback<Null>('onEnd', () => onEnd(new ScaleEndDetails(velocity: velocity))); // ignore: STRONG_MODE_INVALID_CAST_FUNCTION_EXPR, https://github.com/dart-lang/sdk/issues/27504
          } else {
            invokeCallback<Null>('onEnd', () => onEnd(new ScaleEndDetails(velocity: Velocity.zero))); // ignore: STRONG_MODE_INVALID_CAST_FUNCTION_EXPR, https://github.com/dart-lang/sdk/issues/27504
          }
        }
        _state = ScaleState.accepted;
      }
    }

    if (_state == ScaleState.ready)
      _state = ScaleState.possible;

    if (_state == ScaleState.possible &&
        (_currentSpan - _initialSpan).abs() > kScaleSlop) {
      resolve(GestureDisposition.accepted);
    }

    if (_state == ScaleState.accepted && !configChanged) {
      _state = ScaleState.started;
      if (onStart != null)
        invokeCallback<Null>('onStart', () => onStart(new ScaleStartDetails(focalPoint: focalPoint))); // ignore: STRONG_MODE_INVALID_CAST_FUNCTION_EXPR, https://github.com/dart-lang/sdk/issues/27504
    }

    if (_state == ScaleState.started && onUpdate != null)
      invokeCallback<Null>('onUpdate', () => onUpdate(new ScaleUpdateDetails(scale: _scaleFactor, focalPoint: focalPoint))); // ignore: STRONG_MODE_INVALID_CAST_FUNCTION_EXPR, https://github.com/dart-lang/sdk/issues/27504
  }

  @override
  void acceptGesture(int pointer) {
    if (_state != ScaleState.accepted) {
      _state = ScaleState.accepted;
      _update(false, pointer);
    }
  }

  @override
  void didStopTrackingLastPointer(int pointer) {
    switch(_state) {
      case ScaleState.possible:
        resolve(GestureDisposition.rejected);
        break;
      case ScaleState.ready:
        assert(false);  // We should have not seen a pointer yet
        break;
      case ScaleState.accepted:
        break;
      case ScaleState.started:
        assert(false);  // We should be in the accepted state when user is done
        break;
    }
    _state = ScaleState.ready;
  }

  @override
  void dispose() {
    _velocityTrackers.clear();
    super.dispose();
  }

  @override
  String toStringShort() => 'scale';
}
