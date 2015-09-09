// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:sky' as sky;

import 'package:sky/gestures/arena.dart';
import 'package:sky/gestures/recognizer.dart';
import 'package:sky/gestures/constants.dart';

// Fling velocities are logical pixels per second.
typedef void GestureFlingCallback(sky.Offset velocity);

int _eventTime(sky.PointerEvent event) => (event.timeStamp * 1000.0).toInt(); // microseconds

bool _isFlingGesture(sky.GestureVelocity velocity) {
  double velocitySquared = velocity.x * velocity.x + velocity.y * velocity.y;
  return velocity.isValid &&
    velocitySquared > kMinFlingVelocity * kMinFlingVelocity &&
    velocitySquared < kMaxFlingVelocity * kMaxFlingVelocity;
}

class FlingGestureRecognizer extends GestureRecognizer {
  FlingGestureRecognizer({ PointerRouter router, this.onFling })
    : super(router: router);

  GestureFlingCallback onFling;
  sky.VelocityTracker _velocityTracker = new sky.VelocityTracker();
  int _primaryPointer;

  void addPointer(sky.PointerEvent event) {
    startTrackingPointer(event.pointer);
    if (_primaryPointer == null)
      _primaryPointer = event.pointer;
  }

  void handleEvent(sky.PointerEvent event) {
    if (event.pointer == _primaryPointer) {
      if (event.type == 'pointermove') {
        _velocityTracker.addPosition(_eventTime(event), _primaryPointer, event.x, event.y);
      } else if (event.type == 'pointerup') {
        sky.GestureVelocity velocity = _velocityTracker.getVelocity(_primaryPointer);
        if (_isFlingGesture(velocity)) {
          resolve(GestureDisposition.accepted);
          if (onFling != null)
            onFling(new sky.Offset(velocity.x, velocity.y));
        }
      }
    }
    stopTrackingIfPointerNoLongerDown(event);
  }

  void didStopTrackingLastPointer() {
    _primaryPointer = null;
    _velocityTracker.reset();
  }

  void dispose() {
    super.dispose();
    _velocityTracker.reset();
    _primaryPointer = null;
  }
}
