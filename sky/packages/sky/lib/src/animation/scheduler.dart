// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection';
import 'dart:ui' as ui;

/// Slows down animations by this factor to help in development.
double timeDilation = 1.0;

/// A callback from the scheduler
///
/// The timeStamp is the number of milliseconds since the beginning of the
/// scheduler's epoch. Use timeStamp to determine how far to advance animation
/// timelines so that all the animations in the system are synchronized to a
/// common time base.
typedef void SchedulerCallback(Duration timeStamp);

/// Schedules callbacks to run in concert with the engine's animation system
class Scheduler {
  /// Requires clients to use the [scheduler] singleton
  Scheduler._() {
    ui.view.setFrameCallback(beginFrame);
  }

  bool _haveScheduledVisualUpdate = false;
  int _nextCallbackId = 1;

  final List<SchedulerCallback> _persistentCallbacks = new List<SchedulerCallback>();
  Map<int, SchedulerCallback> _transientCallbacks = new LinkedHashMap<int, SchedulerCallback>();
  final Set<int> _removedIds = new Set<int>();

  int get transientCallbackCount => _transientCallbacks.length;

  /// Called by the engine to produce a new frame.
  ///
  /// This function first calls all the callbacks registered by
  /// [requestAnimationFrame] and then calls all the callbacks registered by
  /// [addPersistentFrameCallback], which typically drive the rendering pipeline.
  void beginFrame(double timeStampMS) {
    timeStampMS /= timeDilation;

    Duration timeStamp = new Duration(microseconds: (timeStampMS * Duration.MICROSECONDS_PER_MILLISECOND).round());

    _haveScheduledVisualUpdate = false;

    Map<int, SchedulerCallback> callbacks = _transientCallbacks;
    _transientCallbacks = new Map<int, SchedulerCallback>();

    callbacks.forEach((int id, SchedulerCallback callback) {
      if (!_removedIds.contains(id))
        callback(timeStamp);
    });
    _removedIds.clear();

    for (SchedulerCallback callback in _persistentCallbacks)
      callback(timeStamp);
  }

  /// Call callback every frame.
  void addPersistentFrameCallback(SchedulerCallback callback) {
    _persistentCallbacks.add(callback);
  }

  /// Schedule a callback for the next frame.
  ///
  /// The callback will be run prior to flushing the main rendering pipeline.
  /// Typically, requestAnimationFrame is used to throttle writes into the
  /// rendering pipeline until the system is ready to accept a new frame. For
  /// example, if you wanted to tick through an animation, you should use
  /// requestAnimation frame to determine when to tick the animation. The callback
  /// is passed a timeStamp that you can use to determine how far along the
  /// timeline to advance your animation.
  ///
  /// Returns an id that can be used to unschedule this callback.
  int requestAnimationFrame(SchedulerCallback callback) {
    int id = _nextCallbackId++;
    _transientCallbacks[id] = callback;
    ensureVisualUpdate();
    return id;
  }

  /// Cancel the callback identified by id.
  void cancelAnimationFrame(int id) {
    _transientCallbacks.remove(id);
    _removedIds.add(id);
  }

  /// Ensure that a frame will be produced after this function is called.
  void ensureVisualUpdate() {
    if (_haveScheduledVisualUpdate)
      return;
    ui.view.scheduleFrame();
    _haveScheduledVisualUpdate = true;
  }
}

/// A singleton instance of Scheduler to coordinate all the callbacks.
final Scheduler scheduler = new Scheduler._();
