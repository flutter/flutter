// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:sky' as sky;

import 'package:sky/src/gestures/arena.dart';
import 'package:sky/src/gestures/constants.dart';
import 'package:sky/src/gestures/recognizer.dart';
import 'package:sky/src/gestures/tap.dart';

class DoubleTapGestureRecognizer extends GestureArenaMember {
  static int sInstances = 0;

  DoubleTapGestureRecognizer({ this.router, this.onDoubleTap }) {
    _instance = sInstances++;
  }

  PointerRouter router;
  GestureTapListener onDoubleTap;

  int _numTaps = 0;
  int _instance = 0;
  bool _isTrackingPointer = false;
  int _pointer;
  sky.Point _initialPosition;
  Timer _tapTimer;
  Timer _doubleTapTimer;
  GestureArenaEntry _entry = null;

  void addPointer(sky.PointerEvent event) {
    message("add pointer");
    if (_initialPosition != null && !_isWithinTolerance(event)) {
      message("reset");
      _reset();
    }
    _pointer = event.pointer;
    _initialPosition = _getPoint(event);
    _isTrackingPointer = false;
    _startTapTimer();
    _stopDoubleTapTimer();
    _startTrackingPointer();
    if (_entry == null) {
      message("register entry");
      _entry = GestureArena.instance.add(event.pointer, this);
    }
  }

  void message(String s) {
    print("Double tap " + _instance.toString() + ": " + s);
  }

  void handleEvent(sky.PointerEvent event) {
    message("handle event");
    if (event.type == 'pointerup') {
      _numTaps++;
      _stopTapTimer();
      _stopTrackingPointer();
      if (_numTaps == 1) {
        message("start long timer");
        _startDoubleTapTimer();
      } else if (_numTaps == 2) {
        message("start found second tap");
        _entry.resolve(GestureDisposition.accepted);
      }
    } else if (event.type == 'pointermove' && !_isWithinTolerance(event)) {
      message("outside tap tolerance");
      _entry.resolve(GestureDisposition.rejected);
    } else if (event.type == 'pointercancel') {
      message("cancel");
      _entry.resolve(GestureDisposition.rejected);
    }
  }

  void acceptGesture(int pointer) {
    message("accepted");
    _reset();
    _entry = null;
    print ("Entry is assigned null");
    onDoubleTap?.call();
  }

  void rejectGesture(int pointer) {
    message("rejected");
    _reset();
    _entry = null;
    print ("Entry is assigned null");
  }

  void dispose() {
    _entry?.resolve(GestureDisposition.rejected);
    router = null;
  }

  void _reset() {
    _numTaps = 0;
    _initialPosition = null;
    _stopTapTimer();
    _stopDoubleTapTimer();
    _stopTrackingPointer();
  }

  void _startTapTimer() {
    if (_tapTimer == null) {
      _tapTimer = new Timer(
        kTapTimeout,
        () => _entry.resolve(GestureDisposition.rejected)
      );
    }
  }

  void _stopTapTimer() {
    if (_tapTimer != null) {
      _tapTimer.cancel();
      _tapTimer = null;
    }
  }

  void _startDoubleTapTimer() {
    if (_doubleTapTimer == null) {
      _doubleTapTimer = new Timer(
        kDoubleTapTimeout,
        () => _entry.resolve(GestureDisposition.rejected)
      );
    }
  }

  void _stopDoubleTapTimer() {
    if (_doubleTapTimer != null) {
      _doubleTapTimer.cancel();
      _doubleTapTimer = null;
    }
  }

  void _startTrackingPointer() {
    if (!_isTrackingPointer) {
      _isTrackingPointer = true;
      router.addRoute(_pointer, handleEvent);
    }
  }

  void _stopTrackingPointer() {
    if (_isTrackingPointer) {
      _isTrackingPointer = false;
      router.removeRoute(_pointer, handleEvent);
    }
  }

  sky.Point _getPoint(sky.PointerEvent event) {
    return new sky.Point(event.x, event.y);
  }

  bool _isWithinTolerance(sky.PointerEvent event) {
    sky.Offset offset = _getPoint(event) - _initialPosition;
    return offset.distance <= kDoubleTapTouchSlop;
  }

}
