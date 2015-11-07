import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';

export 'dart:ui' show Point;

class TestPointer {
  TestPointer([ this.pointer = 1 ]);

  int pointer;
  bool isDown = false;
  ui.Point location;

  PointerInputEvent down([ui.Point newLocation = ui.Point.origin ]) {
    assert(!isDown);
    isDown = true;
    location = newLocation;
    return new PointerInputEvent(
      type: 'pointerdown',
      pointer: pointer,
      x: location.x,
      y: location.y
    );
  }

  PointerInputEvent move([ui.Point newLocation = ui.Point.origin ]) {
    assert(isDown);
    ui.Offset delta = newLocation - location;
    location = newLocation;
    return new PointerInputEvent(
      type: 'pointermove',
      pointer: pointer,
      x: newLocation.x,
      y: newLocation.y,
      dx: delta.dx,
      dy: delta.dy
    );
  }

  PointerInputEvent up() {
    assert(isDown);
    isDown = false;
    return new PointerInputEvent(
      type: 'pointerup',
      pointer: pointer,
      x: location.x,
      y: location.y
    );
  }

  PointerInputEvent cancel() {
    assert(isDown);
    isDown = false;
    return new PointerInputEvent(
      type: 'pointercancel',
      pointer: pointer,
      x: location.x,
      y: location.y
    );
  }

}
