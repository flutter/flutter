// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:developer';
import 'dart:ui' as ui;

import 'package:collection/priority_queue.dart';

/// Slows down animations by this factor to help in development.
double timeDilation = 1.0;

/// A frame-related callback from the scheduler.
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

/// An entry in the scheduler's priority queue.
///
/// Combines the task and its priority.
class _SchedulerEntry {
  final ui.VoidCallback task;
  final int priority;

  const _SchedulerEntry(this.task, this.priority);
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
class Scheduler {
  /// Requires clients to use the [scheduler] singleton
  Scheduler._() {
    ui.window.onBeginFrame = beginFrame;
  }

  SchedulingStrategy schedulingStrategy = new DefaultSchedulingStrategy();

  final PriorityQueue _queue = new HeapPriorityQueue<_SchedulerEntry>(
    (_SchedulerEntry e1, _SchedulerEntry e2) {
      // Note that we inverse the priority.
      return -e1.priority.compareTo(e2.priority);
    }
  );

  /// Wether this scheduler already requested to be woken up as soon as
  /// possible.
  bool _wakingNow = false;

  /// Wether this scheduler already requested to be woken up in the next frame.
  bool _wakingNextFrame = false;

  /// Schedules the given [task] with the given [priority].
  void scheduleTask(ui.VoidCallback task, Priority priority) {
    bool isFirstTask = _queue.isEmpty;
    _queue.add(new _SchedulerEntry(task, priority._value));
    if (isFirstTask)
      _wakeNow();
  }

  /// Invoked by the system when there is time to run tasks.
  void tick() {
    if (_queue.isEmpty)
      return;
    _SchedulerEntry entry = _queue.first;
    if (schedulingStrategy.shouldRunTaskWithPriority(entry.priority)) {
      try {
        (_queue.removeFirst().task)();
      } finally {
        if (_queue.isNotEmpty)
          _wakeNow();
      }
    } else {
      _wakeNextFrame();
    }
  }

  int _nextFrameCallbackId = 0; // positive
  Map<int, SchedulerCallback> _transientCallbacks = <int, SchedulerCallback>{};
  final Set<int> _removedIds = new Set<int>();

  int get transientCallbackCount => _transientCallbacks.length;

  /// Schedules the given frame callback.
  int requestAnimationFrame(SchedulerCallback callback) {
    _nextFrameCallbackId += 1;
    _transientCallbacks[_nextFrameCallbackId] = callback;
    _wakeNextFrame();
    return _nextFrameCallbackId;
  }

  /// Cancels the callback of the given [id].
  void cancelAnimationFrame(int id) {
    assert(id > 0);
    _transientCallbacks.remove(id);
    _removedIds.add(id);
  }

  final List<SchedulerCallback> _persistentCallbacks = new List<SchedulerCallback>();

  void addPersistentFrameCallback(SchedulerCallback callback) {
    _persistentCallbacks.add(callback);
  }

  final List<SchedulerCallback> _postFrameCallbacks = new List<SchedulerCallback>();

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

  bool _inFrame = false;

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
    _wakingNextFrame = false;
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

    // All frame-related callbacks have been executed. Run lower-priority tasks.
    tick();
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

  /// Tells the system that the scheduler is awake and should be called as
  /// soon a there is time.
  void _wakeNow() {
    if (_wakingNow)
      return;
    _wakingNow = true;
    Timer.run(() {
      _wakingNow = false;
      tick();
    });
  }

  void ensureVisualUpdate() {
    _wakeNextFrame();
  }

  /// Schedules a new frame.
  void _wakeNextFrame() {
    if (_wakingNextFrame)
      return;
    _wakingNextFrame = true;
    ui.window.scheduleFrame();
  }
}

final Scheduler scheduler = new Scheduler._();

abstract class SchedulingStrategy {
  bool shouldRunTaskWithPriority(int priority);
}

class DefaultSchedulingStrategy implements SchedulingStrategy {
  // TODO(floitsch): for now we only expose the priority. It might be
  // interesting to provide more info (like, how long the task ran the last
  // time).
  bool shouldRunTaskWithPriority(int priority) {
    if (scheduler.transientCallbackCount > 0)
      return priority >= Priority.animation._value;
    return true;
  }
}
