// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:sky' as sky;

import 'package:sky/src/gestures/arena.dart';
import 'package:sky/src/gestures/constants.dart';
import 'package:sky/src/gestures/recognizer.dart';

typedef void GestureTapListener();

class TapGestureRecognizer extends PrimaryPointerGestureRecognizer {
  TapGestureRecognizer({ PointerRouter router, this.onTap })
    : super(router: router, deadline: kTapTimeout);

  GestureTapListener onTap;

  void didExceedDeadline() {
    stopTrackingPointer(primaryPointer);
    resolve(GestureDisposition.rejected);
  }

  void handlePrimaryPointer(sky.PointerEvent event) {
    if (event.type == 'pointerup') {
      resolve(GestureDisposition.accepted);
      onTap();
    }
  }
}
