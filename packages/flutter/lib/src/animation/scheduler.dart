// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection';
import 'dart:developer';
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

typedef void SchedulerExceptionHandler(dynamic exception, StackTrace stack);
/// This callback is invoked whenever an exception is caught by the scheduler.
/// The 'exception' argument contains the object that was thrown, and the
/// 'stack' argument contains the stack trace. If the callback is set, it is
/// invoked instead of printing the information to the console.
SchedulerExceptionHandler debugSchedulerExceptionHandler;

/// Schedules callbacks to run in concert with the engine's animation system
class Scheduler {
  /// Requires clients to use the [scheduler] singleton
  Scheduler._() {
    ui.window.onBeginFrame = beginFrame;
  }

  bool _haveScheduledVisualUpdate = false;
  int _nextCallbackId = 0; // positive

  final List<SchedulerCallback> _persistentCallbacks = new List<SchedulerCallback>();
  Map<int, SchedulerCallback> _transientCallbacks = new LinkedHashMap<int, SchedulerCallback>();
  final Set<int> _removedIds = new Set<int>();
  final List<SchedulerCallback> _postFrameCallbacks = new List<SchedulerCallback>();

  bool _inFrame = false;

  int get transientCallbackCount => _transientCallbacks.length;

  void _invokeAnimationCallbacks(Duration timeStamp) {
    Timeline.startSync('Animate');
    assert(_inFrame);
    Map<int, SchedulerCallback> callbacks = _transientCallbacks;
    _transientCallbacks = new Map<int, SchedulerCallback>();
    callbacks.forEach((int id, SchedulerCallback callback) {
      if (!_removedIds.contains(id))
        invokeCallback(callback, timeStamp);
    });
    _removedIds.clear();
    Timeline.finishSync();
  }

  /// Called by the engine to produce a new frame.
  ///
  /// This function first calls all the callbacks registered by
  /// [requestAnimationFrame], then calls all the callbacks registered by
  /// [addPersistentFrameCallback], which typically drive the rendering pipeline,
  /// and finally calls the callbacks registered by [requestPostFrameCallback].
  void beginFrame(Duration rawTimeStamp) {
    Timeline.startSync('Begin frame');
    assert(!_inFrame);
    _inFrame = true;
    Duration timeStamp = new Duration(
        microseconds: (rawTimeStamp.inMicroseconds / timeDilation).round());
    _haveScheduledVisualUpdate = false;
    _invokeAnimationCallbacks(timeStamp);

    for (SchedulerCallback callback in _persistentCallbacks)
      invokeCallback(callback, timeStamp);

    List<SchedulerCallback> localPostFrameCallbacks =
        new List<SchedulerCallback>.from(_postFrameCallbacks);
    _postFrameCallbacks.clear();
    for (SchedulerCallback callback in localPostFrameCallbacks)
      invokeCallback(callback, timeStamp);

    _inFrame = false;
    Timeline.finishSync();
  }

  void invokeCallback(SchedulerCallback callback, Duration timeStamp) {
    assert(callback != null);
    try {
      callback(timeStamp);
    } catch (exception, stack) {
      if (debugSchedulerExceptionHandler != null) {
        debugSchedulerExceptionHandler(exception, stack);
      } else {
        print('-- EXCEPTION IN SCHEDULER CALLBACK --');
        print('$exception');
        print('Stack trace:');
        print('$stack');
      }
    }
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
  /// Callbacks in invoked in an arbitrary order.
  ///
  /// Returns an id that can be used to unschedule this callback.
  int requestAnimationFrame(SchedulerCallback callback) {
    _nextCallbackId += 1;
    _transientCallbacks[_nextCallbackId] = callback;
    ensureVisualUpdate();
    return _nextCallbackId;
  }

  /// Cancel the callback identified by id.
  void cancelAnimationFrame(int id) {
    assert(id > 0);
    _transientCallbacks.remove(id);
    _removedIds.add(id);
  }

  /// Schedule a callback for the end of this frame.
  ///
  /// If a frame is in progress, the callback will be run just after the main
  /// rendering pipeline has been flushed. In this case, order is preserved (the
  /// callbacks are run in registration order).
  ///
  /// If no frame is in progress, it will be called at the start of the next
  /// frame. In this case, the registration order is not preserved. Callbacks
  /// are called in an arbitrary order.
  void requestPostFrameCallback(SchedulerCallback callback) {
    _postFrameCallbacks.add(callback);
  }

  /// Ensure that a frame will be produced after this function is called.
  void ensureVisualUpdate() {
    if (_haveScheduledVisualUpdate)
      return;
    ui.window.scheduleFrame();
    _haveScheduledVisualUpdate = true;
  }
}

/// A singleton instance of Scheduler to coordinate all the callbacks.
final Scheduler scheduler = new Scheduler._();
