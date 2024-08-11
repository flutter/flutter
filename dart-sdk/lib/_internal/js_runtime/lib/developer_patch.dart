// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Patch file for dart:developer library.

import 'dart:_internal' show patch;

import 'dart:async' show Zone;
import 'dart:js_interop';
import 'dart:isolate';

// These values must be kept in sync with developer/timeline.dart.
const int _beginPatch = 1;
const int _endPatch = 2;
const int _asyncBeginPatch = 5;
const int _asyncEndPatch = 7;
const int _flowBeginPatch = 9;
const int _flowStepPatch = 10;
const int _flowEndPatch = 11;

@JS('debugger')
external void _jsDebugger();

@JS('performance')
external JSAny? get _jsPerformance;

@JS('JSON')
external JSAny? get _jsJSON;

extension type _JSPerformance(JSObject performance) {
  @JS('measure')
  external JSAny? get _measureMethod;

  @JS('mark')
  external JSAny? get _markMethod;

  external void measure(
      JSString measureName, JSString startMark, JSString endMark);

  external void mark(JSString markName, JSObject markOptions);
}

extension type _JSJSON(JSObject performance) {
  external JSObject parse(JSString string);
}

_JSPerformance? _performance = (() {
  final value = _jsPerformance;
  if (value.isA<JSObject>()) {
    final performance = _JSPerformance(value as JSObject);
    if (performance._measureMethod != null && performance._markMethod != null) {
      return performance;
    }
  }
  return null;
})();

_JSJSON _json = (() {
  final value = _jsJSON;
  if (value.isA<JSObject>()) {
    return value as _JSJSON;
  }
  throw UnsupportedError('Missing JSON.parse() support');
})();

@patch
@pragma('dart2js:tryInline')
bool debugger({bool when = true, String? message}) {
  if (when) _jsDebugger();
  return when;
}

@patch
Object? inspect(Object? object) {
  return object;
}

@patch
void log(String message,
    {DateTime? time,
    int? sequenceNumber,
    int level = 0,
    String name = '',
    Zone? zone,
    Object? error,
    StackTrace? stackTrace}) {
  // TODO.
}

@patch
int get reachabilityBarrier => 0;

final _extensions = <String, ServiceExtensionHandler>{};

@patch
ServiceExtensionHandler? _lookupExtension(String method) {
  return _extensions[method];
}

@patch
_registerExtension(String method, ServiceExtensionHandler handler) {
  _extensions[method] = handler;
}

@patch
bool get extensionStreamHasListener => false;

@patch
void _postEvent(String eventKind, String eventData) {
  // TODO.
}

@patch
bool _isDartStreamEnabled() {
  return _performance != null;
}

@patch
int _getTraceClock() {
  // Note: Use `millisecondsSinceEpoch` instead of `microsecondsSinceEpoch`
  // because JS isn't able to hold the value of `microsecondsSinceEpoch` without
  // rounding errors.
  return DateTime.now().millisecondsSinceEpoch;
}

int _taskId = 1;

@patch
int _getNextTaskId() {
  return _taskId++;
}

bool _isBeginEvent(int type) => type == _beginPatch || type == _asyncBeginPatch;

bool _isEndEvent(int type) => type == _endPatch || type == _asyncEndPatch;

bool _isUnsupportedEvent(int type) =>
    type == _flowBeginPatch || type == _flowEndPatch || type == _flowStepPatch;

String _createEventName({
  required int taskId,
  required String name,
  required bool isBeginEvent,
  required bool isEndEvent,
}) {
  if (isBeginEvent) {
    return '$taskId-$name-begin';
  }
  if (isEndEvent) {
    return '$taskId-$name-end';
  }
  // Return only the name for events that don't need measurements:
  return name;
}

Map<String, int> _eventNameToCount = {};

String _postfixWithCount(String eventName) {
  final count = _eventNameToCount[eventName];
  if (count == null) return eventName;
  return '$eventName-$count';
}

void _incrementEventCount(String eventName) {
  final currentCount = _eventNameToCount[eventName] ?? 0;
  _eventNameToCount[eventName] = currentCount + 1;
}

void _decrementEventCount(String eventName) {
  if (!_eventNameToCount.containsKey(eventName)) return;

  final newCount = _eventNameToCount[eventName]! - 1;
  if (newCount <= 0) {
    _eventNameToCount.remove(eventName);
  } else {
    _eventNameToCount[eventName] = newCount;
  }
}

@patch
void _reportTaskEvent(
    int taskId, int flowId, int type, String name, String argumentsAsJson) {
  // Ignore any unsupported events.
  if (_isUnsupportedEvent(type)) return;

  final isBeginEvent = _isBeginEvent(type);
  final isEndEvent = _isEndEvent(type);
  var currentEventName = _createEventName(
    taskId: taskId,
    name: name,
    isBeginEvent: isBeginEvent,
    isEndEvent: isEndEvent,
  );
  // Postfix the event name with the current count of events with that name. This
  // guarantees that we are always measuring from the most recent begin event.
  if (isBeginEvent) {
    _incrementEventCount(currentEventName);
    currentEventName = _postfixWithCount(currentEventName);
  }

  // Start by creating a mark event.
  _performance!.mark(currentEventName.toJS, _json.parse(argumentsAsJson.toJS));

  // If it's an end event, then create a measurement from the most recent begin
  // event with the same name.
  if (isEndEvent) {
    final beginEventName = _createEventName(
        taskId: taskId, name: name, isBeginEvent: true, isEndEvent: false);
    _performance!.measure(name.toJS, _postfixWithCount(beginEventName).toJS,
        currentEventName.toJS);
    _decrementEventCount(beginEventName);
  }
}

@patch
int _getServiceMajorVersion() {
  return 0;
}

@patch
int _getServiceMinorVersion() {
  return 0;
}

@patch
void _getServerInfo(SendPort sendPort) {
  sendPort.send(null);
}

@patch
void _webServerControl(SendPort sendPort, bool enable, bool? silenceOutput) {
  sendPort.send(null);
}

@patch
String? _getIsolateIdFromSendPort(SendPort sendPort) {
  return null;
}

@patch
String? _getObjectId(Object object) {
  return null;
}

@patch
class UserTag {
  @patch
  factory UserTag(String label) = _FakeUserTag;

  @patch
  static UserTag get defaultTag => _FakeUserTag._defaultTag;
}

final class _FakeUserTag implements UserTag {
  static final _instances = <String, _FakeUserTag>{};

  _FakeUserTag.real(this.label);

  factory _FakeUserTag(String label) {
    // Canonicalize by name.
    var existingTag = _instances[label];
    if (existingTag != null) {
      return existingTag;
    }
    // Throw an exception if we've reached the maximum number of user tags.
    if (_instances.length == UserTag.maxUserTags) {
      throw UnsupportedError(
          'UserTag instance limit (${UserTag.maxUserTags}) reached.');
    }
    return _instances[label] = _FakeUserTag.real(label);
  }

  final String label;

  UserTag makeCurrent() {
    var old = _currentTag;
    _currentTag = this;
    return old;
  }

  static final UserTag _defaultTag = _FakeUserTag('Default');
}

var _currentTag = _FakeUserTag._defaultTag;

@patch
UserTag getCurrentTag() => _currentTag;

@patch
abstract final class NativeRuntime {
  @patch
  static String? get buildId => null;

  @patch
  static void writeHeapSnapshotToFile(String filepath) =>
      throw UnsupportedError(
          "Generating heap snapshots is not supported on the web.");
}
