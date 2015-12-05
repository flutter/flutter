// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:ui' show Point, Offset;

import 'arena.dart';
import 'constants.dart';
import 'events.dart';
import 'pointer_router.dart';

export 'pointer_router.dart' show PointerRouter;

abstract class GestureRecognizer extends GestureArenaMember {

  /// Call this with the pointerdown event of each pointer that should be
  /// considered for this gesture. (It's the GestureRecognizer's responsibility
  /// to then add itself to the global pointer router to receive subsequent
  /// events for this pointer.)
  void addPointer(PointerDownEvent event);

  /// Release any resources used by the object. Called when the object is no
  /// longer needed (e.g. a gesture recogniser is being unregistered from a
  /// [GestureDetector]).
  void dispose() { }

}

abstract class OneSequenceGestureRecognizer extends GestureRecognizer {
  OneSequenceGestureRecognizer({ PointerRouter router }) : _router = router {
    assert(_router != null);
  }

  PointerRouter _router;

  final List<GestureArenaEntry> _entries = <GestureArenaEntry>[];
  final Set<int> _trackedPointers = new Set<int>();

  void handleEvent(PointerEvent event);
  void acceptGesture(int pointer) { }
  void rejectGesture(int pointer) { }
  void didStopTrackingLastPointer(int pointer);

  void resolve(GestureDisposition disposition) {
    List<GestureArenaEntry> localEntries = new List<GestureArenaEntry>.from(_entries);
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
      didStopTrackingLastPointer(pointer);
  }

  void stopTrackingIfPointerNoLongerDown(PointerEvent event) {
    if (event is PointerUpEvent || event is PointerCancelEvent)
      stopTrackingPointer(event.pointer);
  }

}

enum GestureRecognizerState {
  ready,
  possible,
  defunct
}

abstract class PrimaryPointerGestureRecognizer extends OneSequenceGestureRecognizer {
  PrimaryPointerGestureRecognizer({ PointerRouter router, this.deadline })
    : super(router: router);

  final Duration deadline;

  GestureRecognizerState state = GestureRecognizerState.ready;
  int primaryPointer;
  Point initialPosition;
  Timer _timer;

  void addPointer(PointerDownEvent event) {
    startTrackingPointer(event.pointer);
    if (state == GestureRecognizerState.ready) {
      state = GestureRecognizerState.possible;
      primaryPointer = event.pointer;
      initialPosition = event.position;
      if (deadline != null)
        _timer = new Timer(deadline, didExceedDeadline);
    }
  }

  void handleEvent(PointerEvent event) {
    assert(state != GestureRecognizerState.ready);
    if (state == GestureRecognizerState.possible && event.pointer == primaryPointer) {
      // TODO(abarth): Maybe factor the slop handling out into a separate class?
      if (event is PointerMoveEvent && _getDistance(event) > kTouchSlop) {
        resolve(GestureDisposition.rejected);
        stopTrackingPointer(primaryPointer);
      } else {
        handlePrimaryPointer(event);
      }
    }
    stopTrackingIfPointerNoLongerDown(event);
  }

  /// Override to provide behavior for the primary pointer when the gesture is still possible.
  void handlePrimaryPointer(PointerEvent event);

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

  void didStopTrackingLastPointer(int pointer) {
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

  double _getDistance(PointerEvent event) {
    Offset offset = event.position - initialPosition;
    return offset.distance;
  }

}
