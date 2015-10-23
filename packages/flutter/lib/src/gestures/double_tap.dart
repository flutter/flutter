// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'arena.dart';
import 'constants.dart';
import 'events.dart';
import 'recognizer.dart';
import 'tap.dart';

class DoubleTapGestureRecognizer extends DisposableArenaMember {

  DoubleTapGestureRecognizer({ this.router, this.onDoubleTap });

  // Implementation notes:
  // The double tap recognizer can be in one of four states. There's no
  // explicit enum for the states, because they are already captured by
  // the state of existing fields.  Specifically:
  // Waiting on first tap: In this state, the _trackers list is empty, and
  // _firstTap is null.
  // First tap in progress: In this state, the _trackers list contains all
  // the states for taps that have begun but not completed. This list can
  // have more than one entry if two pointers begin to tap.
  // Waiting on second tap: In this state, one of the in-progress taps has
  // completed successfully. The _trackers list is again empty, and
  // _firstTap records the successful tap.
  // Second tap in progress: Much like the "first tap in progress" state, but
  // _firstTap is non-null.  If a tap completes successfully while in this
  // state, the callback is invoked and the state is reset.
  // There are various other scenarios that cause the state to reset:
  // - All in-progress taps are rejected (by time, distance, pointercancel, etc)
  // - The long timer between taps expires
  // - The gesture arena decides we have been rejected wholesale

  PointerRouter router;
  GestureTapCallback onDoubleTap;

  Timer _doubleTapTimer;
  TapTracker _firstTap;
  Map<int, TapTracker> _trackers = new Map<int, TapTracker>();

  void addPointer(PointerInputEvent event) {
    // Ignore out-of-bounds second taps
    if (_firstTap != null &&
        !_firstTap.isWithinTolerance(event, kDoubleTapTouchSlop))
      return;
    _stopDoubleTapTimer();
    TapTracker tracker = new TapTracker(
      event: event,
      entry: GestureArena.instance.add(event.pointer, this)
    );
    _trackers[event.pointer] = tracker;
    tracker.startTimer(() => _reject(tracker));
    tracker.startTrackingPointer(router, handleEvent);
  }

  void handleEvent(PointerInputEvent event) {
    TapTracker tracker = _trackers[event.pointer];
    assert(tracker != null);
    if (event.type == 'pointerup') {
      if (_firstTap == null)
        _registerFirstTap(tracker);
      else
        _registerSecondTap(tracker);
    } else if (event.type == 'pointermove' &&
        !tracker.isWithinTolerance(event, kTouchSlop)) {
      _reject(tracker);
    } else if (event.type == 'pointercancel') {
      _reject(tracker);
    }
  }

  void acceptGesture(int pointer) {}

  void rejectGesture(int pointer) {
    TapTracker tracker = _trackers[pointer];
    // If tracker isn't in the list, check if this is the first tap tracker
    if (tracker == null &&
        _firstTap != null &&
        _firstTap.pointer == pointer)
      tracker = _firstTap;
    // If tracker is still null, we rejected ourselves already
    if (tracker != null)
      _reject(tracker);
  }

  void _reject(TapTracker tracker) {
    _trackers.remove(tracker.pointer);
    tracker.entry.resolve(GestureDisposition.rejected);
    _freezeTracker(tracker);
    // If the first tap is in progress, and we've run out of taps to track,
    // reset won't have any work to do.  But if we're in the second tap, we need
    // to clear intermediate state.
    if (_firstTap != null &&
        (_trackers.isEmpty || tracker == _firstTap))
      _reset();
  }

  void dispose() {
    _reset();
    router = null;
  }

  void _reset() {
    _stopDoubleTapTimer();
    if (_firstTap != null) {
      // Note, order is important below in order for the resolve -> reject logic
      // to work properly
      TapTracker tracker = _firstTap;
      _firstTap = null;
      _reject(tracker);
      GestureArena.instance.release(tracker.pointer);
    }
    _clearTrackers();
  }

  void _registerFirstTap(TapTracker tracker) {
    _startDoubleTapTimer();
    GestureArena.instance.hold(tracker.pointer);
    // Note, order is important below in order for the clear -> reject logic to
    // work properly.
    _freezeTracker(tracker);
    _trackers.remove(tracker.pointer);
    _clearTrackers();
    _firstTap = tracker;
  }

  void _registerSecondTap(TapTracker tracker) {
    _firstTap.entry.resolve(GestureDisposition.accepted);
    tracker.entry.resolve(GestureDisposition.accepted);
    _freezeTracker(tracker);
    _trackers.remove(tracker.pointer);
    if (onDoubleTap != null)
      onDoubleTap();
    _reset();
  }

  void _clearTrackers() {
    List<TapTracker> localTrackers = new List<TapTracker>.from(_trackers.values);
    for (TapTracker tracker in localTrackers)
      _reject(tracker);
    assert(_trackers.isEmpty);
  }

  void _freezeTracker(TapTracker tracker) {
    tracker.stopTimer();
    tracker.stopTrackingPointer(router, handleEvent);
  }

  void _startDoubleTapTimer() {
    _doubleTapTimer ??= new Timer(kDoubleTapTimeout, () => _reset());
  }

  void _stopDoubleTapTimer() {
    if (_doubleTapTimer != null) {
      _doubleTapTimer.cancel();
      _doubleTapTimer = null;
    }
  }

}
