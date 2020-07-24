// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.10
part of ui;

/// How the pointer has changed since the last report.
enum PointerChange {
  /// The input from the pointer is no longer directed towards this receiver.
  cancel,

  /// The device has started tracking the pointer.
  ///
  /// For example, the pointer might be hovering above the device, having not yet
  /// made contact with the surface of the device.
  add,

  /// The device is no longer tracking the pointer.
  ///
  /// For example, the pointer might have drifted out of the device's hover
  /// detection range or might have been disconnected from the system entirely.
  remove,

  /// The pointer has moved with respect to the device while not in contact with
  /// the device.
  hover,

  /// The pointer has made contact with the device.
  down,

  /// The pointer has moved with respect to the device while in contact with the
  /// device.
  move,

  /// The pointer has stopped making contact with the device.
  up,
}

/// The kind of pointer device.
enum PointerDeviceKind {
  /// A touch-based pointer device.
  touch,

  /// A mouse-based pointer device.
  mouse,

  /// A pointer device with a stylus.
  stylus,

  /// A pointer device with a stylus that has been inverted.
  invertedStylus,

  /// An unknown pointer device.
  unknown
}

/// The kind of [PointerDeviceKind.signal].
enum PointerSignalKind {
  /// The event is not associated with a pointer signal.
  none,

  /// A pointer-generated scroll (e.g., mouse wheel or trackpad scroll).
  scroll,

  /// An unknown pointer signal kind.
  unknown
}

/// Information about the state of a pointer.
class PointerData {
  /// Creates an object that represents the state of a pointer.
  const PointerData({
    this.embedderId = 0,
    this.timeStamp = Duration.zero,
    this.change = PointerChange.cancel,
    this.kind = PointerDeviceKind.touch,
    this.signalKind,
    this.device = 0,
    this.pointerIdentifier = 0,
    this.physicalX = 0.0,
    this.physicalY = 0.0,
    this.physicalDeltaX = 0.0,
    this.physicalDeltaY = 0.0,
    this.buttons = 0,
    this.obscured = false,
    this.synthesized = false,
    this.pressure = 0.0,
    this.pressureMin = 0.0,
    this.pressureMax = 0.0,
    this.distance = 0.0,
    this.distanceMax = 0.0,
    this.size = 0.0,
    this.radiusMajor = 0.0,
    this.radiusMinor = 0.0,
    this.radiusMin = 0.0,
    this.radiusMax = 0.0,
    this.orientation = 0.0,
    this.tilt = 0.0,
    this.platformData = 0,
    this.scrollDeltaX = 0.0,
    this.scrollDeltaY = 0.0,
  });

  /// Unique identifier that ties the [PointerEvent] to embedder event created it.
  ///
  /// No two pointer events can have the same [embedderId]. This is different from
  /// [pointerIdentifier] - used for hit-testing, whereas [embedderId] is used to
  /// identify the platform event.
  final int embedderId;

  /// Time of event dispatch, relative to an arbitrary timeline.
  final Duration timeStamp;

  /// How the pointer has changed since the last report.
  final PointerChange change;

  /// The kind of input device for which the event was generated.
  final PointerDeviceKind kind;

  /// The kind of signal for a pointer signal event.
  final PointerSignalKind? signalKind;

  /// Unique identifier for the pointing device, reused across interactions.
  final int device;

  /// Unique identifier for the pointer.
  ///
  /// This field changes for each new pointer down event. Framework uses this
  /// identifier to determine hit test result.
  final int pointerIdentifier;

  /// X coordinate of the position of the pointer, in physical pixels in the
  /// global coordinate space.
  final double physicalX;

  /// Y coordinate of the position of the pointer, in physical pixels in the
  /// global coordinate space.
  final double physicalY;

  /// The distance of pointer movement on X coordinate in physical pixels.
  final double physicalDeltaX;

  /// The distance of pointer movement on Y coordinate in physical pixels.
  final double physicalDeltaY;

  /// Bit field using the *Button constants (primaryMouseButton,
  /// secondaryStylusButton, etc). For example, if this has the value 6 and the
  /// [kind] is [PointerDeviceKind.invertedStylus], then this indicates an
  /// upside-down stylus with both its primary and secondary buttons pressed.
  final int buttons;

  /// Set if an application from a different security domain is in any way
  /// obscuring this application's window. (Aspirational; not currently
  /// implemented.)
  final bool obscured;

  /// Set if this pointer data was synthesized by pointer data packet converter.
  /// pointer data packet converter will synthesize additional pointer datas if
  /// the input sequence of pointer data is illegal.
  ///
  /// For example, a down pointer data will be synthesized if the converter receives
  /// a move pointer data while the pointer is not previously down.
  final bool synthesized;

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

  /// The maximum value that a distance can return for this pointer. If this
  /// input device cannot detect "hover touch" input events, then this will be
  /// 0.0.
  final double distanceMax;

  /// The area of the screen being pressed, scaled to a value between 0 and 1.
  /// The value of size can be used to determine fat touch events. This value
  /// is only set on Android, and is a device specific approximation within
  /// the range of detectable values. So, for example, the value of 0.1 could
  /// mean a touch with the tip of the finger, 0.2 a touch with full finger,
  /// and 0.3 the full palm.
  final double size;

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

  /// Opaque platform-specific data associated with the event.
  final int platformData;

  /// For events with signalKind of PointerSignalKind.scroll:
  ///
  /// The amount to scroll in the x direction, in physical pixels.
  final double scrollDeltaX;

  /// For events with signalKind of PointerSignalKind.scroll:
  ///
  /// The amount to scroll in the y direction, in physical pixels.
  final double scrollDeltaY;

  @override
  String toString() => 'PointerData(x: $physicalX, y: $physicalY)';

  /// Returns a complete textual description of the information in this object.
  String toStringFull() {
    return '$runtimeType('
             'embedderId: $embedderId, '
             'timeStamp: $timeStamp, '
             'change: $change, '
             'kind: $kind, '
             'signalKind: $signalKind, '
             'device: $device, '
             'pointerIdentifier: $pointerIdentifier, '
             'physicalX: $physicalX, '
             'physicalY: $physicalY, '
             'physicalDeltaX: $physicalDeltaX, '
             'physicalDeltaY: $physicalDeltaY, '
             'buttons: $buttons, '
             'synthesized: $synthesized, '
             'pressure: $pressure, '
             'pressureMin: $pressureMin, '
             'pressureMax: $pressureMax, '
             'distance: $distance, '
             'distanceMax: $distanceMax, '
             'size: $size, '
             'radiusMajor: $radiusMajor, '
             'radiusMinor: $radiusMinor, '
             'radiusMin: $radiusMin, '
             'radiusMax: $radiusMax, '
             'orientation: $orientation, '
             'tilt: $tilt, '
             'platformData: $platformData, '
             'scrollDeltaX: $scrollDeltaX, '
             'scrollDeltaY: $scrollDeltaY'
           ')';
  }
}

/// A sequence of reports about the state of pointers.
class PointerDataPacket {
  /// Creates a packet of pointer data reports.
  const PointerDataPacket({ this.data = const <PointerData>[] }) : assert(data != null); // ignore: unnecessary_null_comparison

  /// Data about the individual pointers in this packet.
  ///
  /// This list might contain multiple pieces of data about the same pointer.
  final List<PointerData> data;
}
