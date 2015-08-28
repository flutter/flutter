// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:sky' as sky;

import 'package:sky/gestures/arena.dart';
import 'package:sky/gestures/recognizer.dart';

typedef void GestureTapListener();

class TapGestureRecognizer extends PrimaryPointerGestureRecognizer {
  TapGestureRecognizer({ PointerRouter router, this.onTap })
    : super(router: router);

  GestureTapListener onTap;

  void handlePrimaryPointer(sky.PointerEvent event) {
    if (event.type == 'pointerup') {
      resolve(GestureDisposition.accepted);
      onTap();
    }
  }
}
