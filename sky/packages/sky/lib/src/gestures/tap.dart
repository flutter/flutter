// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:ui' as ui;

import 'arena.dart';
import 'constants.dart';
import 'events.dart';
import 'pointer_router.dart';
import 'recognizer.dart';

typedef void GestureTapDownCallback(ui.Point globalPosition);
typedef void GestureTapUpCallback(ui.Point globalPosition);
typedef void GestureTapCallback();
typedef void GestureTapCancelCallback();

/// TapGestureRecognizer is a tap recognizer that tracks only one primary
/// pointer per gesture. That is, during tap recognition, extra pointer events
/// are ignored: down-1, down-2, up-1, up-2 produces only one tap on up-1.
class TapGestureRecognizer extends PrimaryPointerGestureRecognizer {
  TapGestureRecognizer({
    PointerRouter router,
    this.onTapDown,
    this.onTapUp,
    this.onTap,
    this.onTapCancel
  }) : super(router: router);

  GestureTapDownCallback onTapDown;
  GestureTapDownCallback onTapUp;
  GestureTapCallback onTap;
  GestureTapCancelCallback onTapCancel;

  bool _wonArena = false;
  Point _finalPosition;

  void handlePrimaryPointer(PointerInputEvent event) {
    if (event.type == 'pointerdown') {
      if (onTapDown != null)
        onTapDown(event.position);
    } else if (event.type == 'pointerup') {
      _finalPosition = event.position;
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
      if (onTapCancel != null)
        onTapCancel();
      _reset();
    }
  }

  void _check() {
    if (_wonArena && _finalPosition != null) {
      resolve(GestureDisposition.accepted);
      if (onTapUp != null)
        onTapUp(_finalPosition);
      if (onTap != null)
        onTap();
      _reset();
    }
  }

  void _reset() {
    _wonArena = false;
    _finalPosition = null;
  }
}

/// TapTracker helps track individual tap sequences as part of a
/// larger gesture.
class _TapTracker {

  _TapTracker({ PointerInputEvent event, this.entry })
    : pointer = event.pointer,
      _initialPosition = event.position,
      _isTrackingPointer = false {
    assert(event.type == 'pointerdown');
  }

  final int pointer;
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

enum _TapResolution {
  tap,
  cancel
}

/// TapGesture represents a full gesture resulting from a single tap
/// sequence. Tap gestures are passive, meaning that they will not
/// pre-empt any other arena member in play.
class _TapGesture extends _TapTracker {

  _TapGesture({ this.gestureRecognizer, PointerInputEvent event })
      : super(event: event) {
    entry = GestureArena.instance.add(event.pointer, gestureRecognizer);
    startTrackingPointer(gestureRecognizer.router, handleEvent);
  }

  final MultiTapGestureRecognizer gestureRecognizer;

  bool _wonArena = false;
  ui.Point _finalPosition;

  void handleEvent(PointerInputEvent event) {
    assert(event.pointer == pointer);
    if (event.type == 'pointermove' && !isWithinTolerance(event, kTouchSlop)) {
      cancel();
    } else if (event.type == 'pointercancel') {
      cancel();
    } else if (event.type == 'pointerup') {
      stopTrackingPointer(gestureRecognizer.router, handleEvent);
      _finalPosition = event.position;
      _check();
    }
  }

  void accept() {
    _wonArena = true;
    _check();
  }

  void reject() {
    stopTrackingPointer(gestureRecognizer.router, handleEvent);
    gestureRecognizer._resolveTap(pointer, _TapResolution.cancel, null);
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
    if (_wonArena && _finalPosition != null)
      gestureRecognizer._resolveTap(pointer, _TapResolution.tap, _finalPosition);
  }

}

/// MultiTapGestureRecognizer is a tap recognizer that treats taps
/// independently. That is, each pointer sequence that could resolve to a tap
/// does so independently of others: down-1, down-2, up-1, up-2 produces two
/// taps, on up-1 and up-2.
class MultiTapGestureRecognizer extends DisposableArenaMember {
  MultiTapGestureRecognizer({
    this.router,
    this.onTapDown,
    this.onTapUp,
    this.onTap,
    this.onTapCancel
  });

  PointerRouter router;
  GestureTapDownCallback onTapDown;
  GestureTapDownCallback onTapUp;
  GestureTapCallback onTap;
  GestureTapCancelCallback onTapCancel;

  Map<int, _TapGesture> _gestureMap = new Map<int, _TapGesture>();

  void addPointer(PointerInputEvent event) {
    assert(!_gestureMap.containsKey(event.pointer));
    _gestureMap[event.pointer] = new _TapGesture(
      gestureRecognizer: this,
      event: event
    );
    if (onTapDown != null)
      onTapDown(event.position);
  }

  void acceptGesture(int pointer) {
    assert(_gestureMap.containsKey(pointer));
    _gestureMap[pointer]?.accept();
  }

  void rejectGesture(int pointer) {
    assert(_gestureMap.containsKey(pointer));
    _gestureMap[pointer]?.reject();
  }

  void _resolveTap(int pointer, _TapResolution resolution, ui.Point globalPosition) {
    _gestureMap.remove(pointer);
    if (resolution == _TapResolution.tap) {
      if (onTapUp != null)
        onTapUp(globalPosition);
      if (onTap != null)
        onTap();
    } else {
      if (onTapCancel != null)
        onTapCancel();
    }
  }

  void dispose() {
    List<_TapGesture> localGestures = new List<_TapGesture>.from(_gestureMap.values);
    for (_TapGesture gesture in localGestures)
      gesture.cancel();
    // Rejection of each gesture should cause it to be removed from our map
    assert(_gestureMap.isEmpty);
    router = null;
  }

}

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
  _TapTracker _firstTap;
  final Map<int, _TapTracker> _trackers = new Map<int, _TapTracker>();

  void addPointer(PointerInputEvent event) {
    // Ignore out-of-bounds second taps
    if (_firstTap != null &&
        !_firstTap.isWithinTolerance(event, kDoubleTapTouchSlop))
      return;
    _stopDoubleTapTimer();
    _TapTracker tracker = new _TapTracker(
      event: event,
      entry: GestureArena.instance.add(event.pointer, this)
    );
    _trackers[event.pointer] = tracker;
    tracker.startTrackingPointer(router, handleEvent);
  }

  void handleEvent(PointerInputEvent event) {
    _TapTracker tracker = _trackers[event.pointer];
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
    _TapTracker tracker = _trackers[pointer];
    // If tracker isn't in the list, check if this is the first tap tracker
    if (tracker == null &&
        _firstTap != null &&
        _firstTap.pointer == pointer)
      tracker = _firstTap;
    // If tracker is still null, we rejected ourselves already
    if (tracker != null)
      _reject(tracker);
  }

  void _reject(_TapTracker tracker) {
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
      _TapTracker tracker = _firstTap;
      _firstTap = null;
      _reject(tracker);
      GestureArena.instance.release(tracker.pointer);
    }
    _clearTrackers();
  }

  void _registerFirstTap(_TapTracker tracker) {
    _startDoubleTapTimer();
    GestureArena.instance.hold(tracker.pointer);
    // Note, order is important below in order for the clear -> reject logic to
    // work properly.
    _freezeTracker(tracker);
    _trackers.remove(tracker.pointer);
    _clearTrackers();
    _firstTap = tracker;
  }

  void _registerSecondTap(_TapTracker tracker) {
    _firstTap.entry.resolve(GestureDisposition.accepted);
    tracker.entry.resolve(GestureDisposition.accepted);
    _freezeTracker(tracker);
    _trackers.remove(tracker.pointer);
    if (onDoubleTap != null)
      onDoubleTap();
    _reset();
  }

  void _clearTrackers() {
    List<_TapTracker> localTrackers = new List<_TapTracker>.from(_trackers.values);
    for (_TapTracker tracker in localTrackers)
      _reject(tracker);
    assert(_trackers.isEmpty);
  }

  void _freezeTracker(_TapTracker tracker) {
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
