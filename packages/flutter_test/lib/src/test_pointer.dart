// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/gestures.dart';

export 'dart:ui' show Point;

class TestPointer {
  TestPointer([ this.pointer = 1 ]);

  int pointer;
  bool isDown = false;
  Point location;

  PointerDownEvent down(Point newLocation, { Duration timeStamp: const Duration() }) {
    assert(!isDown);
    isDown = true;
    location = newLocation;
      return new PointerDownEvent(
      timeStamp: timeStamp,
      pointer: pointer,
      position: location
    );
  }

  PointerMoveEvent move(Point newLocation, { Duration timeStamp: const Duration() }) {
    assert(isDown);
    Offset delta = newLocation - location;
    location = newLocation;
    return new PointerMoveEvent(
      timeStamp: timeStamp,
      pointer: pointer,
      position: newLocation,
      delta: delta
    );
  }

  PointerUpEvent up({ Duration timeStamp: const Duration() }) {
    assert(isDown);
    isDown = false;
    return new PointerUpEvent(
      timeStamp: timeStamp,
      pointer: pointer,
      position: location
    );
  }

  PointerCancelEvent cancel({ Duration timeStamp: const Duration() }) {
    assert(isDown);
    isDown = false;
    return new PointerCancelEvent(
      timeStamp: timeStamp,
      pointer: pointer,
      position: location
    );
  }

}
