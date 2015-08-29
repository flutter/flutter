// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:sky' as sky;

import 'package:sky/base/pointer_router.dart';
import 'package:sky/gestures/arena.dart';
import 'package:sky/gestures/constants.dart';

export 'package:sky/base/pointer_router.dart' show PointerRouter;

abstract class GestureRecognizer extends GestureArenaMember {
  GestureRecognizer({ PointerRouter router }) : _router = router;

  PointerRouter _router;

  final List<GestureArenaEntry> _entries = new List<GestureArenaEntry>();
  final Set<int> _trackedPointers = new Set<int>();

  /// The primary entry point for users of this class.
  void addPointer(sky.PointerEvent event);

  void handleEvent(sky.PointerEvent event);
  void acceptGesture(int pointer) { }
  void rejectGesture(int pointer) { }
  void didStopTrackingLastPointer();

  void resolve(GestureDisposition disposition) {
    List<GestureArenaEntry> localEntries = new List.from(_entries);
    _entries.clear();
    for (GestureArenaEntry entry in localEntries)
      entry.resolve(disposition);
  }

  void dispose() {
    resolve(GestureDisposition.rejected);
    for (int pointer in _trackedPointers)
      _router.removeRoute(pointer, handleEvent);
    _trackedPointers.clear();
    assert(_entries.isEmpty);
    _router = null;
  }

  void startTrackingPointer(int pointer) {
    _router.addRoute(pointer, handleEvent);
    _trackedPointers.add(pointer);
    _entries.add(GestureArena.instance.add(pointer, this));
  }

  void stopTrackingPointer(int pointer) {
    _router.removeRoute(pointer, handleEvent);
    _trackedPointers.remove(pointer);
    if (_trackedPointers.isEmpty)
      didStopTrackingLastPointer();
  }

  void stopTrackingIfPointerNoLongerDown(sky.PointerEvent event) {
    if (event.type == 'pointerup' || event.type == 'pointercancel')
      stopTrackingPointer(event.pointer);
  }

}

enum GestureRecognizerState {
  ready,
  possible,
  defunct
}

sky.Point _getPoint(sky.PointerEvent event) {
  return new sky.Point(event.x, event.y);
}

abstract class PrimaryPointerGestureRecognizer extends GestureRecognizer {
  PrimaryPointerGestureRecognizer({ PointerRouter router, this.deadline })
    : super(router: router);

  final Duration deadline;

  GestureRecognizerState state = GestureRecognizerState.ready;
  int primaryPointer;
  sky.Point initialPosition;
  Timer _timer;

  void addPointer(sky.PointerEvent event) {
    startTrackingPointer(event.pointer);
    if (state == GestureRecognizerState.ready) {
      state = GestureRecognizerState.possible;
      primaryPointer = event.pointer;
      initialPosition = _getPoint(event);
      if (deadline != null)
        _timer = new Timer(deadline, didExceedDeadline);
    }
  }

  void handleEvent(sky.PointerEvent event) {
    assert(state != GestureRecognizerState.ready);
    if (state == GestureRecognizerState.possible && event.pointer == primaryPointer) {
      // TODO(abarth): Maybe factor the slop handling out into a separate class?
      if (event.type == 'pointermove' && _getDistance(event) > kTouchSlop)
        resolve(GestureDisposition.rejected);
      else
        handlePrimaryPointer(event);
    }
    stopTrackingIfPointerNoLongerDown(event);
  }

  /// Override to provide behavior for the primary pointer when the gesture is still possible.
  void handlePrimaryPointer(sky.PointerEvent event);

  /// Override to be notified with [deadline] is exceeded.
  ///
  /// You must override this function if you supply a [deadline].
  void didExceedDeadline() {
    assert(deadline == null);
  }

  void rejectGesture(int pointer) {
    if (pointer == primaryPointer) {
      _stopTimer();
      state = GestureRecognizerState.defunct;
    }
  }

  void didStopTrackingLastPointer() {
    _stopTimer();
    state = GestureRecognizerState.ready;
  }

  void dispose() {
    _stopTimer();
    super.dispose();
  }

  void _stopTimer() {
    if (_timer != null) {
      _timer.cancel();
      _timer = null;
    }
  }

  double _getDistance(sky.PointerEvent event) {
    sky.Offset offset = _getPoint(event) - initialPosition;
    return offset.distance;
  }

}
