// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Generated from Web IDL definitions.

import 'dart:js_interop';

import 'dom.dart';
import 'html.dart';

typedef SchedulerPostTaskCallback = JSFunction;
typedef TaskPriority = String;

@JS()
@staticInterop
@anonymous
class SchedulerPostTaskOptions {
  external factory SchedulerPostTaskOptions({
    AbortSignal signal,
    TaskPriority priority,
    int delay,
  });
}

extension SchedulerPostTaskOptionsExtension on SchedulerPostTaskOptions {
  external set signal(AbortSignal value);
  external AbortSignal get signal;
  external set priority(TaskPriority value);
  external TaskPriority get priority;
  external set delay(int value);
  external int get delay;
}

@JS('Scheduler')
@staticInterop
class Scheduler {}

extension SchedulerExtension on Scheduler {
  external JSPromise postTask(
    SchedulerPostTaskCallback callback, [
    SchedulerPostTaskOptions options,
  ]);
}

@JS('TaskPriorityChangeEvent')
@staticInterop
class TaskPriorityChangeEvent implements Event {
  external factory TaskPriorityChangeEvent(
    String type,
    TaskPriorityChangeEventInit priorityChangeEventInitDict,
  );
}

extension TaskPriorityChangeEventExtension on TaskPriorityChangeEvent {
  external TaskPriority get previousPriority;
}

@JS()
@staticInterop
@anonymous
class TaskPriorityChangeEventInit implements EventInit {
  external factory TaskPriorityChangeEventInit(
      {required TaskPriority previousPriority});
}

extension TaskPriorityChangeEventInitExtension on TaskPriorityChangeEventInit {
  external set previousPriority(TaskPriority value);
  external TaskPriority get previousPriority;
}

@JS()
@staticInterop
@anonymous
class TaskControllerInit {
  external factory TaskControllerInit({TaskPriority priority});
}

extension TaskControllerInitExtension on TaskControllerInit {
  external set priority(TaskPriority value);
  external TaskPriority get priority;
}

@JS('TaskController')
@staticInterop
class TaskController implements AbortController {
  external factory TaskController([TaskControllerInit init]);
}

extension TaskControllerExtension on TaskController {
  external void setPriority(TaskPriority priority);
}

@JS()
@staticInterop
@anonymous
class TaskSignalAnyInit {
  external factory TaskSignalAnyInit({JSAny priority});
}

extension TaskSignalAnyInitExtension on TaskSignalAnyInit {
  external set priority(JSAny value);
  external JSAny get priority;
}

@JS('TaskSignal')
@staticInterop
class TaskSignal implements AbortSignal {
  external static TaskSignal any(
    JSArray signals, [
    TaskSignalAnyInit init,
  ]);
}

extension TaskSignalExtension on TaskSignal {
  external TaskPriority get priority;
  external set onprioritychange(EventHandler value);
  external EventHandler get onprioritychange;
}
