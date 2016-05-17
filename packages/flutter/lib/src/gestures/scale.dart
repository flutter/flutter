// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'arena.dart';
import 'recognizer.dart';
import 'constants.dart';
import 'events.dart';

/// The possible states of a [ScaleGestureRecognizer].
enum ScaleState {
  /// The recognizer is ready to start recognizing a gesture.
  ready,

  /// The sequence of pointer events seen thus far are consistent with a scale
  /// gesture but the gesture has not been accepted definitively.
  possible,

  /// The sequence of pointer events seen thus far have been accepted
  /// definitively as a scale gesture.
  accepted,

  /// The sequence of pointer events seen thus far have been accepted
  /// definitively as a scale gesture and the pointers established a focal point
  /// and initial scale.
  started,
}

/// Signature for when the pointers in contact with the screen have begun
/// established a focal point and initial scale of 1.0.
typedef void GestureScaleStartCallback(Point focalPoint);

/// Signature for when the pointers in contact with the screen have indicated a
/// new focal point and/or scale.
typedef void GestureScaleUpdateCallback(double scale, Point focalPoint);

/// Signature for when the pointers are no longer in contact with the screen.
typedef void GestureScaleEndCallback();

/// Recognizes a scale gesture.
///
/// [ScaleGestureRecognizer] tracks the pointers in contact with the screen and
/// calculates their focal point and indiciated scale. When a focal pointer is
/// established, the recognizer calls [onStart]. As the focal point and scale
/// change, the recognizer calls [onUpdate]. When the pointers are no longer in
/// contact with the screen, the recognizer calls [onEnd].
class ScaleGestureRecognizer extends OneSequenceGestureRecognizer {
  /// The pointers in contact with the screen have begun established a focal
  /// point and initial scale of 1.0.
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

  double get _scaleFactor => _initialSpan > 0.0 ? _currentSpan / _initialSpan : 1.0;

  @override
  void addPointer(PointerEvent event) {
    startTrackingPointer(event.pointer);
    if (_state == ScaleState.ready) {
      _state = ScaleState.possible;
      _initialSpan = 0.0;
      _currentSpan = 0.0;
      _pointerLocations = new Map<int, Point>();
    }
  }

  @override
  void handleEvent(PointerEvent event) {
    assert(_state != ScaleState.ready);
    bool configChanged = false;
    if (event is PointerMoveEvent) {
      _pointerLocations[event.pointer] = event.position;
    } else if (event is PointerDownEvent) {
      configChanged = true;
      _pointerLocations[event.pointer] = event.position;
    } else if (event is PointerUpEvent) {
      configChanged = true;
      _pointerLocations.remove(event.pointer);
    }

    _update(configChanged);

    stopTrackingIfPointerNoLongerDown(event);
  }

  void _update(bool configChanged) {
    int count = _pointerLocations.keys.length;

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
        if (onEnd != null)
          onEnd();
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
        onStart(focalPoint);
    }

    if (_state == ScaleState.started && onUpdate != null)
      onUpdate(_scaleFactor, focalPoint);
  }

  @override
  void acceptGesture(int pointer) {
    if (_state != ScaleState.accepted) {
      _state = ScaleState.accepted;
      _update(false);
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
  String toStringShort() => 'scale';
}
