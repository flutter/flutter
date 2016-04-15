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

typedef bool SchedulingStrategy({ int priority, Scheduler scheduler });

/// An entry in the scheduler's priority queue.
///
/// Combines the task and its priority.
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

class Priority {
  static const Priority idle = const Priority._(0);
  static const Priority animation = const Priority._(100000);
  static const Priority touch = const Priority._(200000);

  /// Relative priorities are clamped by this offset.
  ///
  /// It is still possible to have priorities that are offset by more than this
  /// amount by repeatedly taking relative offsets, but that's generally
  /// discouraged.
  static const int kMaxOffset = 10000;

  const Priority._(this._value);

  int get value => _value;
  final int _value;

  /// Returns a priority relative to this priority.
  ///
  /// A positive [offset] indicates a higher priority.
  ///
  /// The parameter [offset] is clamped to +/-[kMaxOffset].
  Priority operator +(int offset) {
    if (offset.abs() > kMaxOffset) {
      // Clamp the input offset.
      offset = kMaxOffset * offset.sign;
    }
    return new Priority._(_value + offset);
  }

  /// Returns a priority relative to this priority.
  ///
  /// A positive offset indicates a lower priority.
  ///
  /// The parameter [offset] is clamped to +/-[kMaxOffset].
  Priority operator -(int offset) => this + (-offset);
}

/// Scheduler running tasks with specific priorities.
///
/// Combines the task's priority with remaining time in a frame to decide when
/// the task should be run.
///
/// Tasks always run in the idle time after a frame has been committed.
abstract class Scheduler extends BindingBase {
  /// Requires clients to use the [scheduler] singleton

  @override
  void initInstances() {
    super.initInstances();
    _instance = this;
    ui.window.onBeginFrame = handleBeginFrame;
  }

  static Scheduler _instance;
  static Scheduler get instance => _instance;

  SchedulingStrategy schedulingStrategy = defaultSchedulingStrategy;

  static int _taskSorter (_TaskEntry e1, _TaskEntry e2) {
    // Note that we inverse the priority.
    return -e1.priority.compareTo(e2.priority);
  }
  final PriorityQueue<_TaskEntry> _taskQueue = new HeapPriorityQueue<_TaskEntry>(_taskSorter);

  /// Whether this scheduler already requested to be called from the event loop.
  bool _hasRequestedAnEventLoopCallback = false;

  /// Whether this scheduler already requested to be called at the beginning of
  /// the next frame.
  bool _hasRequestedABeginFrameCallback = false;

  /// Schedules the given [task] with the given [priority].
  void scheduleTask(VoidCallback task, Priority priority) {
    bool isFirstTask = _taskQueue.isEmpty;
    _taskQueue.add(new _TaskEntry(task, priority._value));
    if (isFirstTask)
      _ensureEventLoopCallback();
  }

  /// Invoked by the system when there is time to run tasks.
  void handleEventLoopCallback() {
    _hasRequestedAnEventLoopCallback = false;
    _runTasks();
  }

  void _runTasks() {
    if (_taskQueue.isEmpty)
      return;
    _TaskEntry entry = _taskQueue.first;
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
      _ensureBeginFrameCallback();
    }
  }

  int _nextFrameCallbackId = 0; // positive
  Map<int, _FrameCallbackEntry> _transientCallbacks = <int, _FrameCallbackEntry>{};
  final Set<int> _removedIds = new HashSet<int>();

  int get transientCallbackCount => _transientCallbacks.length;

  /// Schedules the given frame callback.
  ///
  /// Adds the given callback to the list of frame-callbacks and ensures that a
  /// frame is scheduled.
  ///
  /// If `rescheduling` is true, the call must be in the context of a
  /// frame callback, and for debugging purposes the stack trace
  /// stored for this callback will be the same stack trace as for the
  /// current callback.
  int scheduleFrameCallback(FrameCallback callback, { bool rescheduling: false }) {
    _ensureBeginFrameCallback();
    return addFrameCallback(callback, rescheduling: rescheduling);
  }

  /// Adds a frame callback.
  ///
  /// Frame callbacks are executed at the beginning of a frame (see
  /// [handleBeginFrame]).
  ///
  /// The registered callbacks are executed in the order in which they have been
  /// registered.
  ///
  /// Callbacks registered with this method will not be invoked until
  /// a frame is requested. To register a callback and ensure that a
  /// frame is immediately scheduled, use [scheduleFrameCallback].
  ///
  /// If `rescheduling` is true, the call must be in the context of a
  /// frame callback, and for debugging purposes the stack trace
  /// stored for this callback will be the same stack trace as for the
  /// current callback.
  int addFrameCallback(FrameCallback callback, { bool rescheduling: false }) {
    _nextFrameCallbackId += 1;
    _transientCallbacks[_nextFrameCallbackId] = new _FrameCallbackEntry(callback, rescheduling: rescheduling);
    return _nextFrameCallbackId;
  }

  /// Cancels the callback of the given [id].
  ///
  /// Removes the given callback from the list of frame callbacks. If a frame
  /// has been requested does *not* cancel that request.
  void cancelFrameCallbackWithId(int id) {
    assert(id > 0);
    _transientCallbacks.remove(id);
    _removedIds.add(id);
  }

  final List<FrameCallback> _persistentCallbacks = new List<FrameCallback>();

  /// Adds a persistent frame callback.
  ///
  /// Persistent callbacks are invoked after transient (non-persistent) frame
  /// callbacks.
  ///
  /// Does *not* request a new frame. Conceptually, persistent
  /// frame-callbacks are thus observers of begin-frame events. Since they are
  /// executed after the transient frame-callbacks they can drive the rendering
  /// pipeline.
  void addPersistentFrameCallback(FrameCallback callback) {
    _persistentCallbacks.add(callback);
  }

  final List<FrameCallback> _postFrameCallbacks = new List<FrameCallback>();

  /// Schedule a callback for the end of this frame.
  ///
  /// Does *not* request a new frame.
  ///
  /// The callback is run just after the persistent frame-callbacks (which is
  /// when the main rendering pipeline has been flushed). If a frame is
  /// in progress, but post frame-callbacks haven't been executed yet, then the
  /// registered callback is still executed during the frame. Otherwise,
  /// the registered callback is executed during the next frame.
  ///
  /// The registered callbacks are executed in the order in which they have been
  /// registered.
  void addPostFrameCallback(FrameCallback callback) {
    _postFrameCallbacks.add(callback);
  }

  static bool get debugInFrame => _debugInFrame;
  static bool _debugInFrame = false;

  void _invokeTransientFrameCallbacks(Duration timeStamp) {
    Timeline.startSync('Animate');
    assert(_debugInFrame);
    Map<int, _FrameCallbackEntry> callbacks = _transientCallbacks;
    _transientCallbacks = new Map<int, _FrameCallbackEntry>();
    callbacks.forEach((int id, _FrameCallbackEntry callbackEntry) {
      if (!_removedIds.contains(id))
        invokeFrameCallback(callbackEntry.callback, timeStamp, callbackEntry.stack);
    });
    _removedIds.clear();
    Timeline.finishSync();
  }

  /// Called by the engine to produce a new frame.
  ///
  /// This function first calls all the callbacks registered by
  /// [scheduleFrameCallback]/[addFrameCallback], then calls all the callbacks
  /// registered by [addPersistentFrameCallback], which typically drive the
  /// rendering pipeline, and finally calls the callbacks registered by
  /// [addPostFrameCallback].
  void handleBeginFrame(Duration rawTimeStamp) {
    Timeline.startSync('Begin frame');
    assert(!_debugInFrame);
    assert(() { _debugInFrame = true; return true; });
    Duration timeStamp = new Duration(
        microseconds: (rawTimeStamp.inMicroseconds / timeDilation).round());
    _hasRequestedABeginFrameCallback = false;
    _invokeTransientFrameCallbacks(timeStamp);

    for (FrameCallback callback in _persistentCallbacks)
      invokeFrameCallback(callback, timeStamp);

    List<FrameCallback> localPostFrameCallbacks =
        new List<FrameCallback>.from(_postFrameCallbacks);
    _postFrameCallbacks.clear();
    for (FrameCallback callback in localPostFrameCallbacks)
      invokeFrameCallback(callback, timeStamp);

    assert(() { _debugInFrame = false; return true; });
    Timeline.finishSync();

    // All frame-related callbacks have been executed. Run lower-priority tasks.
    _runTasks();
  }

  /// Invokes the given [callback] with [timestamp] as argument.
  ///
  /// Wraps the callback in a try/catch and forwards any error to
  /// [debugSchedulerExceptionHandler], if set. If not set, then simply prints
  /// the error.
  ///
  /// Must not be called reentrantly from within a frame callback.
  void invokeFrameCallback(FrameCallback callback, Duration timeStamp, [ StackTrace stack ]) {
    assert(callback != null);
    assert(_FrameCallbackEntry.currentCallbackStack == null);
    assert(() { _FrameCallbackEntry.currentCallbackStack = stack; return true; });
    try {
      callback(timeStamp);
    } catch (exception, stack) {
      FlutterError.reportError(new FlutterErrorDetails(
        exception: exception,
        stack: stack,
        library: 'scheduler library',
        context: 'during a scheduler callback',
        informationCollector: (stack == null) ? null : (StringBuffer information) {
          information.writeln('When this callback was registered, this was the stack:\n$stack');
        }
      ));
    }
    assert(() { _FrameCallbackEntry.currentCallbackStack = null; return true; });
  }

  /// Asserts that there are no registered transient callbacks; if
  /// there are, prints their locations and throws an exception.
  ///
  /// This is expected to be called at the end of tests (the
  /// flutter_test framework does it automatically in normal cases).
  ///
  /// To invoke this method, call it, when you expect there to be no
  /// transient callbacks registered, in an assert statement with a
  /// message that you want printed when a transient callback is
  /// registered, as follows:
  ///
  /// ```dart
  /// assert(Scheduler.instance.debugAssertNoTransientCallbacks(
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

  /// Ensures that the scheduler is woken by the event loop.
  void _ensureEventLoopCallback() {
    if (_hasRequestedAnEventLoopCallback)
      return;
    Timer.run(handleEventLoopCallback);
    _hasRequestedAnEventLoopCallback = true;
  }

  // TODO(floitsch): "ensureVisualUpdate" doesn't really fit into the scheduler.
  void ensureVisualUpdate() {
    _ensureBeginFrameCallback();
  }

  /// Schedules a new frame.
  void _ensureBeginFrameCallback() {
    if (_hasRequestedABeginFrameCallback)
      return;
    ui.window.scheduleFrame();
    _hasRequestedABeginFrameCallback = true;
  }
}

// TODO(floitsch): for now we only expose the priority. It might be interesting
// to provide more info (like, how long the task ran the last time).
bool defaultSchedulingStrategy({ int priority, Scheduler scheduler }) {
  if (scheduler.transientCallbackCount > 0)
    return priority >= Priority.animation._value;
  return true;
}
