// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:sky' as sky;

import 'package:sky/src/gestures/arena.dart';
import 'package:sky/src/gestures/constants.dart';
import 'package:sky/src/gestures/pointer_router.dart';
import 'package:sky/src/gestures/recognizer.dart';

typedef void GestureLongPressCallback();

class LongPressGestureRecognizer extends PrimaryPointerGestureRecognizer {
  LongPressGestureRecognizer({ PointerRouter router, this.onLongPress })
    : super(router: router, deadline: kTapTimeout + kLongPressTimeout);

  GestureLongPressCallback onLongPress;

  void didExceedDeadline() {
    resolve(GestureDisposition.accepted);
    onLongPress();
  }

  void handlePrimaryPointer(sky.PointerEvent event) {
    if (event.type == 'pointerup')
      resolve(GestureDisposition.rejected);
  }
}
