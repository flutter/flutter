// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:collection';
import 'dart:developer';
import 'dart:ui' as ui show window;
import 'dart:ui' show VoidCallback;

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';

import 'priority.dart';

export 'dart:ui' show VoidCallback;

/// Slows down animations by this factor to help in development.
double timeDilation = 1.0;

/// A frame-related callback from the scheduler.
///
/// The timeStamp is the number of milliseconds since the beginning of the
/// scheduler's epoch. Use timeStamp to determine how far to advance animation
/// timelines so that all the animations in the system are synchronized to a
/// common time base.
typedef void FrameCallback(Duration timeStamp);

/// Signature for the [SchedulerBinding.schedulingStrategy] callback. Invoked
/// whenever the system needs to decide whether a task at a given
/// priority needs to be run.
///
/// Return true if a task with the given priority should be executed
/// at this time, false otherwise.
///
/// See also [defaultSchedulingStrategy].
typedef bool SchedulingStrategy({ int priority, SchedulerBinding scheduler });

class _TaskEntry {
  const _TaskEntry(this.task, this.priority);
  final VoidCallback task;
  final int priority;
}

class _FrameCallbackEntry {
  _FrameCallbackEntry(this.callback, { bool rescheduling: false }) {
    assert(() {
      if (rescheduling) {
        assert(currentCallbackStack != null);
        stack = currentCallbackStack;
      } else {
        stack = StackTrace.current;
      }
      return true;
    });
  }
  static StackTrace currentCallbackStack;
  final FrameCallback callback;
  StackTrace stack;
}

/// Scheduler for running the following:
///
/// * _Frame callbacks_, triggered by the system's
///   [ui.window.onBeginFrame] callback, for synchronising the
///   application's behavior to the system's display. For example, the
///   rendering layer uses this to drive its rendering pipeline.
///
/// * Non-rendering tasks, to be run between frames. These are given a
///   priority and are executed in priority order according to a
///   [schedulingStrategy].
abstract class SchedulerBinding extends BindingBase {

  @override
  void initInstances() {
    super.initInstances();
    _instance = this;
    ui.window.onBeginFrame = handleBeginFrame;
  }

  /// The current [SchedulerBinding], if one has been created.
  static SchedulerBinding get instance => _instance;
  static SchedulerBinding _instance;

  @override
  void initServiceExtensions() {
    super.initServiceExtensions();
    registerNumericServiceExtension(
      name: 'timeDilation', 
      getter: () => timeDilation,
      setter: (double value) {
        timeDilation = value;
      }
    );
  }


  /// The strategy to use when deciding whether to run a task or not.
  /// 
  /// Defaults to [defaultSchedulingStrategy].
  SchedulingStrategy schedulingStrategy = defaultSchedulingStrategy;

  static int _taskSorter (_TaskEntry e1, _TaskEntry e2) {
    return -e1.priority.compareTo(e2.priority);
  }
  final PriorityQueue<_TaskEntry> _taskQueue = new HeapPriorityQueue<_TaskEntry>(_taskSorter);

  /// Schedules the given `task` with the given `priority`.
  ///
  /// Tasks will be executed between frames, in priority order,
  /// excluding tasks that are skipped by the current
  /// [schedulingStrategy]. Tasks should be short (as in, up to a
  /// millisecond), so as to not cause the regular frame callbacks to
  /// get delayed.
  void scheduleTask(VoidCallback task, Priority priority) {
    bool isFirstTask = _taskQueue.isEmpty;
    _taskQueue.add(new _TaskEntry(task, priority.value));
    if (isFirstTask)
      _ensureEventLoopCallback();
  }


  // Whether this scheduler already requested to be called from the event loop.
  bool _hasRequestedAnEventLoopCallback = false;

  // Ensures that the scheduler is awakened by the event loop.
  void _ensureEventLoopCallback() {
    if (_hasRequestedAnEventLoopCallback)
      return;
    Timer.run(handleEventLoopCallback);
    _hasRequestedAnEventLoopCallback = true;
  }

  /// Invoked by the system when there is time to run tasks.
  void handleEventLoopCallback() {
    _hasRequestedAnEventLoopCallback = false;
    _runTasks();
  }

  // Called when the system wakes up and at the end of each frame.
  void _runTasks() {
    if (_taskQueue.isEmpty)
      return;
    _TaskEntry entry = _taskQueue.first;
    // TODO(floitsch): for now we only expose the priority. It might
    // be interesting to provide more info (like, how long the task
    // ran the last time, or how long is left in this frame).
    if (schedulingStrategy(priority: entry.priority, scheduler: this)) {
      try {
        (_taskQueue.removeFirst().task)();
      } finally {
        if (_taskQueue.isNotEmpty)
          _ensureEventLoopCallback();
      }
    } else {
      // TODO(floitsch): we shouldn't need to request a frame. Just schedule
      // an event-loop callback.
      ensureVisualUpdate();
    }
  }


  int _nextFrameCallbackId = 0; // positive
  Map<int, _FrameCallbackEntry> _transientCallbacks = <int, _FrameCallbackEntry>{};
  final Set<int> _removedIds = new HashSet<int>();

  /// The current number of transient frame callbacks scheduled.
  ///
  /// This is reset to zero just before all the currently scheduled
  /// transient callbacks are invoked, at the start of a frame.
  ///
  /// This number is primarily exposed so that tests can verify that
  /// there are no unexpected transient callbacks still registered
  /// after a test's resources have been gracefully disposed.
  int get transientCallbackCount => _transientCallbacks.length;

  /// Schedules the given frame callback.
  ///
  /// Adds the given callback to the list of frame callbacks and ensures that a
  /// frame is scheduled.
  ///
  /// If `rescheduling` is true, the call must be in the context of a
  /// frame callback, and for debugging purposes the stack trace
  /// stored for this callback will be the same stack trace as for the
  /// current callback.
  ///
  /// Callbacks registered with this method can be canceled using
  /// [cancelFrameCallbackWithId].
  int scheduleFrameCallback(FrameCallback callback, { bool rescheduling: false }) {
    ensureVisualUpdate();
    return addFrameCallback(callback, rescheduling: rescheduling);
  }

  /// Adds a frame callback.
  ///
  /// Frame callbacks are executed at the beginning of a frame (see
  /// [handleBeginFrame]).
  ///
  /// These callbacks are executed in the order in which they have
  /// been added.
  ///
  /// Callbacks registered with this method will not be invoked until
  /// a frame is requested. To register a callback and ensure that a
  /// frame is immediately scheduled, use [scheduleFrameCallback].
  ///
  /// If `rescheduling` is true, the call must be in the context of a
  /// frame callback, and for debugging purposes the stack trace
  /// stored for this callback will be the same stack trace as for the
  /// current callback.
  ///
  /// Callbacks registered with this method can be canceled using
  /// [cancelFrameCallbackWithId].
  int addFrameCallback(FrameCallback callback, { bool rescheduling: false }) {
    _nextFrameCallbackId += 1;
    _transientCallbacks[_nextFrameCallbackId] = new _FrameCallbackEntry(callback, rescheduling: rescheduling);
    return _nextFrameCallbackId;
  }

  /// Cancels the callback of the given [id].
  ///
  /// Removes the given callback from the list of frame callbacks. If a frame
  /// has been requested, this does not also cancel that request.
  ///
  /// Frame callbacks are registered using [scheduleFrameCallback] or
  /// [addFrameCallback].
  void cancelFrameCallbackWithId(int id) {
    assert(id > 0);
    _transientCallbacks.remove(id);
    _removedIds.add(id);
  }

  /// Asserts that there are no registered transient callbacks; if
  /// there are, prints their locations and throws an exception.
  ///
  /// This is expected to be called at the end of tests (the
  /// flutter_test framework does it automatically in normal cases).
  ///
  /// Invoke this method when you expect there to be no transient
  /// callbacks registered, in an assert statement with a message that
  /// you want printed when a transient callback is registered:
  ///
  /// ```dart
  /// assert(SchedulerBinding.instance.debugAssertNoTransientCallbacks(
  ///   'A leak of transient callbacks was detected while doing foo.'
  /// ));
  /// ```
  ///
  /// Does nothing if asserts are disabled. Always returns true.
  bool debugAssertNoTransientCallbacks(String reason) {
    assert(() {
      if (transientCallbackCount > 0) {
        FlutterError.reportError(new FlutterErrorDetails(
          exception: reason,
          library: 'scheduler library',
          informationCollector: (StringBuffer information) {
            information.writeln(
              'There ${ transientCallbackCount == 1 ? "was one transient callback" : "were $transientCallbackCount transient callbacks" } '
              'left. The stack traces for when they were registered are as follows:'
            );
            for (int id in _transientCallbacks.keys) {
              _FrameCallbackEntry entry = _transientCallbacks[id];
              information.writeln('-- callback $id --');
              information.writeln(entry.stack);
            }
          }
        ));
      }
      return true;
    });
    return true;
  }


  final List<FrameCallback> _persistentCallbacks = new List<FrameCallback>();

  /// Adds a persistent frame callback.
  ///
  /// Persistent callbacks are invoked after transient
  /// (non-persistent) frame callbacks.
  ///
  /// Does *not* request a new frame. Conceptually, persistent frame
  /// callbacks are observers of "begin frame" events. Since they are
  /// executed after the transient frame callbacks they can drive the
  /// rendering pipeline.
  void addPersistentFrameCallback(FrameCallback callback) {
    _persistentCallbacks.add(callback);
  }


  final List<FrameCallback> _postFrameCallbacks = new List<FrameCallback>();

  /// Schedule a callback for the end of this frame.
  ///
  /// Does *not* request a new frame.
  ///
  /// This callback is run during a frame, just after the persistent
  /// frame callbacks (which is when the main rendering pipeline has
  /// been flushed). If a frame is in progress and post-frame
  /// callbacks haven't been executed yet, then the registered
  /// callback is still executed during the frame. Otherwise, the
  /// registered callback is executed during the next frame.
  ///
  /// The callbacks are executed in the order in which they have been
  /// added.
  void addPostFrameCallback(FrameCallback callback) {
    _postFrameCallbacks.add(callback);
  }


  // Whether this scheduler already requested to be called at the beginning of
  // the next frame.
  bool _hasRequestedABeginFrameCallback = false;

  /// If necessary, schedules a new frame by calling
  /// [ui.window.scheduleFrame].
  ///
  /// After this is called, the engine will (eventually) invoke
  /// [handleBeginFrame]. (This call might be delayed, e.g. if the
  /// device's screen is turned off it will typically be delayed until
  /// the screen is on and the application is visible.)
  void ensureVisualUpdate() {
    if (_hasRequestedABeginFrameCallback)
      return;
    ui.window.scheduleFrame();
    _hasRequestedABeginFrameCallback = true;
  }

  /// Whether the scheduler is currently handling a "begin frame"
  /// callback.
  ///
  /// True while [handleBeginFrame] is running in checked mode. False
  /// otherwise.
  static bool get debugInFrame => _debugInFrame;
  static bool _debugInFrame = false;

  /// Called by the engine to produce a new frame.
  ///
  /// This function first calls all the callbacks registered by
  /// [scheduleFrameCallback]/[addFrameCallback], then calls all the
  /// callbacks registered by [addPersistentFrameCallback], which
  /// typically drive the rendering pipeline, and finally calls the
  /// callbacks registered by [addPostFrameCallback].
  void handleBeginFrame(Duration rawTimeStamp) {
    Timeline.startSync('Frame');
    assert(!_debugInFrame);
    assert(() { _debugInFrame = true; return true; });
    Duration timeStamp = new Duration(
        microseconds: (rawTimeStamp.inMicroseconds / timeDilation).round());
    _hasRequestedABeginFrameCallback = false;
    _invokeTransientFrameCallbacks(timeStamp);

    for (FrameCallback callback in _persistentCallbacks)
      _invokeFrameCallback(callback, timeStamp);

    List<FrameCallback> localPostFrameCallbacks =
        new List<FrameCallback>.from(_postFrameCallbacks);
    _postFrameCallbacks.clear();
    for (FrameCallback callback in localPostFrameCallbacks)
      _invokeFrameCallback(callback, timeStamp);

    assert(() { _debugInFrame = false; return true; });
    Timeline.finishSync();

    // All frame-related callbacks have been executed. Run lower-priority tasks.
    _runTasks();
  }

  void _invokeTransientFrameCallbacks(Duration timeStamp) {
    Timeline.startSync('Animate');
    assert(_debugInFrame);
    Map<int, _FrameCallbackEntry> callbacks = _transientCallbacks;
    _transientCallbacks = new Map<int, _FrameCallbackEntry>();
    callbacks.forEach((int id, _FrameCallbackEntry callbackEntry) {
      if (!_removedIds.contains(id))
        _invokeFrameCallback(callbackEntry.callback, timeStamp, callbackEntry.stack);
    });
    _removedIds.clear();
    Timeline.finishSync();
  }

  // Invokes the given [callback] with [timestamp] as argument.
  //
  // Wraps the callback in a try/catch and forwards any error to
  // [debugSchedulerExceptionHandler], if set. If not set, then simply prints
  // the error.
  void _invokeFrameCallback(FrameCallback callback, Duration timeStamp, [ StackTrace callbackStack ]) {
    assert(callback != null);
    assert(_FrameCallbackEntry.currentCallbackStack == null);
    assert(() { _FrameCallbackEntry.currentCallbackStack = callbackStack; return true; });
    try {
      callback(timeStamp);
    } catch (exception, exceptionStack) {
      FlutterError.reportError(new FlutterErrorDetails(
        exception: exception,
        stack: exceptionStack,
        library: 'scheduler library',
        context: 'during a scheduler callback',
        informationCollector: (callbackStack == null) ? null : (StringBuffer information) {
          information.writeln('When this callback was registered, this was the stack:\n$callbackStack');
        }
      ));
    }
    assert(() { _FrameCallbackEntry.currentCallbackStack = null; return true; });
  }
}

/// The default [SchedulingStrategy] for [SchedulerBinding.schedulingStrategy].
///
/// If there are any frame callbacks registered, only runs tasks with
/// a [Priority] of [Priority.animation] or higher. Otherwise, runs
/// all tasks.
bool defaultSchedulingStrategy({ int priority, SchedulerBinding scheduler }) {
  if (scheduler.transientCallbackCount > 0)
    return priority >= Priority.animation.value;
  return true;
}
