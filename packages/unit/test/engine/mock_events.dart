import 'dart:sky' as sky;

class TestPointerEvent extends sky.PointerEvent {
  TestPointerEvent({
    this.type,
    this.pointer,
    this.kind,
    this.x,
    this.y,
    this.dx,
    this.dy,
    this.velocityX,
    this.velocityY,
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
  });

  // These are all of the PointerEvent members, but not all of Event.
  String type;
  int pointer;
  String kind;
  double x;
  double y;
  double dx;
  double dy;
  double velocityX;
  double velocityY;
  int buttons;
  bool down;
  bool primary;
  bool obscured;
  double pressure;
  double pressureMin;
  double pressureMax;
  double distance;
  double distanceMin;
  double distanceMax;
  double radiusMajor;
  double radiusMinor;
  double radiusMin;
  double radiusMax;
  double orientation;
  double tilt;
}

class TestGestureEvent extends sky.GestureEvent {
  TestGestureEvent({
    this.type,
    this.primaryPointer,
    this.x,
    this.y,
    this.dx,
    this.dy,
    this.velocityX,
    this.velocityY
  });

  // These are all of the GestureEvent members, but not all of Event.
  String type;
  int primaryPointer;
  double x;
  double y;
  double dx;
  double dy;
  double velocityX;
  double velocityY;
}
