import 'dart:ui' as ui;

/// Dart-layer version of ui.Event
class InputEvent {

  InputEvent({ this.type }) : timeStamp = 0.0;

  factory InputEvent.fromSkyEvent(ui.Event event) {
    if (event is ui.PointerEvent)
      return new PointerInputEvent.fromUiEvent(event);

    // Default event
    InputEvent result = new InputEvent();
    result.type = event.type;
    result.timeStamp = event.timeStamp;
  }

  String type;
  double timeStamp;
}

/// Dart-layer version of ui.PointerInputEvent
class PointerInputEvent extends InputEvent {

  // Map actual input pointer value to a unique value
  // Since events are serialized we can just use a counter
  static Map<int, int> _pointerMap = new Map<int, int>();
  static int _pointerCount = 0;

  PointerInputEvent({
    String type,
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
  }) : super(type: type);

  PointerInputEvent.fromUiEvent(ui.PointerEvent event) {
    type = event.type;
    timeStamp = event.timeStamp;

    if (type == 'pointerdown') {
      pointer = _pointerCount;
      _pointerMap[event.pointer] = _pointerCount;
      _pointerCount++;
    } else {
      pointer = _pointerMap[event.pointer];
    }

    kind = event.kind;
    x = event.x;
    y = event.y;
    dx = event.dx;
    dy = event.dy;
    buttons = event.buttons;
    down = event.down;
    primary = event.primary;
    obscured = event.obscured;
    pressure = event.pressure;
    pressureMin = event.pressureMin;
    pressureMax = event.pressureMax;
    distance = event.distance;
    distanceMin = event.distanceMin;
    distanceMax = event.distanceMax;
    radiusMajor = event.radiusMajor;
    radiusMinor = event.radiusMinor;
    radiusMin = event.radiusMin;
    radiusMax = event.radiusMax;
    orientation = event.orientation;
    tilt = event.tilt;

  }

  int pointer;
  String kind;
  double x;
  double y;
  double dx;
  double dy;
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
