// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;
import 'dart:sky' as sky;

import 'package:sky/gestures/arena.dart';
import 'package:sky/gestures/recognizer.dart';
import 'package:sky/gestures/constants.dart';

enum PinchState {
  ready,
  possible,
  started,
  ended
}

typedef void GesturePinchStartCallback();
typedef void GesturePinchUpdateCallback(double scale);
typedef void GesturePinchEndCallback();

class PinchGestureRecognizer extends GestureRecognizer {
  PinchGestureRecognizer({ PointerRouter router, this.onStart, this.onUpdate, this.onEnd })
    : super(router: router);

  GesturePinchStartCallback onStart;
  GesturePinchUpdateCallback onUpdate;
  GesturePinchEndCallback onEnd;

  PinchState _state = PinchState.ready;

  double _initialSpan;
  double _currentSpan;
  Map<int, sky.Point> _pointerLocations;

  double get _scaleFactor => _initialSpan > 0 ? _currentSpan / _initialSpan : 1.0;

  void addPointer(sky.PointerEvent event) {
    startTrackingPointer(event.pointer);
    if (_state == PinchState.ready) {
      _state = PinchState.possible;
      _initialSpan = 0.0;
      _currentSpan = 0.0;
      _pointerLocations = new Map<int, sky.Point>();
    }
  }

  void handleEvent(sky.PointerEvent event) {
    assert(_state != PinchState.ready);
    bool configChanged = false;
    switch(event.type) {
      case 'pointerup':
        configChanged = true;
        _pointerLocations.remove(event.pointer);
        break;
      case 'pointerdown':
        configChanged = true;
        _pointerLocations[event.pointer] = new sky.Point(event.x, event.y);
        break;
      case 'pointermove':
        _pointerLocations[event.pointer] = new sky.Point(event.x, event.y);
        break;
    }

    int count = _pointerLocations.keys.length;

    // Compute the focal point
    sky.Point focalPoint = sky.Point.origin;
    for (int pointer in _pointerLocations.keys)
      focalPoint += _pointerLocations[pointer].toOffset();
    focalPoint = new sky.Point(focalPoint.x / count, focalPoint.y / count);

    // Span is the average deviation from focal point
    double totalDeviation = 0.0;
    for (int pointer in _pointerLocations.keys)
      totalDeviation += (focalPoint - _pointerLocations[pointer]).distance;
    _currentSpan = count > 0 ? totalDeviation / count : 0.0;

    if (configChanged) {
      _initialSpan = _currentSpan;
      if (_state == PinchState.started) {
        _state = PinchState.ended;
        if (onEnd != null)
          onEnd();
      }
    }

    if (_state == PinchState.ready)
      _state = PinchState.possible;

    if (_state == PinchState.possible &&
        (_currentSpan - _initialSpan).abs() > kPinchSlop) {
      resolve(GestureDisposition.accepted);
    }

    if (_state == PinchState.ended && _currentSpan != _initialSpan) {
      _state = PinchState.started;
      if (onStart != null)
        onStart();
    }

    if (_state == PinchState.started && onUpdate != null)
      onUpdate(_scaleFactor);

    stopTrackingIfPointerNoLongerDown(event);
  }

  void acceptGesture(int pointer) {
    if (_state != PinchState.started) {
      _state = PinchState.started;
      if (onStart != null)
        onStart();
      if (onUpdate != null)
        onUpdate(_scaleFactor);
    }
  }

  void didStopTrackingLastPointer(int pointer) {
    switch(_state) {
      case PinchState.possible:
        resolve(GestureDisposition.rejected);
        break;
      case PinchState.ready:
        assert(false);
        break;
      case PinchState.started:
        assert(false);
        break;
      case PinchState.ended:
        break;
    }
    _state = PinchState.ready;
  }

  void dispose() {
    super.dispose();
  }
}
