// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:sky' as sky;

import 'package:sky/src/gestures/arena.dart';
import 'package:sky/src/gestures/constants.dart';

typedef void GestureTapCallback();

enum TapResolution {
  tap,
  cancel
}

class _TapGesture {
  _TapGesture({ this.gestureRecognizer, sky.PointerEvent event }) {
    assert(event.type == 'pointerdown');
    _pointer = event.pointer;
    _isTrackingPointer = false;
    _initialPosition = _getPoint(event);
    _entry = GestureArena.instance.add(_pointer, gestureRecognizer);
    _wonArena = false;
    _didTap = false;
    _startTimer();
    _startTrackingPointer();
  }

  TapGestureRecognizer gestureRecognizer;

  int _pointer;
  bool _isTrackingPointer;
  sky.Point _initialPosition;
  GestureArenaEntry _entry;
  Timer _deadline;
  bool _wonArena;
  bool _didTap;

  void handleEvent(sky.PointerEvent event) {
    print("Tap gesture handleEvent");
    assert(event.pointer == _pointer);
    if (event.type == 'pointermove' && !_isWithinTolerance(event)) {
      _entry.resolve(GestureDisposition.rejected);
    } else if (event.type == 'pointercancel') {
      _entry.resolve(GestureDisposition.rejected);
    } else if (event.type == 'pointerup') {
      _stopTimer();
      _stopTrackingPointer();
      _didTap = true;
      _check();
    }
  }

  void accept() {
    print("Tap gesture accept");
    _wonArena = true;
    _check();
  }

  void reject() {
    print("Tap gesture reject");
    _stopTimer();
    _stopTrackingPointer();
    gestureRecognizer._resolveTap(_pointer, TapResolution.cancel);
  }

  void abort() {
    _entry.resolve(GestureDisposition.rejected);
  }

  void _check() {
    if (_wonArena && _didTap)
      gestureRecognizer._resolveTap(_pointer, TapResolution.tap);
  }

  void _startTimer() {
    if (_deadline == null) {
      _deadline = new Timer(
        kTapTimeout,
        () => _entry.resolve(GestureDisposition.rejected)
      );
    }
  }

  void _stopTimer() {
    if (_deadline != null) {
      _deadline.cancel();
      _deadline = null;
    }
  }

  void _startTrackingPointer() {
    if (!_isTrackingPointer) {
      _isTrackingPointer = true;
      gestureRecognizer.router.addRoute(_pointer, handleEvent);
    }
  }

  void _stopTrackingPointer() {
    if (_isTrackingPointer) {
      _isTrackingPointer = false;
      gestureRecognizer.router.removeRoute(_pointer, handleEvent);
    }
  }

  sky.Point _getPoint(sky.PointerEvent event) {
    return new sky.Point(event.x, event.y);
  }

  bool _isWithinTolerance(sky.PointerEvent event) {
    sky.Offset offset = _getPoint(event) - _initialPosition;
    return offset.distance <= kTouchSlop;
  }

}

class TapGestureRecognizer extends GestureArenaMember {
  TapGestureRecognizer({ this.router, this.onTap, this.onTapDown, this.onTapCancel });

  PointerRouter router;
  GestureTapCallback onTap;
  GestureTapCallback onTapDown;
  GestureTapCallback onTapCancel;

  Map<int, _TapGesture> _gestureMap = new Map<int, _TapGesture>();

  void addPointer(sky.PointerEvent event) {
    _gestureMap[event.pointer] = new _TapGesture(
      gestureRecognizer: this,
      event: event
    );
    onTapDown?.call();
  }

  void acceptGesture(int pointer) {
    _gestureMap[pointer]?.accept();
  }

  void rejectGesture(int pointer) {
    _gestureMap[pointer]?.reject();
  }

  void _resolveTap(int pointer, TapResolution resolution) {
    _gestureMap.remove(pointer);
    if (resolution == TapResolution.tap)
      onTap?.call();
    else
      onTapCancel?.call();
  }

  void dispose() {
    List<_TapGesture> localGestures = new List.from(_gestureMap.values);
    for (_TapGesture gesture in localGestures)
      entry.abort();
    // Rejection of each gesture should cause it to be removed from our map
    assert(_gestureMap.isEmpty);
    router = null;
  }

}
