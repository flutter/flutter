// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:sky' as sky;

import 'package:sky/src/gestures/arena.dart';
import 'package:sky/src/gestures/recognizer.dart';

typedef void GestureTapCallback();

class TapGestureRecognizer extends PrimaryPointerGestureRecognizer {
  TapGestureRecognizer({ PointerRouter router, this.onTap })
    : super(router: router);

  GestureTapCallback onTap;
  GestureTapCallback onTapDown;
  GestureTapCallback onTapCancel;

  void handlePrimaryPointer(sky.PointerEvent event) {
    if (event.type == 'pointerdown') {
      if (onTapDown != null)
        onTapDown();
    } else if (event.type == 'pointerup') {
      resolve(GestureDisposition.accepted);
      if (onTap != null)
        onTap();
    }
  }

  void rejectGesture(int pointer) {
    super.rejectGesture(pointer);
    if (pointer == primaryPointer) {
      assert(state == GestureRecognizerState.defunct);
      if (onTapCancel != null)
        onTapCancel();
    }
  }
}
