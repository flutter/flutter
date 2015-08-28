// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:sky' as sky;

import 'package:sky/gestures/arena.dart';
import 'package:sky/gestures/recognizer.dart';
import 'package:sky/gestures/constants.dart';

enum ScrollState {
  ready,
  possible,
  accepted
}

typedef void GestureScrollStartCallback(sky.Offset scrollDelta);
typedef void GestureScrollUpdateCallback(sky.Offset scrollDelta);
typedef void GestureScrollEndCallback();

sky.Offset _getScrollOffset(sky.PointerEvent event) {
  // Notice that we negate dy because scroll offsets go in the opposite direction.
  return new sky.Offset(event.dx, -event.dy);
}

class ScrollGestureRecognizer extends GestureRecognizer {
  ScrollGestureRecognizer({ PointerRouter router, this.onScrollStart, this.onScrollUpdate, this.onScrollEnd })
    : super(router: router);

  GestureScrollStartCallback onScrollStart;
  GestureScrollUpdateCallback onScrollUpdate;
  GestureScrollEndCallback onScrollEnd;

  ScrollState state = ScrollState.ready;
  sky.Offset pendingScrollOffset;

  void addPointer(sky.PointerEvent event) {
    startTrackingPointer(event.pointer);
    if (state == ScrollState.ready) {
      state = ScrollState.possible;
      pendingScrollOffset = sky.Offset.zero;
    }
  }

  void handleEvent(sky.PointerEvent event) {
    assert(state != ScrollState.ready);
    if (event.type == 'pointermove') {
      sky.Offset offset = _getScrollOffset(event);
      if (state == ScrollState.accepted) {
        onScrollUpdate(offset);
      } else {
        pendingScrollOffset += offset;
        if (pendingScrollOffset.distance > kTouchSlop)
          resolve(GestureDisposition.accepted);
      }
    }
    stopTrackingIfPointerNoLongerDown(event);
  }

  void acceptGesture(int pointer) {
    if (state != ScrollState.accepted) {
      state = ScrollState.accepted;
      sky.Offset offset = pendingScrollOffset;
      pendingScrollOffset = null;
      onScrollStart(offset);
    }
  }

  void didStopTrackingLastPointer() {
     bool wasAccepted = (state == ScrollState.accepted);
     state = ScrollState.ready;
     if (wasAccepted)
      onScrollEnd();
  }

}
