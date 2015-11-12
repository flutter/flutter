// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:collection/priority_queue.dart';
import 'package:flutter/animation.dart' as animation show scheduler;

typedef Task();

/// An entry in the scheduler's priority queue.
///
/// Combines the task and its priority.
class _SchedulerEntry {
  final Task task;
  final int priority;

  _SchedulerEntry(this.task, this.priority);
}

class Priority {
  static const kIdle = const Priority._(0);
  static const kAnimation = const Priority._(100000);
  static const kTouch = const Priority._(200000);

  /// Relative priorities are clamped by this offset.
  ///
  /// It is still possible to have priorities that are offset by more than this
  /// amount by repeatedly taking relative offsets, but that's generally
  /// discouraged.
  static const kMaxOffset = 10000;

  final int _value;

  int get value => _value;

  const Priority._(this._value);

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
class TaskScheduler {
  final PriorityQueue _queue = new HeapPriorityQueue<_SchedulerEntry>(
    (_SchedulerEntry e1, _SchedulerEntry e2) {
      // Note that we inverse the priority.
      return -e1.priority.compareTo(e2.priority);
    });

  SchedulingStrategy schedulingStrategy = new SchedulingStrategy();

  /// Wether this scheduler already requested to be woken up as soon as
  /// possible.
  bool _wakingNow = false;
  /// Wether this scheduler already requested to be woken up in the next frame.
  bool _wakingNextFrame = false;

  TaskScheduler._();

  /// Schedules the given [task] with the given [priority].
  // TODO(floitsch): provide some means to indicate how long things are going
  // to take?
  // TODO(floitsch): guidance on how to increase priority over time?
  void schedule(Task task, Priority priority) {
    bool isFirstTask = _queue.isEmpty;
    _queue.add(new _SchedulerEntry(task, priority._value));
    if (isFirstTask) _wakeNow();
  }

  /// Invoked by the system when there is time to run tasks.
  void tick() {
    if (_queue.isEmpty) return;
    _SchedulerEntry entry = _queue.first;
    if (schedulingStrategy.shouldRunTaskWithPriority(entry.priority)) {
      try {
        (_queue.removeFirst().task)();
      } finally {
        if (_queue.isNotEmpty) {
          _wakeNow();
        }
      }
    } else {
      _wakeNextFrame();
    }
  }

  /// Tells the system that the scheduler is awake and should be called as
  /// soon a there is time.
  void _wakeNow() {
    if (_wakingNow) return;
    _wakingNow = true;
    Timer.run(() {
      _wakingNow = false;
      tick();
    });
  }

  /// Tells the system that the scheduler needs to run again (ideally next
  /// frame).
  void _wakeNextFrame() {
    if (_wakingNextFrame) return;
    _wakingNextFrame = true;
    animation.scheduler.requestAnimationFrame((_) {
      _wakingNextFrame = false;
      // RequestAnimationFrame calls back at the beginning of a frame. We want
      // to run in the idle-phase of an animation. We therefore request to be
      // woken up as soon as possible.
      _wakeNow();
    });
  }
}

final TaskScheduler tasks = new TaskScheduler._();

class SchedulingStrategy {
  // TODO(floitsch): for now we only expose the priority. It might be
  // interesting to provide more info (like, how long the task ran the last
  // time).
  bool shouldRunTaskWithPriority(int priority) {
    if (animation.scheduler.transientCallbackCount > 0) {
      return priority >= Priority.kAnimation._value;
    }
    return true;
  }
}
