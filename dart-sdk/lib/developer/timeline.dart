// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.developer;

// Examples can assume:
// void doSomething() {}

const bool _hasTimeline =
    const bool.fromEnvironment("dart.developer.timeline", defaultValue: true);

/// A typedef for the function argument to [Timeline.timeSync].
typedef TimelineSyncFunction<T> = T Function();

// TODO: This typedef is not used.
typedef Future TimelineAsyncFunction();

// These values must be kept in sync with the enum "EventType" in
// runtime/vm/timeline.h, along with the JS-specific implementations in:
// - _internal/js_runtime/lib/developer_patch.dart
// - _internal/js_dev_runtime/patch/developer_patch.dart
const int _begin = 1;
const int _end = 2;
const int _instant = 4;
const int _asyncBegin = 5;
const int _asyncInstant = 6;
const int _asyncEnd = 7;
const int _flowBegin = 9;
const int _flowStep = 10;
const int _flowEnd = 11;

// This value must be kept in sync with the value of TimelineEvent::kNoFlowId in
// runtime/vm/timeline.h.
const int _noFlowId = -1;

/// A class to represent Flow events.
///
/// [Flow] objects are used to thread flow events between timeline slices,
/// for example, those created with the [Timeline] class below. Adding
/// [Flow] objects cause arrows to be drawn between slices in Chrome's trace
/// viewer. The arrows start at e.g [Timeline] events that are passed a
/// [Flow.begin] object, go through [Timeline] events that are passed a
/// [Flow.step] object, and end at [Timeline] events that are passed a
/// [Flow.end] object, all having the same [Flow.id]. For example:
///
/// ```dart
/// var flow = Flow.begin();
/// Timeline.timeSync('flow_test', () {
///   doSomething();
/// }, flow: flow);
///
/// Timeline.timeSync('flow_test', () {
///   doSomething();
/// }, flow: Flow.step(flow.id));
///
/// Timeline.timeSync('flow_test', () {
///   doSomething();
/// }, flow: Flow.end(flow.id));
/// ```
final class Flow {
  final int _type;

  /// The flow id of the flow event.
  final int id;

  Flow._(this._type, this.id);

  /// A "begin" Flow event.
  ///
  /// When passed to a [Timeline] method, generates a "begin" Flow event.
  /// If [id] is not provided, an id that conflicts with no other Dart-generated
  /// flow id's will be generated.
  static Flow begin({int? id}) {
    return new Flow._(_flowBegin, id ?? _getNextTaskId());
  }

  /// A "step" Flow event.
  ///
  /// When passed to a [Timeline] method, generates a "step" Flow event.
  /// The [id] argument is required. It can come either from another [Flow]
  /// event, or some id that comes from the environment.
  static Flow step(int id) => new Flow._(_flowStep, id);

  /// An "end" Flow event.
  ///
  /// When passed to a [Timeline] method, generates a "end" Flow event.
  /// The [id] argument is required. It can come either from another [Flow]
  /// event, or some id that comes from the environment.
  static Flow end(int id) => new Flow._(_flowEnd, id);
}

/// Add to the timeline.
///
/// [Timeline]'s methods add synchronous events to the timeline. When
/// generating a timeline in Chrome's tracing format, using [Timeline] generates
/// "Complete" events. [Timeline]'s [startSync] and [finishSync] can be used
/// explicitly, or implicitly by wrapping a closure in [timeSync]. For example:
///
/// ```dart
/// Timeline.startSync("Doing Something");
/// doSomething();
/// Timeline.finishSync();
/// ```
///
/// Or:
///
/// ```dart
/// Timeline.timeSync("Doing Something", () {
///   doSomething();
/// });
/// ```
abstract final class Timeline {
  /// Start a synchronous operation labeled [name]. Optionally takes
  /// a [Map] of [arguments]. This slice may also optionally be associated with
  /// a [Flow] event. This operation must be finished before
  /// returning to the event queue.
  static void startSync(String name, {Map? arguments, Flow? flow}) {
    if (!_hasTimeline) return;
    // TODO: When NNBD is complete, delete the following line.
    ArgumentError.checkNotNull(name, 'name');
    if (!_isDartStreamEnabled()) {
      // Push a null onto the stack and return.
      _stack.add(null);
      return;
    }
    var block = new _SyncBlock._(name, _getNextTaskId(),
        arguments: arguments, flow: flow);
    _stack.add(block);
    block._startSync();
  }

  /// Finish the last synchronous operation that was started.
  static void finishSync() {
    if (!_hasTimeline) {
      return;
    }
    if (_stack.isEmpty) {
      throw new StateError('Uneven calls to startSync and finishSync');
    }
    // Pop top item off of stack.
    var block = _stack.removeLast();
    if (block == null) {
      // Dart stream was disabled when startSync was called.
      return;
    }
    // Finish it.
    block.finish();
  }

  /// Emit an instant event.
  static void instantSync(String name, {Map? arguments}) {
    if (!_hasTimeline) return;
    // TODO: When NNBD is complete, delete the following line.
    ArgumentError.checkNotNull(name, 'name');
    if (!_isDartStreamEnabled()) {
      // Stream is disabled.
      return;
    }
    // Instant events don't have an id because they don't need to be paired with
    // other events.
    int taskId = 0;
    _reportTaskEvent(taskId, /*flowId=*/ _noFlowId, _instant, name,
        _argumentsAsJson(arguments));
  }

  /// A utility method to time a synchronous [function]. Internally calls
  /// [function] bracketed by calls to [startSync] and [finishSync].
  static T timeSync<T>(String name, TimelineSyncFunction<T> function,
      {Map? arguments, Flow? flow}) {
    startSync(name, arguments: arguments, flow: flow);
    try {
      return function();
    } finally {
      finishSync();
    }
  }

  /// The current time stamp from the clock used by the timeline. Units are
  /// microseconds.
  ///
  /// When run on the Dart VM, uses the same monotonic clock as the embedding
  /// API's `Dart_TimelineGetMicros`.
  static int get now => _getTraceClock();
  static final List<_SyncBlock?> _stack = [];
}

/// An asynchronous task on the timeline. An asynchronous task can have many
/// (nested) synchronous operations. Synchronous operations can live longer than
/// the current isolate event. To pass a [TimelineTask] to another isolate,
/// you must first call [pass] to get the task id and then construct a new
/// [TimelineTask] in the other isolate.
final class TimelineTask {
  /// Create a task. The task ID will be set by the system.
  ///
  /// If [parent] is provided, the parent's task ID is provided as argument
  /// 'parentId' when [start] is called. In DevTools, this argument will result
  /// in this [TimelineTask] being linked to the [parent] [TimelineTask].
  ///
  /// If [filterKey] is provided, a property named `filterKey` will be inserted
  /// into the arguments of each event associated with this task. The
  /// `filterKey` will be set to the value of [filterKey].
  TimelineTask({TimelineTask? parent, String? filterKey})
      : _parent = parent,
        _filterKey = filterKey,
        _taskId = _getNextTaskId() {}

  /// Create a task with an explicit [taskId]. This is useful if you are
  /// passing a task from one isolate to another.
  ///
  /// Important note: only provide task IDs which have been obtained as a
  /// result of invoking [TimelineTask.pass]. Specifying a custom ID can lead
  /// to ID collisions, resulting in incorrect rendering of timeline events.
  ///
  /// If [filterKey] is provided, a property named `filterKey` will be inserted
  /// into the arguments of each event associated with this task. The
  /// `filterKey` will be set to the value of [filterKey].
  TimelineTask.withTaskId(int taskId, {String? filterKey})
      : _parent = null,
        _filterKey = filterKey,
        _taskId = taskId {
    // TODO: When NNBD is complete, delete the following line.
    ArgumentError.checkNotNull(taskId, 'taskId');
  }

  /// Start a synchronous operation within this task named [name].
  /// Optionally takes a [Map] of [arguments].
  void start(String name, {Map? arguments}) {
    if (!_hasTimeline) return;
    // TODO: When NNBD is complete, delete the following line.
    ArgumentError.checkNotNull(name, 'name');
    if (!_isDartStreamEnabled()) {
      // Push a null onto the stack and return.
      _stack.add(null);
      return;
    }
    var block = new _AsyncBlock._(name, _taskId);
    _stack.add(block);
    // TODO(39115): Spurious error about collection literal ambiguity.
    // TODO(39117): Spurious error about typing of `...?arguments`.
    // TODO(39120): Spurious error even about `...arguments`.
    // When these TODOs are done, we can use spread and if elements.
    var map = <Object?, Object?>{};
    if (arguments != null) {
      for (var key in arguments.keys) {
        map[key] = arguments[key];
      }
    }
    if (_parent != null) map['parentId'] = _parent._taskId.toRadixString(16);
    if (_filterKey != null) map[_kFilterKey] = _filterKey;
    block._start(map);
  }

  /// Emit an instant event for this task.
  /// Optionally takes a [Map] of [arguments].
  void instant(String name, {Map? arguments}) {
    if (!_hasTimeline) return;
    // TODO: When NNBD is complete, delete the following line.
    ArgumentError.checkNotNull(name, 'name');
    if (!_isDartStreamEnabled()) {
      // Stream is disabled.
      return;
    }
    Map? instantArguments;
    if (arguments != null) {
      instantArguments = new Map.from(arguments);
    }
    if (_filterKey != null) {
      instantArguments ??= {};
      instantArguments[_kFilterKey] = _filterKey;
    }
    _reportTaskEvent(_taskId, /*flowId=*/ _noFlowId, _asyncInstant, name,
        _argumentsAsJson(instantArguments));
  }

  /// Finish the last synchronous operation that was started.
  /// Optionally takes a [Map] of [arguments].
  void finish({Map? arguments}) {
    if (!_hasTimeline) {
      return;
    }
    if (_stack.length == 0) {
      throw new StateError('Uneven calls to start and finish');
    }
    if (_filterKey != null) {
      arguments ??= {};
      arguments[_kFilterKey] = _filterKey;
    }
    // Pop top item off of stack.
    var block = _stack.removeLast();
    if (block == null) {
      // Dart stream was disabled when start was called.
      return;
    }
    block._finish(arguments);
  }

  /// Retrieve the [TimelineTask]'s task id. Will throw an exception if the
  /// stack is not empty.
  int pass() {
    if (_stack.length > 0) {
      throw new StateError(
          'You cannot pass a TimelineTask without finishing all started '
          'operations');
    }
    int r = _taskId;
    return r;
  }

  static const String _kFilterKey = 'filterKey';
  final TimelineTask? _parent;
  final String? _filterKey;
  final int _taskId;
  final List<_AsyncBlock?> _stack = [];
}

/// An asynchronous block of time on the timeline. This block can be kept
/// open across isolate messages.
final class _AsyncBlock {
  /// The name of this block.
  final String name;

  /// The asynchronous task id.
  final int _taskId;

  _AsyncBlock._(this.name, this._taskId);

  // Emit the start event.
  void _start(Map arguments) {
    _reportTaskEvent(_taskId, /*flowId=*/ _noFlowId, _asyncBegin, name,
        _argumentsAsJson(arguments));
  }

  // Emit the finish event.
  void _finish(Map? arguments) {
    _reportTaskEvent(_taskId, /*flowId=*/ _noFlowId, _asyncEnd, name,
        _argumentsAsJson(arguments));
  }
}

/// A synchronous block of time on the timeline. This block should not be
/// kept open across isolate messages.
final class _SyncBlock {
  /// The name of this block.
  final String name;

  /// Signpost needs help matching begin and end events.
  final int taskId;

  /// An (optional) set of arguments which will be serialized to JSON and
  /// associated with this block.
  final Map? arguments;

  /// An (optional) flow event associated with this block.
  final Flow? flow;

  late final String _jsonArguments = _argumentsAsJson(arguments);

  _SyncBlock._(this.name, this.taskId, {this.arguments, this.flow});

  /// Start this block of time.
  void _startSync() {
    _reportTaskEvent(
        taskId, flow?.id ?? _noFlowId, _begin, name, _jsonArguments);
  }

  /// Finish this block of time. At this point, this block can no longer be
  /// used.
  void finish() {
    // Report event to runtime.
    final Flow? tempFlow = flow;
    if (tempFlow != null) {
      _reportTaskEvent(tempFlow.id, /*flowId=*/ _noFlowId, tempFlow._type,
          "${tempFlow.id}", _argumentsAsJson(null));
    }
    _reportTaskEvent(taskId, /*flowId=*/ _noFlowId, _end, name, _jsonArguments);
  }
}

String _argumentsAsJson(Map? arguments) {
  if ((arguments == null) || (arguments.length == 0)) {
    // Fast path no arguments. Avoid calling jsonEncode.
    return '{}';
  }
  return json.encode(arguments);
}

/// Returns true if the Dart Timeline stream is enabled.
@pragma("vm:recognized", "asm-intrinsic")
external bool _isDartStreamEnabled();

/// Returns the next task id.
@pragma("vm:recognized", "asm-intrinsic")
external int _getNextTaskId();

/// Returns the current value from the trace clock.
external int _getTraceClock();

/// Reports an event for a task.
external void _reportTaskEvent(
    int taskId, int flowId, int type, String name, String argumentsAsJson);
