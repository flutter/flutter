// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:sky' as sky;

import 'package:sky/gestures/arena.dart';
import 'package:sky/gestures/constants.dart';
import 'package:sky/gestures/recognizer.dart';

typedef void GestureShowPressListener();

class ShowPressGestureRecognizer extends PrimaryPointerGestureRecognizer {
  ShowPressGestureRecognizer({ PointerRouter router, this.onShowPress })
    : super(router: router, deadline: kTapTimeout);

  GestureShowPressListener onShowPress;

  void didExceedDeadline() {
    // Show press isn't an exclusive gesture. We can recognize a show press
    // as well as another gesture, like a long press.
    resolve(GestureDisposition.rejected);
    onShowPress();
  }

  void handlePrimaryPointer(sky.PointerEvent event) {
    if (event.type == 'pointerup')
      resolve(GestureDisposition.rejected);
  }
}
