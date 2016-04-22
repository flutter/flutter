// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:collection';
import 'dart:ui' show Point, Offset;

import 'arena.dart';
import 'binding.dart';
import 'constants.dart';
import 'events.dart';
import 'pointer_router.dart';

export 'pointer_router.dart' show PointerRouter;

/// The base class that all GestureRecognizers should inherit from.
///
/// Provides a basic API that can be used by classes that work with
/// gesture recognizers but don't care about the specific details of
/// the gestures recognizers themselves.
abstract class GestureRecognizer extends GestureArenaMember {

  /// Registers a new pointer that might be relevant to this gesture
  /// detector.
  ///
  /// The owner of this gesture recognizer calls addPointer() with the
  /// PointerDownEvent of each pointer that should be considered for
  /// this gesture.
  ///
  /// It's the GestureRecognizer's responsibility to then add itself
  /// to the global pointer router (see [PointerRouter]) to receive
  /// subsequent events for this pointer, and to add the pointer to
  /// the global gesture arena manager (see [GestureArenaManager]) to track
  /// that pointer.
  void addPointer(PointerDownEvent event);

  /// Releases any resources used by the object.
  ///
  /// This method is called by the owner of this gesture recognizer
  /// when the object is no longer needed (e.g. when a gesture
  /// recogniser is being unregistered from a [GestureDetector], the
  /// GestureDetector widget calls this method).
  void dispose() { }

  /// Returns a very short pretty description of the gesture that the
  /// recognizer looks for, like 'tap' or 'horizontal drag'.
  String toStringShort() => toString();
}

/// Base class for gesture recognizers that can only recognize one
/// gesture at a time. For example, a single [TapGestureRecognizer]
/// can never recognize two taps happening simultaneously, even if
/// multiple pointers are placed on the same widget.
///
/// This is in contrast to, for instance, [MultiTapGestureRecognizer],
/// which manages each pointer independently and can consider multiple
/// simultaneous touches to each result in a separate tap.
abstract class OneSequenceGestureRecognizer extends GestureRecognizer {
  final List<GestureArenaEntry> _entries = <GestureArenaEntry>[];
  final Set<int> _trackedPointers = new HashSet<int>();

  void handleEvent(PointerEvent event);

  @override
  void acceptGesture(int pointer) { }

  @override
  void rejectGesture(int pointer) { }

  void didStopTrackingLastPointer(int pointer);

  void resolve(GestureDisposition disposition) {
    List<GestureArenaEntry> localEntries = new List<GestureArenaEntry>.from(_entries);
    _entries.clear();
    for (GestureArenaEntry entry in localEntries)
      entry.resolve(disposition);
  }

  @override
  void dispose() {
    resolve(GestureDisposition.rejected);
    for (int pointer in _trackedPointers)
      GestureBinding.instance.pointerRouter.removeRoute(pointer, handleEvent);
    _trackedPointers.clear();
    assert(_entries.isEmpty);
  }

  void startTrackingPointer(int pointer) {
    GestureBinding.instance.pointerRouter.addRoute(pointer, handleEvent);
    _trackedPointers.add(pointer);
    _entries.add(GestureBinding.instance.gestureArena.add(pointer, this));
  }

  void stopTrackingPointer(int pointer) {
    GestureBinding.instance.pointerRouter.removeRoute(pointer, handleEvent);
    _trackedPointers.remove(pointer);
    if (_trackedPointers.isEmpty)
      didStopTrackingLastPointer(pointer);
  }

  void ensureNotTrackingPointer(int pointer) {
    if (_trackedPointers.contains(pointer))
      stopTrackingPointer(pointer);
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
  PrimaryPointerGestureRecognizer({ this.deadline });

  final Duration deadline;

  GestureRecognizerState state = GestureRecognizerState.ready;
  int primaryPointer;
  Point initialPosition;
  Timer _timer;

  @override
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

  @override
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

  /// Override to be notified when [deadline] is exceeded.
  ///
  /// You must override this function if you supply a [deadline].
  void didExceedDeadline() {
    assert(deadline == null);
  }

  @override
  void rejectGesture(int pointer) {
    if (pointer == primaryPointer) {
      _stopTimer();
      state = GestureRecognizerState.defunct;
    }
  }

  @override
  void didStopTrackingLastPointer(int pointer) {
    _stopTimer();
    state = GestureRecognizerState.ready;
  }

  @override
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
