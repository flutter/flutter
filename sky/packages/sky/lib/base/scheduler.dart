// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection';
import 'dart:sky' as sky;

import 'package:sky/base/debug.dart';

/// A callback from the scheduler
///
/// The timeStamp is the number of milliseconds since the beginning of the
/// scheduler's epoch. Use timeStamp to determine how far to advance animation
/// timelines so that all the animations in the system are synchronized to a
/// common time base.
typedef void SchedulerCallback(double timeStamp);

bool _haveScheduledVisualUpdate = false;
int _nextCallbackId = 1;

final List<SchedulerCallback> _persistentCallbacks = new List<SchedulerCallback>();
Map<int, SchedulerCallback> _transientCallbacks = new LinkedHashMap<int, SchedulerCallback>();
final Set<int> _removedIds = new Set<int>();

/// Called by the engine to produce a new frame.
///
/// This function first calls all the callbacks registered by
/// [requestAnimationFrame] and then calls all the callbacks registered by
/// [addPersistentFrameCallback], which typically drive the rendering pipeline.
void beginFrame(double timeStamp) {
  timeStamp /= timeDilation;

  _haveScheduledVisualUpdate = false;

  Map<int, SchedulerCallback> callbacks = _transientCallbacks;
  _transientCallbacks = new Map<int, SchedulerCallback>();

  callbacks.forEach((id, callback) {
    if (!_removedIds.contains(id))
      callback(timeStamp);
  });
  _removedIds.clear();

  for (SchedulerCallback callback in _persistentCallbacks)
    callback(timeStamp);
}

/// Registers [beginFrame] callback with the engine.
void init() {
  sky.view.setFrameCallback(beginFrame);
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
  sky.view.scheduleFrame();
  _haveScheduledVisualUpdate = true;
}
