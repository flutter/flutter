// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show Point, Offset;

export 'dart:ui' show Point, Offset;

enum PointerDeviceKind { touch, stylus, invertedStylus, mouse }

const int primaryMouseButton = 0x01;
const int secondaryMouseButton = 0x02;
const int primaryStylusButton = 0x02;
const int middleMouseButton = 0x04;
const int secondaryStylusButton = 0x04;
const int backMouseButton = 0x08;
const int forwardMouseButton = 0x10;
int nthMouseButton(int number) => primaryMouseButton << (number - 1);
int nthStylusButton(int number) => primaryStylusButton << (number - 1);

/// Base class for touch, stylus, or mouse events.
abstract class PointerEvent {
  const PointerEvent({
    this.timeStamp: Duration.ZERO,
    this.pointer: 0,
    this.kind: PointerDeviceKind.touch,
    this.position: Point.origin,
    this.delta: Offset.zero,
    this.buttons: 0,
    this.down: false,
    this.obscured: false,
    this.pressure: 1.0,
    this.pressureMin: 1.0,
    this.pressureMax: 1.0,
    this.distance: 0.0,
    this.distanceMax: 0.0,
    this.radiusMajor: 0.0,
    this.radiusMinor: 0.0,
    this.radiusMin: 0.0,
    this.radiusMax: 0.0,
    this.orientation: 0.0,
    this.tilt: 0.0
  });

  /// Time of event dispatch, relative to an arbitrary timeline.
  final Duration timeStamp;

  /// Unique identifier for the pointer, not reused.
  final int pointer;

  /// The kind of input device for which the event was generated.
  final PointerDeviceKind kind;

  /// Coordinate of the position of the pointer, in logical pixels in the global
  /// coordinate space.
  final Point position;

  /// Distance in logical pixels that the pointer moved since the last
  /// PointerMoveEvent. Always 0.0 for down, up, and cancel events.
  final Offset delta;

  /// Bit field using the *Button constants (primaryMouseButton,
  /// secondaryStylusButton, etc). For example, if this has the value 6 and the
  /// [kind] is [PointerDeviceKind.invertedStylus], then this indicates an
  /// upside-down stylus with both its primary and secondary buttons pressed.
  final int buttons;

  // Set if the pointer is currently down. For touch and stylus pointers, this
  // means the object (finger, pen) is in contact with the input surface. For
  // mice, it means a button is pressed.
  final bool down;

  // Set if an application from a different security domain is in any way
  // obscuring this application's window. (Aspirational; not currently
  // implemented.)
  final bool obscured;

  /// The pressure of the touch as a number ranging from 0.0, indicating a touch
  /// with no discernible pressure, to 1.0, indicating a touch with "normal"
  /// pressure, and possibly beyond, indicating a stronger touch. For devices
  /// that do not detect pressure (e.g. mice), returns 1.0.
  final double pressure;

  /// The minimum value that [pressure] can return for this pointer. For devices
  /// that do not detect pressure (e.g. mice), returns 1.0. This will always be
  /// a number less than or equal to 1.0.
  final double pressureMin;

  /// The maximum value that [pressure] can return for this pointer. For devices
  /// that do not detect pressure (e.g. mice), returns 1.0. This will always be
  /// a greater than or equal to 1.0.
  final double pressureMax;

  /// The distance of the detected object from the input surface (e.g. the
  /// distance of a stylus or finger from a touch screen), in arbitrary units on
  /// an arbitrary (not necessarily linear) scale. If the pointer is down, this
  /// is 0.0 by definition.
  final double distance;

  /// The minimum value that a distance can return for this pointer (always 0.0).
  final double distanceMin = 0.0;

  /// The maximum value that a distance can return for this pointer. If this
  /// input device cannot detect "hover touch" input events, then this will be
  /// 0.0.
  final double distanceMax;

  /// The radius of the contact ellipse along the major axis, in logical pixels.
  final double radiusMajor;

  /// The radius of the contact ellipse along the minor axis, in logical pixels.
  final double radiusMinor;

  /// The minimum value that could be reported for radiusMajor and radiusMinor
  /// for this pointer, in logical pixels.
  final double radiusMin;

  /// The minimum value that could be reported for radiusMajor and radiusMinor
  /// for this pointer, in logical pixels.
  final double radiusMax;

  /// For PointerDeviceKind.touch events:
  ///
  /// The angle of the contact ellipse, in radius in the range:
  ///
  ///    -pi/2 < orientation <= pi/2
  ///
  /// ...giving the angle of the major axis of the ellipse with the y-axis
  /// (negative angles indicating an orientation along the top-left /
  /// bottom-right diagonal, positive angles indicating an orientation along the
  /// top-right / bottom-left diagonal, and zero indicating an orientation
  /// parallel with the y-axis).
  ///
  /// For PointerDeviceKind.stylus and PointerDeviceKind.invertedStylus events:
  ///
  /// The angle of the stylus, in radians in the range:
  ///
  ///    -pi < orientation <= pi
  ///
  /// ...giving the angle of the axis of the stylus projected onto the input
  /// surface, relative to the positive y-axis of that surface (thus 0.0
  /// indicates the stylus, if projected onto that surface, would go from the
  /// contact point vertically up in the positive y-axis direction, pi would
  /// indicate that the stylus would go down in the negative y-axis direction;
  /// pi/4 would indicate that the stylus goes up and to the right, -pi/2 would
  /// indicate that the stylus goes to the left, etc).
  final double orientation;

  /// For PointerDeviceKind.stylus and PointerDeviceKind.invertedStylus events:
  ///
  /// The angle of the stylus, in radians in the range:
  ///
  ///    0 <= tilt <= pi/2
  ///
  /// ...giving the angle of the axis of the stylus, relative to the axis
  /// perpendicular to the input surface (thus 0.0 indicates the stylus is
  /// orthogonal to the plane of the input surface, while pi/2 indicates that
  /// the stylus is flat on that surface).
  final double tilt;

  String toString() => '$runtimeType($position)';

  String toStringFull() {
    return '$runtimeType('
             'timeStamp: $timeStamp, '
             'pointer: $pointer, '
             'kind: $kind, '
             'position: $position, '
             'delta: $delta, '
             'buttons: $buttons, '
             'down: $down, '
             'obscured: $obscured, '
             'pressure: $pressure, '
             'pressureMin: $pressureMin, '
             'pressureMax: $pressureMax, '
             'distance: $distance, '
             'distanceMin: $distanceMin, '
             'distanceMax: $distanceMax, '
             'radiusMajor: $radiusMajor, '
             'radiusMinor: $radiusMinor, '
             'radiusMin: $radiusMin, '
             'radiusMax: $radiusMax, '
             'orientation: $orientation, '
             'tilt: $tilt'
           ')';
  }
}

class PointerAddedEvent extends PointerEvent {
  const PointerAddedEvent({
    Duration timeStamp: Duration.ZERO,
    int pointer: 0,
    PointerDeviceKind kind: PointerDeviceKind.touch,
    Point position: Point.origin,
    bool obscured: false,
    double pressureMin: 1.0,
    double pressureMax: 1.0,
    double distance: 0.0,
    double distanceMax: 0.0,
    double radiusMin: 0.0,
    double radiusMax: 0.0,
    double orientation: 0.0,
    double tilt: 0.0
  }) : super(
    timeStamp: timeStamp,
    pointer: pointer,
    kind: kind,
    position: position,
    obscured: obscured,
    pressureMin: pressureMin,
    pressureMax: pressureMax,
    distance: distance,
    distanceMax: distanceMax,
    radiusMin: radiusMin,
    radiusMax: radiusMax,
    orientation: orientation,
    tilt: tilt
  );
}

class PointerRemovedEvent extends PointerEvent {
  const PointerRemovedEvent({
    Duration timeStamp: Duration.ZERO,
    int pointer: 0,
    PointerDeviceKind kind: PointerDeviceKind.touch,
    bool obscured: false,
    double pressureMin: 1.0,
    double pressureMax: 1.0,
    double distanceMax: 0.0,
    double radiusMin: 0.0,
    double radiusMax: 0.0
  }) : super(
    timeStamp: timeStamp,
    pointer: pointer,
    kind: kind,
    position: null,
    obscured: obscured,
    pressureMin: pressureMin,
    pressureMax: pressureMax,
    distanceMax: distanceMax,
    radiusMin: radiusMin,
    radiusMax: radiusMax
  );
}

class PointerDownEvent extends PointerEvent {
  const PointerDownEvent({
    Duration timeStamp: Duration.ZERO,
    int pointer: 0,
    PointerDeviceKind kind: PointerDeviceKind.touch,
    Point position: Point.origin,
    int buttons: 0,
    bool obscured: false,
    double pressure: 1.0,
    double pressureMin: 1.0,
    double pressureMax: 1.0,
    double distanceMax: 0.0,
    double radiusMajor: 0.0,
    double radiusMinor: 0.0,
    double radiusMin: 0.0,
    double radiusMax: 0.0,
    double orientation: 0.0,
    double tilt: 0.0
  }) : super(
    timeStamp: timeStamp,
    pointer: pointer,
    kind: kind,
    position: position,
    buttons: buttons,
    down: true,
    obscured: obscured,
    pressure: pressure,
    pressureMin: pressureMin,
    pressureMax: pressureMax,
    distance: 0.0,
    distanceMax: distanceMax,
    radiusMajor: radiusMajor,
    radiusMinor: radiusMinor,
    radiusMin: radiusMin,
    radiusMax: radiusMax,
    orientation: orientation,
    tilt: tilt
  );
}

class PointerMoveEvent extends PointerEvent {
  const PointerMoveEvent({
    Duration timeStamp: Duration.ZERO,
    int pointer: 0,
    PointerDeviceKind kind: PointerDeviceKind.touch,
    Point position: Point.origin,
    Offset delta: Offset.zero,
    int buttons: 0,
    bool down: false,
    bool obscured: false,
    double pressure: 1.0,
    double pressureMin: 1.0,
    double pressureMax: 1.0,
    double distance: 0.0,
    double distanceMax: 0.0,
    double radiusMajor: 0.0,
    double radiusMinor: 0.0,
    double radiusMin: 0.0,
    double radiusMax: 0.0,
    double orientation: 0.0,
    double tilt: 0.0
  }) : super(
    timeStamp: timeStamp,
    pointer: pointer,
    kind: kind,
    position: position,
    delta: delta,
    buttons: buttons,
    down: down,
    obscured: obscured,
    pressure: pressure,
    pressureMin: pressureMin,
    pressureMax: pressureMax,
    distance: distance,
    distanceMax: distanceMax,
    radiusMajor: radiusMajor,
    radiusMinor: radiusMinor,
    radiusMin: radiusMin,
    radiusMax: radiusMax,
    orientation: orientation,
    tilt: tilt
  );
}

class PointerUpEvent extends PointerEvent {
  const PointerUpEvent({
    Duration timeStamp: Duration.ZERO,
    int pointer: 0,
    PointerDeviceKind kind: PointerDeviceKind.touch,
    Point position: Point.origin,
    int buttons: 0,
    bool obscured: false,
    double pressureMin: 1.0,
    double pressureMax: 1.0,
    double distance: 0.0,
    double distanceMax: 0.0,
    double radiusMin: 0.0,
    double radiusMax: 0.0,
    double orientation: 0.0,
    double tilt: 0.0
  }) : super(
    timeStamp: timeStamp,
    pointer: pointer,
    kind: kind,
    position: position,
    buttons: buttons,
    obscured: obscured,
    pressureMin: pressureMin,
    pressureMax: pressureMax,
    distance: distance,
    distanceMax: distanceMax,
    radiusMin: radiusMin,
    radiusMax: radiusMax,
    orientation: orientation,
    tilt: tilt
  );
}

class PointerCancelEvent extends PointerEvent {
  const PointerCancelEvent({
    Duration timeStamp: Duration.ZERO,
    int pointer: 0,
    PointerDeviceKind kind: PointerDeviceKind.touch,
    Point position: Point.origin,
    int buttons: 0,
    bool obscured: false,
    double pressureMin: 1.0,
    double pressureMax: 1.0,
    double distance: 0.0,
    double distanceMax: 0.0,
    double radiusMin: 0.0,
    double radiusMax: 0.0,
    double orientation: 0.0,
    double tilt: 0.0
  }) : super(
    timeStamp: timeStamp,
    pointer: pointer,
    kind: kind,
    position: position,
    buttons: buttons,
    obscured: obscured,
    pressureMin: pressureMin,
    pressureMax: pressureMax,
    distance: distance,
    distanceMax: distanceMax,
    radiusMin: radiusMin,
    radiusMax: radiusMax,
    orientation: orientation,
    tilt: tilt
  );
}
