// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Base class for input events.
class InputEvent {

  const InputEvent({ this.type, this.timeStamp: 0.0 });

  final String type;
  // TODO: Should timeStamp be a DateTime object instead of double?
  // Some client code (e.g. drag.dart) does math on the time stamp.
  final double timeStamp;

}

/// Input event representing a touch or button.
class PointerInputEvent extends InputEvent {

  const PointerInputEvent({
    String type,
    double timeStamp: 0.0,
    this.pointer,
    this.kind,
    this.x,
    this.y,
    this.dx,
    this.dy,
    this.buttons,
    this.down,
    this.primary,
    this.obscured,
    this.pressure,
    this.pressureMin,
    this.pressureMax,
    this.distance,
    this.distanceMin,
    this.distanceMax,
    this.radiusMajor,
    this.radiusMinor,
    this.radiusMin,
    this.radiusMax,
    this.orientation,
    this.tilt
  }) : super(type: type, timeStamp: timeStamp);

  final int pointer;
  final String kind;
  final double x;
  final double y;
  final double dx;
  final double dy;
  final int buttons;
  final bool down;
  final bool primary;
  final bool obscured;
  final double pressure;
  final double pressureMin;
  final double pressureMax;
  final double distance;
  final double distanceMin;
  final double distanceMax;
  final double radiusMajor;
  final double radiusMinor;
  final double radiusMin;
  final double radiusMax;
  final double orientation;
  final double tilt;

}
