// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;

import 'arena.dart';
import 'constants.dart';
import 'events.dart';
import 'pointer_router.dart';
import 'recognizer.dart';

typedef void GestureTapCallback();

/// TapGestureRecognizer is a tap recognizer that tracks only one primary
/// pointer per gesture. That is, during tap recognition, extra pointer events
/// are ignored: down-1, down-2, up-1, up-2 produces only one tap on up-1.
class TapGestureRecognizer extends PrimaryPointerGestureRecognizer {
  TapGestureRecognizer({ PointerRouter router, this.onTap })
    : super(router: router);

  GestureTapCallback onTap;
  GestureTapCallback onTapDown;
  GestureTapCallback onTapCancel;

  bool _wonArena = false;
  bool _didTap = false;

  void handlePrimaryPointer(PointerInputEvent event) {
    if (event.type == 'pointerdown') {
      if (onTapDown != null)
        onTapDown();
    } else if (event.type == 'pointerup') {
      _didTap = true;
      _check();
    }
  }

  void acceptGesture(int pointer) {
    super.acceptGesture(pointer);
    if (pointer == primaryPointer) {
      _wonArena = true;
      _check();
    }
  }

  void rejectGesture(int pointer) {
    super.rejectGesture(pointer);
    if (pointer == primaryPointer) {
      assert(state == GestureRecognizerState.defunct);
      _wonArena = false;
      _didTap = false;
      if (onTapCancel != null)
        onTapCancel();
    }
  }

  void _check() {
    if (_wonArena && _didTap) {
      resolve(GestureDisposition.accepted);
      if (onTap != null)
        onTap();
    }
  }
}

/// TapTracker helps track individual tap sequences as part of a
/// larger gesture.
class TapTracker {

  TapTracker({ PointerInputEvent event, this.entry })
    : pointer = event.pointer,
      _initialPosition = event.position,
      _isTrackingPointer = false {
    assert(event.type == 'pointerdown');
  }

  int pointer;
  GestureArenaEntry entry;
  ui.Point _initialPosition;
  bool _isTrackingPointer;

  void startTrackingPointer(PointerRouter router, PointerRoute route) {
    if (!_isTrackingPointer) {
      _isTrackingPointer = true;
      router.addRoute(pointer, route);
    }
  }

  void stopTrackingPointer(PointerRouter router, PointerRoute route) {
    if (_isTrackingPointer) {
      _isTrackingPointer = false;
      router.removeRoute(pointer, route);
    }
  }

  bool isWithinTolerance(PointerInputEvent event, double tolerance) {
    ui.Offset offset = event.position - _initialPosition;
    return offset.distance <= tolerance;
  }

}

enum TapResolution {
  tap,
  cancel
}

/// TapGesture represents a full gesture resulting from a single tap
/// sequence. Tap gestures are passive, meaning that they will not
/// pre-empt any other arena member in play.
class TapGesture extends TapTracker {

  TapGesture({ this.gestureRecognizer, PointerInputEvent event })
    : super(event: event) {
    entry = GestureArena.instance.add(event.pointer, gestureRecognizer);
    _wonArena = false;
    _didTap = false;
    startTrackingPointer(gestureRecognizer.router, handleEvent);
  }

  MultiTapGestureRecognizer gestureRecognizer;

  bool _wonArena;
  bool _didTap;

  void handleEvent(PointerInputEvent event) {
    assert(event.pointer == pointer);
    if (event.type == 'pointermove' && !isWithinTolerance(event, kTouchSlop)) {
      cancel();
    } else if (event.type == 'pointercancel') {
      cancel();
    } else if (event.type == 'pointerup') {
      stopTrackingPointer(gestureRecognizer.router, handleEvent);
      _didTap = true;
      _check();
    }
  }

  void accept() {
    _wonArena = true;
    _check();
  }

  void reject() {
    stopTrackingPointer(gestureRecognizer.router, handleEvent);
    gestureRecognizer._resolveTap(pointer, TapResolution.cancel);
  }

  void cancel() {
    // If we won the arena already, then entry is resolved, so resolving
    // again is a no-op. But we still need to clean up our own state.
    if (_wonArena)
      reject();
    else
      entry.resolve(GestureDisposition.rejected);
  }

  void _check() {
    if (_wonArena && _didTap)
      gestureRecognizer._resolveTap(pointer, TapResolution.tap);
  }

}

/// MultiTapGestureRecognizer is a tap recognizer that treats taps
/// independently. That is, each pointer sequence that could resolve to a tap
/// does so independently of others: down-1, down-2, up-1, up-2 produces two
/// taps, on up-1 and up-2.
class MultiTapGestureRecognizer extends DisposableArenaMember {
  MultiTapGestureRecognizer({ this.router, this.onTap, this.onTapDown, this.onTapCancel });

  PointerRouter router;
  GestureTapCallback onTap;
  GestureTapCallback onTapDown;
  GestureTapCallback onTapCancel;

  Map<int, TapGesture> _gestureMap = new Map<int, TapGesture>();

  void addPointer(PointerInputEvent event) {
    assert(!_gestureMap.containsKey(event.pointer));
    _gestureMap[event.pointer] = new TapGesture(
      gestureRecognizer: this,
      event: event
    );
    if (onTapDown != null)
      onTapDown();
  }

  void acceptGesture(int pointer) {
    assert(_gestureMap.containsKey(pointer));
    _gestureMap[pointer]?.accept();
  }

  void rejectGesture(int pointer) {
    assert(_gestureMap.containsKey(pointer));
    _gestureMap[pointer]?.reject();
  }

  void _resolveTap(int pointer, TapResolution resolution) {
    _gestureMap.remove(pointer);
    if (resolution == TapResolution.tap) {
      if (onTap != null)
        onTap();
    } else {
      if (onTapCancel != null)
        onTapCancel();
    }
  }

  void dispose() {
    List<TapGesture> localGestures = new List<TapGesture>.from(_gestureMap.values);
    for (TapGesture gesture in localGestures)
      gesture.cancel();
    // Rejection of each gesture should cause it to be removed from our map
    assert(_gestureMap.isEmpty);
    router = null;
  }

}
