// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:sky' as sky;

import 'package:sky/src/gestures/arena.dart';
import 'package:sky/src/gestures/constants.dart';
import 'package:sky/src/gestures/recognizer.dart';
import 'package:sky/src/gestures/tap.dart';

class DoubleTapGestureRecognizer extends PrimaryPointerGestureRecognizer {
  DoubleTapGestureRecognizer({ PointerRouter router, this.onDoubleTap })
    : super(router: router, deadline: kTapTimeout);

  GestureTapListener onDoubleTap;
  int _numTaps = 0;
  Timer _longTimer;

  void resolve(GestureDisposition disposition) {
    super.resolve(disposition);
    if (disposition == GestureDisposition.rejected) {
      _numTaps = 0;
    }
  }

  void didExceedDeadline() {
    stopTrackingPointer(primaryPointer);
    resolve(GestureDisposition.rejected);
  }

  void didExceedLongDeadline() {
    _numTaps = 0;
    _longTimer = null;
  }

  void handlePrimaryPointer(sky.PointerEvent event) {
    if (event.type == 'pointerup') {
      _numTaps++;
      if (_numTaps == 1) {
        _longTimer = new Timer(kDoubleTapTimeout, didExceedLongDeadline);
      } else if (_numTaps == 2) {
        resolve(GestureDisposition.accepted);
        onDoubleTap();
      }
    }
  }


}
