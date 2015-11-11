import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';

export 'dart:ui' show Point;

class TestPointer {
  TestPointer([ this.pointer = 1 ]);

  int pointer;
  bool isDown = false;
  ui.Point location;

  PointerInputEvent down(ui.Point newLocation, { double timeStamp: 0.0 }) {
    assert(!isDown);
    isDown = true;
    location = newLocation;
    return new PointerInputEvent(
      type: 'pointerdown',
      pointer: pointer,
      x: location.x,
      y: location.y,
      timeStamp: timeStamp
    );
  }

  PointerInputEvent move(ui.Point newLocation, { double timeStamp: 0.0 }) {
    assert(isDown);
    ui.Offset delta = newLocation - location;
    location = newLocation;
    return new PointerInputEvent(
      type: 'pointermove',
      pointer: pointer,
      x: newLocation.x,
      y: newLocation.y,
      dx: delta.dx,
      dy: delta.dy,
      timeStamp: timeStamp
    );
  }

  PointerInputEvent up({ double timeStamp: 0.0 }) {
    assert(isDown);
    isDown = false;
    return new PointerInputEvent(
      type: 'pointerup',
      pointer: pointer,
      x: location.x,
      y: location.y,
      timeStamp: timeStamp
    );
  }

  PointerInputEvent cancel({ double timeStamp: 0.0 }) {
    assert(isDown);
    isDown = false;
    return new PointerInputEvent(
      type: 'pointercancel',
      pointer: pointer,
      x: location.x,
      y: location.y,
      timeStamp: timeStamp
    );
  }

}
