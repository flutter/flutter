// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:collection';
import 'dart:developer';
import 'dart:ui' as ui show window;
import 'dart:ui' show AppLifecycleState;

import 'package:collection/collection.dart' show PriorityQueue, HeapPriorityQueue;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'debug.dart';
import 'priority.dart';

export 'dart:ui' show AppLifecycleState, VoidCallback;

/// Slows down animations by this factor to help in development.
double get timeDilation => _timeDilation;
double _timeDilation = 1.0;
/// Setting the time dilation automatically calls [SchedulerBinding.resetEpoch]
/// to ensure that time stamps seen by consumers of the scheduler binding are
/// always increasing.
set timeDilation(double value) {
  assert(value > 0.0);
  if (_timeDilation == value)
    return;
  // We need to resetEpoch first so that we capture start of the epoch with the
  // current time dilation.
  SchedulerBinding.instance?.resetEpoch();
  _timeDilation = value;
}

/// Signature for frame-related callbacks from the scheduler.
///
/// The `timeStamp` is the number of milliseconds since the beginning of the
/// scheduler's epoch. Use timeStamp to determine how far to advance animation
/// timelines so that all the animations in the system are synchronized to a
/// common time base.
typedef void FrameCallback(Duration timeStamp);

/// Signature for [Scheduler.scheduleTask] callbacks.
///
/// The type argument `T` is the task's return value. Consider [void] if the
/// task does not return a value.
typedef T TaskCallback<T>();

/// Signature for the [SchedulerBinding.schedulingStrategy] callback. Called
/// whenever the system needs to decide whether a task at a given
/// priority needs to be run.
///
/// Return true if a task with the given priority should be executed
/// at this time, false otherwise.
///
/// See also [defaultSchedulingStrategy].
typedef bool SchedulingStrategy({ int priority, SchedulerBinding scheduler });

class _TaskEntry<T> {
  _TaskEntry(this.task, this.priority, this.debugLabel, this.flow) {
    // ignore: prefer_asserts_in_initializer_lists
    assert(() {
      debugStack = StackTrace.current;
      return true;
    }());
    completer = new Completer<T>();
  }
  final TaskCallback<T> task;
  final int priority;
  final String debugLabel;
  final Flow flow;

  StackTrace debugStack;
  Completer<T> completer;

  void run() {
    Timeline.timeSync(
      debugLabel ?? 'Scheduled Task',
      () {
        completer.complete(task());
      },
      flow: flow != null ? Flow.step(flow.id) : null,
    );
  }
}

class _FrameCallbackEntry {
  _FrameCallbackEntry(this.callback, { bool rescheduling: false }) {
    assert(() {
      if (rescheduling) {
        assert(() {
          if (debugCurrentCallbackStack == null) {
            throw new FlutterError(
              'scheduleFrameCallback called with rescheduling true, but no callback is in scope.\n'
              'The "rescheduling" argument should only be set to true if the '
              'callback is being reregistered from within the callback itself, '
              'and only then if the callback itself is entirely synchronous. '
              'If this is the initial registration of the callback, or if the '
              'callback is asynchronous, then do not use the "rescheduling" '
              'argument.'
            );
          }
          return true;
        }());
        debugStack = debugCurrentCallbackStack;
      } else {
        // TODO(ianh): trim the frames from this library, so that the call to scheduleFrameCallback is the top one
        debugStack = StackTrace.current;
      }
      return true;
    }());
  }

  final FrameCallback callback;

  static StackTrace debugCurrentCallbackStack;
  StackTrace debugStack;
}

/// The various phases that a [SchedulerBinding] goes through during
/// [SchedulerBinding.handleBeginFrame].
///
/// This is exposed by [SchedulerBinding.schedulerPhase].
///
/// The values of this enum are ordered in the same order as the phases occur,
/// so their relative index values can be compared to each other.
///
/// See also the discussion at [WidgetsBinding.drawFrame].
enum SchedulerPhase {
  /// No frame is being processed. Tasks (scheduled by
  /// [WidgetsBinding.scheduleTask]), microtasks (scheduled by
  /// [scheduleMicrotask]), [Timer] callbacks, event handlers (e.g. from user
  /// input), and other callbacks (e.g. from [Future]s, [Stream]s, and the like)
  /// may be executing.
  idle,

  /// The transient callbacks (scheduled by
  /// [WidgetsBinding.scheduleFrameCallback]) are currently executing.
  ///
  /// Typically, these callbacks handle updating objects to new animation
  /// states.
  ///
  /// See [SchedulerBinding.handleBeginFrame].
  transientCallbacks,

  /// Microtasks scheduled during the processing of transient callbacks are
  /// current executing.
  ///
  /// This may include, for instance, callbacks from futures resulted during the
  /// [transientCallbacks] phase.
  midFrameMicrotasks,

  /// The persistent callbacks (scheduled by
  /// [WidgetsBinding.addPersistentFrameCallback]) are currently executing.
  ///
  /// Typically, this is the build/layout/paint pipeline. See
  /// [WidgetsBinding.drawFrame] and [SchedulerBinding.handleDrawFrame].
  persistentCallbacks,

  /// The post-frame callbacks (scheduled by
  /// [WidgetsBinding.addPostFrameCallback]) are currently executing.
  ///
  /// Typically, these callbacks handle cleanup and scheduling of work for the
  /// next frame.
  ///
  /// See [SchedulerBinding.handleDrawFrame].
  postFrameCallbacks,
}

/// Scheduler for running the following:
///
/// * _Transient callbacks_, triggered by the system's [Window.onBeginFrame]
///   callback, for synchronizing the application's behavior to the system's
///   display. For example, [Ticker]s and [AnimationController]s trigger from
///   these.
///
/// * _Persistent callbacks_, triggered by the system's [Window.onDrawFrame]
///   callback, for updating the system's display after transient callbacks have
///   executed. For example, the rendering layer uses this to drive its
///   rendering pipeline.
///
/// * _Post-frame callbacks_, which are run after persistent callbacks, just
///   before returning from the [Window.onDrawFrame] callback.
///
/// * Non-rendering tasks, to be run between frames. These are given a
///   priority and are executed in priority order according to a
///   [schedulingStrategy].
abstract class SchedulerBinding extends BindingBase with ServicesBinding {
  // This class is intended to be used as a mixin, and should not be
  // extended directly.
  factory SchedulerBinding._() => null;

  @override
  void initInstances() {
    super.initInstances();
    _instance = this;
    ui.window.onBeginFrame = _handleBeginFrame;
    ui.window.onDrawFrame = _handleDrawFrame;
    SystemChannels.lifecycle.setMessageHandler(_handleLifecycleMessage);
  }

  /// The current [SchedulerBinding], if one has been created.
  static SchedulerBinding get instance => _instance;
  static SchedulerBinding _instance;

  @override
  void initServiceExtensions() {
    super.initServiceExtensions();
    registerNumericServiceExtension(
      name: 'timeDilation',
      getter: () async => timeDilation,
      setter: (double value) async {
        timeDilation = value;
      }
    );
  }

  /// Whether the application is visible, and if so, whether it is currently
  /// interactive.
  ///
  /// This is set by [handleAppLifecycleStateChanged] when the
  /// [SystemChannels.lifecycle] notification is dispatched.
  ///
  /// The preferred way to watch for changes to this value is using
  /// [WidgetsBindingObserver.didChangeAppLifecycleState].
  AppLifecycleState get lifecycleState => _lifecycleState;
  AppLifecycleState _lifecycleState;

  /// Called when the application lifecycle state changes.
  ///
  /// Notifies all the observers using
  /// [WidgetsBindingObserver.didChangeAppLifecycleState].
  ///
  /// This method exposes notifications from [SystemChannels.lifecycle].
  @protected
  @mustCallSuper
  void handleAppLifecycleStateChanged(AppLifecycleState state) {
    assert(state != null);
    _lifecycleState = state;
    switch (state) {
      case AppLifecycleState.resumed:
      case AppLifecycleState.inactive:
        _setFramesEnabledState(true);
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.suspending:
        _setFramesEnabledState(false);
        break;
    }
  }

  Future<String> _handleLifecycleMessage(String message) {
    handleAppLifecycleStateChanged(_parseAppLifecycleMessage(message));
    return null;
  }

  static AppLifecycleState _parseAppLifecycleMessage(String message) {
    switch (message) {
      case 'AppLifecycleState.paused':
        return AppLifecycleState.paused;
      case 'AppLifecycleState.resumed':
        return AppLifecycleState.resumed;
      case 'AppLifecycleState.inactive':
        return AppLifecycleState.inactive;
      case 'AppLifecycleState.suspending':
        return AppLifecycleState.suspending;
    }
    return null;
  }

  /// The strategy to use when deciding whether to run a task or not.
  ///
  /// Defaults to [defaultSchedulingStrategy].
  SchedulingStrategy schedulingStrategy = defaultSchedulingStrategy;

  static int _taskSorter (_TaskEntry<dynamic> e1, _TaskEntry<dynamic> e2) {
    return -e1.priority.compareTo(e2.priority);
  }
  final PriorityQueue<_TaskEntry<dynamic>> _taskQueue = new HeapPriorityQueue<_TaskEntry<dynamic>>(_taskSorter);

  /// Schedules the given `task` with the given `priority` and returns a
  /// [Future] that completes to the `task`'s eventual return value.
  ///
  /// The `debugLabel` and `flow` are used to report the task to the [Timeline],
  /// for use when profiling.
  ///
  /// ## Processing model
  ///
  /// Tasks will be executed between frames, in priority order,
  /// excluding tasks that are skipped by the current
  /// [schedulingStrategy]. Tasks should be short (as in, up to a
  /// millisecond), so as to not cause the regular frame callbacks to
  /// get delayed.
  ///
  /// If an animation is running, including, for instance, a [ProgressIndicator]
  /// indicating that there are pending tasks, then tasks with a priority below
  /// [Priority.animation] won't run (at least, not with the
  /// [defaultSchedulingStrategy]; this can be configured using
  /// [schedulingStrategy]).
  Future<T> scheduleTask<T>(TaskCallback<T> task, Priority priority, {
    String debugLabel,
    Flow flow,
  }) {
    final bool isFirstTask = _taskQueue.isEmpty;
    final _TaskEntry<T> entry = new _TaskEntry<T>(
      task,
      priority.value,
      debugLabel,
      flow,
    );
    _taskQueue.add(entry);
    if (isFirstTask && !locked)
      _ensureEventLoopCallback();
    return entry.completer.future;
  }

  @override
  void unlocked() {
    super.unlocked();
    if (_taskQueue.isNotEmpty)
      _ensureEventLoopCallback();
  }

  // Whether this scheduler already requested to be called from the event loop.
  bool _hasRequestedAnEventLoopCallback = false;

  // Ensures that the scheduler services a task scheduled by [scheduleTask].
  void _ensureEventLoopCallback() {
    assert(!locked);
    assert(_taskQueue.isNotEmpty);
    if (_hasRequestedAnEventLoopCallback)
      return;
    _hasRequestedAnEventLoopCallback = true;
    Timer.run(_runTasks);
  }

  // Scheduled by _ensureEventLoopCallback.
  void _runTasks() {
    _hasRequestedAnEventLoopCallback = false;
    if (handleEventLoopCallback())
      _ensureEventLoopCallback(); // runs next task when there's time
  }

  /// Execute the highest-priority task, if it is of a high enough priority.
  ///
  /// Returns true if a task was executed and there are other tasks remaining
  /// (even if they are not high-enough priority).
  ///
  /// Returns false if no task was executed, which can occur if there are no
  /// tasks scheduled, if the scheduler is [locked], or if the highest-priority
  /// task is of too low a priority given the current [schedulingStrategy].
  ///
  /// Also returns false if there are no tasks remaining.
  @visibleForTesting
  bool handleEventLoopCallback() {
    if (_taskQueue.isEmpty || locked)
      return false;
    final _TaskEntry<dynamic> entry = _taskQueue.first;
    if (schedulingStrategy(priority: entry.priority, scheduler: this)) {
      try {
        _taskQueue.removeFirst();
        entry.run();
      } catch (exception, exceptionStack) {
        StackTrace callbackStack;
        assert(() {
          callbackStack = entry.debugStack;
          return true;
        }());
        FlutterError.reportError(new FlutterErrorDetails(
          exception: exception,
          stack: exceptionStack,
          library: 'scheduler library',
          context: 'during a task callback',
          informationCollector: (callbackStack == null) ? null : (StringBuffer information) {
            information.writeln(
              '\nThis exception was thrown in the context of a task callback. '
              'When the task callback was _registered_ (as opposed to when the '
              'exception was thrown), this was the stack:'
            );
            FlutterError.defaultStackFilter(callbackStack.toString().trimRight().split('\n')).forEach(information.writeln);
          }
        ));
      }
      return _taskQueue.isNotEmpty;
    }
    return false;
  }

  int _nextFrameCallbackId = 0; // positive
  Map<int, _FrameCallbackEntry> _transientCallbacks = <int, _FrameCallbackEntry>{};
  final Set<int> _removedIds = new HashSet<int>();

  /// The current number of transient frame callbacks scheduled.
  ///
  /// This is reset to zero just before all the currently scheduled
  /// transient callbacks are called, at the start of a frame.
  ///
  /// This number is primarily exposed so that tests can verify that
  /// there are no unexpected transient callbacks still registered
  /// after a test's resources have been gracefully disposed.
  int get transientCallbackCount => _transientCallbacks.length;

  /// Schedules the given transient frame callback.
  ///
  /// Adds the given callback to the list of frame callbacks and ensures that a
  /// frame is scheduled.
  ///
  /// If this is a one-off registration, ignore the `rescheduling` argument.
  ///
  /// If this is a callback that will be reregistered each time it fires, then
  /// when you reregister the callback, set the `rescheduling` argument to true.
  /// This has no effect in release builds, but in debug builds, it ensures that
  /// the stack trace that is stored for this callback is the original stack
  /// trace for when the callback was _first_ registered, rather than the stack
  /// trace for when the callback is reregistered. This makes it easier to track
  /// down the original reason that a particular callback was called. If
  /// `rescheduling` is true, the call must be in the context of a frame
  /// callback.
  ///
  /// Callbacks registered with this method can be canceled using
  /// [cancelFrameCallbackWithId].
  int scheduleFrameCallback(FrameCallback callback, { bool rescheduling: false }) {
    scheduleFrame();
    _nextFrameCallbackId += 1;
    _transientCallbacks[_nextFrameCallbackId] = new _FrameCallbackEntry(callback, rescheduling: rescheduling);
    return _nextFrameCallbackId;
  }

  /// Cancels the transient frame callback with the given [id].
  ///
  /// Removes the given callback from the list of frame callbacks. If a frame
  /// has been requested, this does not also cancel that request.
  ///
  /// Transient frame callbacks are those registered using
  /// [scheduleFrameCallback].
  void cancelFrameCallbackWithId(int id) {
    assert(id > 0);
    _transientCallbacks.remove(id);
    _removedIds.add(id);
  }

  /// Asserts that there are no registered transient callbacks; if
  /// there are, prints their locations and throws an exception.
  ///
  /// A transient frame callback is one that was registered with
  /// [scheduleFrameCallback].
  ///
  /// This is expected to be called at the end of tests (the
  /// flutter_test framework does it automatically in normal cases).
  ///
  /// Call this method when you expect there to be no transient
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
        // We cache the values so that we can produce them later
        // even if the information collector is called after
        // the problem has been resolved.
        final int count = transientCallbackCount;
        final Map<int, _FrameCallbackEntry> callbacks = new Map<int, _FrameCallbackEntry>.from(_transientCallbacks);
        FlutterError.reportError(new FlutterErrorDetails(
          exception: reason,
          library: 'scheduler library',
          informationCollector: (StringBuffer information) {
            if (count == 1) {
              information.writeln(
                'There was one transient callback left. '
                'The stack trace for when it was registered is as follows:'
              );
            } else {
              information.writeln(
                'There were $count transient callbacks left. '
                'The stack traces for when they were registered are as follows:'
              );
            }
            for (int id in callbacks.keys) {
              final _FrameCallbackEntry entry = callbacks[id];
              information.writeln('── callback $id ──');
              FlutterError.defaultStackFilter(entry.debugStack.toString().trimRight().split('\n')).forEach(information.writeln);
            }
          }
        ));
      }
      return true;
    }());
    return true;
  }

  /// Prints the stack for where the current transient callback was registered.
  ///
  /// A transient frame callback is one that was registered with
  /// [scheduleFrameCallback].
  ///
  /// When called in debug more and in the context of a transient callback, this
  /// function prints the stack trace from where the current transient callback
  /// was registered (i.e. where it first called [scheduleFrameCallback]).
  ///
  /// When called in debug mode in other contexts, it prints a message saying
  /// that this function was not called in the context a transient callback.
  ///
  /// In release mode, this function does nothing.
  ///
  /// To call this function, use the following code:
  ///
  /// ```dart
  ///   SchedulerBinding.debugPrintTransientCallbackRegistrationStack();
  /// ```
  static void debugPrintTransientCallbackRegistrationStack() {
    assert(() {
      if (_FrameCallbackEntry.debugCurrentCallbackStack != null) {
        debugPrint('When the current transient callback was registered, this was the stack:');
        debugPrint(
          FlutterError.defaultStackFilter(
            _FrameCallbackEntry.debugCurrentCallbackStack.toString().trimRight().split('\n')
          ).join('\n')
        );
      } else {
        debugPrint('No transient callback is currently executing.');
      }
      return true;
    }());
  }

  final List<FrameCallback> _persistentCallbacks = <FrameCallback>[];

  /// Adds a persistent frame callback.
  ///
  /// Persistent callbacks are called after transient
  /// (non-persistent) frame callbacks.
  ///
  /// Does *not* request a new frame. Conceptually, persistent frame
  /// callbacks are observers of "begin frame" events. Since they are
  /// executed after the transient frame callbacks they can drive the
  /// rendering pipeline.
  ///
  /// Persistent frame callbacks cannot be unregistered. Once registered, they
  /// are called for every frame for the lifetime of the application.
  void addPersistentFrameCallback(FrameCallback callback) {
    _persistentCallbacks.add(callback);
  }

  final List<FrameCallback> _postFrameCallbacks = <FrameCallback>[];

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
  ///
  /// Post-frame callbacks cannot be unregistered. They are called exactly once.
  ///
  /// See also:
  ///
  ///  * [scheduleFrameCallback], which registers a callback for the start of
  ///    the next frame.
  void addPostFrameCallback(FrameCallback callback) {
    _postFrameCallbacks.add(callback);
  }

  Completer<Null> _nextFrameCompleter;

  /// Returns a Future that completes after the frame completes.
  ///
  /// If this is called between frames, a frame is immediately scheduled if
  /// necessary. If this is called during a frame, the Future completes after
  /// the current frame.
  ///
  /// If the device's screen is currently turned off, this may wait a very long
  /// time, since frames are not scheduled while the device's screen is turned
  /// off.
  Future<Null> get endOfFrame {
    if (_nextFrameCompleter == null) {
      if (schedulerPhase == SchedulerPhase.idle)
        scheduleFrame();
      _nextFrameCompleter = new Completer<Null>();
      addPostFrameCallback((Duration timeStamp) {
        _nextFrameCompleter.complete();
        _nextFrameCompleter = null;
      });
    }
    return _nextFrameCompleter.future;
  }

  /// Whether this scheduler has requested that [handleBeginFrame] be called soon.
  bool get hasScheduledFrame => _hasScheduledFrame;
  bool _hasScheduledFrame = false;

  /// The phase that the scheduler is currently operating under.
  SchedulerPhase get schedulerPhase => _schedulerPhase;
  SchedulerPhase _schedulerPhase = SchedulerPhase.idle;

  /// Whether frames are currently being scheduled when [scheduleFrame] is called.
  ///
  /// This value depends on the value of the [lifecycleState].
  bool get framesEnabled => _framesEnabled;

  bool _framesEnabled = true;
  void _setFramesEnabledState(bool enabled) {
    if (_framesEnabled == enabled)
      return;
    _framesEnabled = enabled;
    if (enabled)
      scheduleFrame();
  }

  /// Schedules a new frame using [scheduleFrame] if this object is not
  /// currently producing a frame.
  ///
  /// Calling this method ensures that [handleDrawFrame] will eventually be
  /// called, unless it's already in progress.
  ///
  /// This has no effect if [schedulerPhase] is
  /// [SchedulerPhase.transientCallbacks] or [SchedulerPhase.midFrameMicrotasks]
  /// (because a frame is already being prepared in that case), or
  /// [SchedulerPhase.persistentCallbacks] (because a frame is actively being
  /// rendered in that case). It will schedule a frame if the [schedulerPhase]
  /// is [SchedulerPhase.idle] (in between frames) or
  /// [SchedulerPhase.postFrameCallbacks] (after a frame).
  void ensureVisualUpdate() {
    switch (schedulerPhase) {
      case SchedulerPhase.idle:
      case SchedulerPhase.postFrameCallbacks:
        scheduleFrame();
        return;
      case SchedulerPhase.transientCallbacks:
      case SchedulerPhase.midFrameMicrotasks:
      case SchedulerPhase.persistentCallbacks:
        return;
    }
  }

  /// If necessary, schedules a new frame by calling
  /// [Window.scheduleFrame].
  ///
  /// After this is called, the engine will (eventually) call
  /// [handleBeginFrame]. (This call might be delayed, e.g. if the device's
  /// screen is turned off it will typically be delayed until the screen is on
  /// and the application is visible.) Calling this during a frame forces
  /// another frame to be scheduled, even if the current frame has not yet
  /// completed.
  ///
  /// Scheduled frames are serviced when triggered by a "Vsync" signal provided
  /// by the operating system. The "Vsync" signal, or vertical synchronization
  /// signal, was historically related to the display refresh, at a time when
  /// hardware physically moved a beam of electrons vertically between updates
  /// of the display. The operation of contemporary hardware is somewhat more
  /// subtle and complicated, but the conceptual "Vsync" refresh signal continue
  /// to be used to indicate when applications should update their rendering.
  ///
  /// To have a stack trace printed to the console any time this function
  /// schedules a frame, set [debugPrintScheduleFrameStacks] to true.
  ///
  /// See also:
  ///
  ///  * [scheduleForcedFrame], which ignores the [lifecycleState] when
  ///    scheduling a frame.
  ///  * [scheduleWarmUpFrame], which ignores the "Vsync" signal entirely and
  ///    triggers a frame immediately.
  void scheduleFrame() {
    if (_hasScheduledFrame || !_framesEnabled)
      return;
    assert(() {
      if (debugPrintScheduleFrameStacks)
        debugPrintStack(label: 'scheduleFrame() called. Current phase is $schedulerPhase.');
      return true;
    }());
    ui.window.scheduleFrame();
    _hasScheduledFrame = true;
  }

  /// Schedules a new frame by calling [Window.scheduleFrame].
  ///
  /// After this is called, the engine will call [handleBeginFrame], even if
  /// frames would normally not be scheduled by [scheduleFrame] (e.g. even if
  /// the device's screen is turned off).
  ///
  /// The framework uses this to force a frame to be rendered at the correct
  /// size when the phone is rotated, so that a correctly-sized rendering is
  /// available when the screen is turned back on.
  ///
  /// To have a stack trace printed to the console any time this function
  /// schedules a frame, set [debugPrintScheduleFrameStacks] to true.
  ///
  /// Prefer using [scheduleFrame] unless it is imperative that a frame be
  /// scheduled immediately, since using [scheduleForceFrame] will cause
  /// significantly higher battery usage when the device should be idle.
  ///
  /// Consider using [scheduleWarmUpFrame] instead if the goal is to update the
  /// rendering as soon as possible (e.g. at application startup).
  void scheduleForcedFrame() {
    if (_hasScheduledFrame)
      return;
    assert(() {
      if (debugPrintScheduleFrameStacks)
        debugPrintStack(label: 'scheduleForcedFrame() called. Current phase is $schedulerPhase.');
      return true;
    }());
    ui.window.scheduleFrame();
    _hasScheduledFrame = true;
  }

  bool _warmUpFrame = false;

  /// Schedule a frame to run as soon as possible, rather than waiting for
  /// the engine to request a frame in response to a system "Vsync" signal.
  ///
  /// This is used during application startup so that the first frame (which is
  /// likely to be quite expensive) gets a few extra milliseconds to run.
  ///
  /// Locks events dispatching until the scheduled frame has completed.
  ///
  /// If a frame has already been scheduled with [scheduleFrame] or
  /// [scheduleForcedFrame], this call may delay that frame.
  ///
  /// If any scheduled frame has already begun or if another
  /// [scheduleWarmUpFrame] was already called, this call will be ignored.
  ///
  /// Prefer [scheduleFrame] to update the display in normal operation.
  void scheduleWarmUpFrame() {
    if (_warmUpFrame || schedulerPhase != SchedulerPhase.idle)
      return;

    _warmUpFrame = true;
    Timeline.startSync('Warm-up frame');
    final bool hadScheduledFrame = _hasScheduledFrame;
    // We use timers here to ensure that microtasks flush in between.
    Timer.run(() {
      assert(_warmUpFrame);
      handleBeginFrame(null);
    });
    Timer.run(() {
      assert(_warmUpFrame);
      handleDrawFrame();
      // We call resetEpoch after this frame so that, in the hot reload case,
      // the very next frame pretends to have occurred immediately after this
      // warm-up frame. The warm-up frame's timestamp will typically be far in
      // the past (the time of the last real frame), so if we didn't reset the
      // epoch we would see a sudden jump from the old time in the warm-up frame
      // to the new time in the "real" frame. The biggest problem with this is
      // that implicit animations end up being triggered at the old time and
      // then skipping every frame and finishing in the new time.
      resetEpoch();
      _warmUpFrame = false;
      if (hadScheduledFrame)
        scheduleFrame();
    });

    // Lock events so touch events etc don't insert themselves until the
    // scheduled frame has finished.
    lockEvents(() async {
      await endOfFrame;
      Timeline.finishSync();
    });
  }

  Duration _firstRawTimeStampInEpoch;
  Duration _epochStart = Duration.zero;
  Duration _lastRawTimeStamp = Duration.zero;

  /// Prepares the scheduler for a non-monotonic change to how time stamps are
  /// calculated.
  ///
  /// Callbacks received from the scheduler assume that their time stamps are
  /// monotonically increasing. The raw time stamp passed to [handleBeginFrame]
  /// is monotonic, but the scheduler might adjust those time stamps to provide
  /// [timeDilation]. Without careful handling, these adjusts could cause time
  /// to appear to run backwards.
  ///
  /// The [resetEpoch] function ensures that the time stamps are monotonic by
  /// resetting the base time stamp used for future time stamp adjustments to the
  /// current value. For example, if the [timeDilation] decreases, rather than
  /// scaling down the [Duration] since the beginning of time, [resetEpoch] will
  /// ensure that we only scale down the duration since [resetEpoch] was called.
  ///
  /// Setting [timeDilation] calls [resetEpoch] automatically. You don't need to
  /// call [resetEpoch] yourself.
  void resetEpoch() {
    _epochStart = _adjustForEpoch(_lastRawTimeStamp);
    _firstRawTimeStampInEpoch = null;
  }

  /// Adjusts the given time stamp into the current epoch.
  ///
  /// This both offsets the time stamp to account for when the epoch started
  /// (both in raw time and in the epoch's own time line) and scales the time
  /// stamp to reflect the time dilation in the current epoch.
  ///
  /// These mechanisms together combine to ensure that the durations we give
  /// during frame callbacks are monotonically increasing.
  Duration _adjustForEpoch(Duration rawTimeStamp) {
    final Duration rawDurationSinceEpoch = _firstRawTimeStampInEpoch == null ? Duration.zero : rawTimeStamp - _firstRawTimeStampInEpoch;
    return new Duration(microseconds: (rawDurationSinceEpoch.inMicroseconds / timeDilation).round() + _epochStart.inMicroseconds);
  }

  /// The time stamp for the frame currently being processed.
  ///
  /// This is only valid while [handleBeginFrame] is running, i.e. while a frame
  /// is being produced.
  Duration get currentFrameTimeStamp {
    assert(_currentFrameTimeStamp != null);
    return _currentFrameTimeStamp;
  }
  Duration _currentFrameTimeStamp;

  int _profileFrameNumber = 0;
  final Stopwatch _profileFrameStopwatch = new Stopwatch();
  String _debugBanner;
  bool _ignoreNextEngineDrawFrame = false;

  void _handleBeginFrame(Duration rawTimeStamp) {
    if (_warmUpFrame) {
      assert(!_ignoreNextEngineDrawFrame);
      _ignoreNextEngineDrawFrame = true;
      return;
    }
    handleBeginFrame(rawTimeStamp);
  }

  void _handleDrawFrame() {
    if (_ignoreNextEngineDrawFrame) {
      _ignoreNextEngineDrawFrame = false;
      return;
    }
    handleDrawFrame();
  }

  /// Called by the engine to prepare the framework to produce a new frame.
  ///
  /// This function calls all the transient frame callbacks registered by
  /// [scheduleFrameCallback]. It then returns, any scheduled microtasks are run
  /// (e.g. handlers for any [Future]s resolved by transient frame callbacks),
  /// and [handleDrawFrame] is called to continue the frame.
  ///
  /// If the given time stamp is null, the time stamp from the last frame is
  /// reused.
  ///
  /// To have a banner shown at the start of every frame in debug mode, set
  /// [debugPrintBeginFrameBanner] to true. The banner will be printed to the
  /// console using [debugPrint] and will contain the frame number (which
  /// increments by one for each frame), and the time stamp of the frame. If the
  /// given time stamp was null, then the string "warm-up frame" is shown
  /// instead of the time stamp. This allows frames eagerly pushed by the
  /// framework to be distinguished from those requested by the engine in
  /// response to the "Vsync" signal from the operating system.
  ///
  /// You can also show a banner at the end of every frame by setting
  /// [debugPrintEndFrameBanner] to true. This allows you to distinguish log
  /// statements printed during a frame from those printed between frames (e.g.
  /// in response to events or timers).
  void handleBeginFrame(Duration rawTimeStamp) {
    Timeline.startSync('Frame', arguments: timelineWhitelistArguments);
    _firstRawTimeStampInEpoch ??= rawTimeStamp;
    _currentFrameTimeStamp = _adjustForEpoch(rawTimeStamp ?? _lastRawTimeStamp);
    if (rawTimeStamp != null)
      _lastRawTimeStamp = rawTimeStamp;

    profile(() {
      _profileFrameNumber += 1;
      _profileFrameStopwatch.reset();
      _profileFrameStopwatch.start();
    });

    assert(() {
      if (debugPrintBeginFrameBanner || debugPrintEndFrameBanner) {
        final StringBuffer frameTimeStampDescription = new StringBuffer();
        if (rawTimeStamp != null) {
          _debugDescribeTimeStamp(_currentFrameTimeStamp, frameTimeStampDescription);
        } else {
          frameTimeStampDescription.write('(warm-up frame)');
        }
        _debugBanner = '▄▄▄▄▄▄▄▄ Frame ${_profileFrameNumber.toString().padRight(7)}   ${frameTimeStampDescription.toString().padLeft(18)} ▄▄▄▄▄▄▄▄';
        if (debugPrintBeginFrameBanner)
          debugPrint(_debugBanner);
      }
      return true;
    }());

    assert(schedulerPhase == SchedulerPhase.idle);
    _hasScheduledFrame = false;
    try {
      // TRANSIENT FRAME CALLBACKS
      Timeline.startSync('Animate', arguments: timelineWhitelistArguments);
      _schedulerPhase = SchedulerPhase.transientCallbacks;
      final Map<int, _FrameCallbackEntry> callbacks = _transientCallbacks;
      _transientCallbacks = <int, _FrameCallbackEntry>{};
      callbacks.forEach((int id, _FrameCallbackEntry callbackEntry) {
        if (!_removedIds.contains(id))
          _invokeFrameCallback(callbackEntry.callback, _currentFrameTimeStamp, callbackEntry.debugStack);
      });
      _removedIds.clear();
    } finally {
      _schedulerPhase = SchedulerPhase.midFrameMicrotasks;
    }
  }

  /// Called by the engine to produce a new frame.
  ///
  /// This method is called immediately after [handleBeginFrame]. It calls all
  /// the callbacks registered by [addPersistentFrameCallback], which typically
  /// drive the rendering pipeline, and then calls the callbacks registered by
  /// [addPostFrameCallback].
  ///
  /// See [handleBeginFrame] for a discussion about debugging hooks that may be
  /// useful when working with frame callbacks.
  void handleDrawFrame() {
    assert(_schedulerPhase == SchedulerPhase.midFrameMicrotasks);
    Timeline.finishSync(); // end the "Animate" phase
    try {
      // PERSISTENT FRAME CALLBACKS
      _schedulerPhase = SchedulerPhase.persistentCallbacks;
      for (FrameCallback callback in _persistentCallbacks)
        _invokeFrameCallback(callback, _currentFrameTimeStamp);

      // POST-FRAME CALLBACKS
      _schedulerPhase = SchedulerPhase.postFrameCallbacks;
      final List<FrameCallback> localPostFrameCallbacks =
          new List<FrameCallback>.from(_postFrameCallbacks);
      _postFrameCallbacks.clear();
      for (FrameCallback callback in localPostFrameCallbacks)
        _invokeFrameCallback(callback, _currentFrameTimeStamp);
    } finally {
      _schedulerPhase = SchedulerPhase.idle;
      Timeline.finishSync(); // end the Frame
      profile(() {
        _profileFrameStopwatch.stop();
        _profileFramePostEvent();
      });
      assert(() {
        if (debugPrintEndFrameBanner)
          debugPrint('▀' * _debugBanner.length);
        _debugBanner = null;
        return true;
      }());
      _currentFrameTimeStamp = null;
    }
  }

  void _profileFramePostEvent() {
    postEvent('Flutter.Frame', <String, dynamic>{
      'number': _profileFrameNumber,
      'startTime': _currentFrameTimeStamp.inMicroseconds,
      'elapsed': _profileFrameStopwatch.elapsedMicroseconds
    });
  }

  static void _debugDescribeTimeStamp(Duration timeStamp, StringBuffer buffer) {
    if (timeStamp.inDays > 0)
      buffer.write('${timeStamp.inDays}d ');
    if (timeStamp.inHours > 0)
      buffer.write('${timeStamp.inHours - timeStamp.inDays * Duration.hoursPerDay}h ');
    if (timeStamp.inMinutes > 0)
      buffer.write('${timeStamp.inMinutes - timeStamp.inHours * Duration.minutesPerHour}m ');
    if (timeStamp.inSeconds > 0)
      buffer.write('${timeStamp.inSeconds - timeStamp.inMinutes * Duration.secondsPerMinute}s ');
    buffer.write('${timeStamp.inMilliseconds - timeStamp.inSeconds * Duration.millisecondsPerSecond}');
    final int microseconds = timeStamp.inMicroseconds - timeStamp.inMilliseconds * Duration.microsecondsPerMillisecond;
    if (microseconds > 0)
      buffer.write('.${microseconds.toString().padLeft(3, "0")}');
    buffer.write('ms');
  }

  // Calls the given [callback] with [timestamp] as argument.
  //
  // Wraps the callback in a try/catch and forwards any error to
  // [debugSchedulerExceptionHandler], if set. If not set, then simply prints
  // the error.
  void _invokeFrameCallback(FrameCallback callback, Duration timeStamp, [ StackTrace callbackStack ]) {
    assert(callback != null);
    assert(_FrameCallbackEntry.debugCurrentCallbackStack == null);
    assert(() { _FrameCallbackEntry.debugCurrentCallbackStack = callbackStack; return true; }());
    try {
      callback(timeStamp);
    } catch (exception, exceptionStack) {
      FlutterError.reportError(new FlutterErrorDetails(
        exception: exception,
        stack: exceptionStack,
        library: 'scheduler library',
        context: 'during a scheduler callback',
        informationCollector: (callbackStack == null) ? null : (StringBuffer information) {
          information.writeln(
            '\nThis exception was thrown in the context of a scheduler callback. '
            'When the scheduler callback was _registered_ (as opposed to when the '
            'exception was thrown), this was the stack:'
          );
          FlutterError.defaultStackFilter(callbackStack.toString().trimRight().split('\n')).forEach(information.writeln);
        }
      ));
    }
    assert(() { _FrameCallbackEntry.debugCurrentCallbackStack = null; return true; }());
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
