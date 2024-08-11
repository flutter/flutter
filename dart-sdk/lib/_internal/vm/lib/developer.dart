// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Note: the VM concatenates all patch files into a single patch file. This
/// file is the first patch in "dart:developer" which contains all the imports
/// used by patches of that library. We plan to change this when we have a
/// shared front end and simply use parts.

import "dart:_internal" show patch;

import "dart:async" show Future, Zone;

import "dart:isolate" show SendPort;

/// These are the additional parts of this patch library:
part "profiler.dart";
part "timeline.dart";

@patch
@pragma("vm:recognized", "other")
@pragma("vm:external-name", "Developer_debugger")
external bool debugger({bool when = true, String? message});

@patch
@pragma("vm:external-name", "Developer_inspect")
external Object? inspect(Object? object);

@patch
void log(String message,
    {DateTime? time,
    int? sequenceNumber,
    int level = 0,
    String name = '',
    Zone? zone,
    Object? error,
    StackTrace? stackTrace}) {
  if (message is! String) {
    throw new ArgumentError.value(message, "message", "Must be a String");
  }
  time ??= new DateTime.now();
  if (time is! DateTime) {
    throw new ArgumentError.value(time, "time", "Must be a DateTime");
  }
  if (sequenceNumber == null) {
    sequenceNumber = _nextSequenceNumber++;
  } else {
    _nextSequenceNumber = sequenceNumber + 1;
  }
  _log(message, time.millisecondsSinceEpoch, sequenceNumber, level, name, zone,
      error, stackTrace);
}

@patch
@pragma("vm:external-name", "Developer_reachability_barrier")
external int get reachabilityBarrier;

int _nextSequenceNumber = 0;

@pragma("vm:external-name", "Developer_log")
external _log(String message, int timestamp, int sequenceNumber, int level,
    String name, Zone? zone, Object? error, StackTrace? stackTrace);

@patch
@pragma("vm:external-name", "Developer_postEvent")
external void _postEvent(String eventKind, String eventData);

@patch
@pragma("vm:external-name", "Developer_lookupExtension")
external ServiceExtensionHandler? _lookupExtension(String method);

@patch
@pragma("vm:external-name", "Developer_registerExtension")
external _registerExtension(String method, ServiceExtensionHandler handler);

// This code is only invoked when there is no other Dart code on the stack.
@pragma("vm:entry-point", !const bool.fromEnvironment("dart.vm.product"))
_runExtension(
    ServiceExtensionHandler handler,
    String method,
    List<String> parameterKeys,
    List<String> parameterValues,
    SendPort replyPort,
    Object id,
    bool trace_service) {
  var parameters = <String, String>{};
  for (var i = 0; i < parameterKeys.length; i++) {
    parameters[parameterKeys[i]] = parameterValues[i];
  }
  var response;
  try {
    response = handler(method, parameters);
  } catch (e, st) {
    var errorDetails = (st == null) ? '$e' : '$e\n$st';
    response = new ServiceExtensionResponse.error(
        ServiceExtensionResponse.extensionError, errorDetails);
    _postResponse(replyPort, id, response, trace_service);
    return;
  }
  if (response is! Future) {
    response = new ServiceExtensionResponse.error(
        ServiceExtensionResponse.extensionError,
        "Extension handler must return a Future");
    _postResponse(replyPort, id, response, trace_service);
    return;
  }
  response.catchError((e, st) {
    // Catch any errors eagerly and wrap them in a ServiceExtensionResponse.
    var errorDetails = (st == null) ? '$e' : '$e\n$st';
    return new ServiceExtensionResponse.error(
        ServiceExtensionResponse.extensionError, errorDetails);
  }).then((response) {
    // Post the valid response or the wrapped error after verifying that
    // the response is a ServiceExtensionResponse.
    if (response is! ServiceExtensionResponse) {
      response = new ServiceExtensionResponse.error(
          ServiceExtensionResponse.extensionError,
          "Extension handler must complete to a ServiceExtensionResponse");
    }
    _postResponse(replyPort, id, response, trace_service);
  }).catchError((e, st) {
    // We do not expect any errors to occur in the .then or .catchError blocks
    // but, suppress them just in case.
  });
}

// This code is only invoked by _runExtension.
_postResponse(SendPort replyPort, Object id, ServiceExtensionResponse response,
    bool trace_service) {
  assert(replyPort != null);
  if (id == null) {
    if (trace_service) {
      print("vm-service: posting no response for request");
    }
    // No id -> no response.
    replyPort.send(null);
    return;
  }
  assert(id != null);
  StringBuffer sb = new StringBuffer();
  sb.write('{"jsonrpc":"2.0",');
  if (response.isError()) {
    if (trace_service) {
      print("vm-service: posting error response for request $id");
    }
    sb.write('"error":');
  } else {
    if (trace_service) {
      print("vm-service: posting response for request $id");
    }
    sb.write('"result":');
  }
  sb.write('${response._toString()},');
  if (id is String) {
    sb.write('"id":"$id"}');
  } else {
    sb.write('"id":$id}');
  }
  replyPort.send(sb.toString());
}

@patch
@pragma("vm:external-name", "Developer_getServiceMajorVersion")
external int _getServiceMajorVersion();

@patch
@pragma("vm:external-name", "Developer_getServiceMinorVersion")
external int _getServiceMinorVersion();

@patch
@pragma("vm:external-name", "Developer_getServerInfo")
external void _getServerInfo(SendPort sendPort);

@patch
@pragma("vm:external-name", "Developer_webServerControl")
external void _webServerControl(
    SendPort sendPort, bool enable, bool? silenceOutput);

@patch
@pragma("vm:external-name", "Developer_getIsolateIdFromSendPort")
external String? _getIsolateIdFromSendPort(SendPort sendPort);

@patch
@pragma("vm:external-name", "Developer_getObjectId")
external String _getObjectId(Object object);

@patch
abstract final class NativeRuntime {
  @patch
  @pragma("vm:external-name", "Developer_NativeRuntime_buildId")
  external static String? get buildId;

  @patch
  @pragma("vm:external-name", "Developer_NativeRuntime_writeHeapSnapshotToFile")
  external static void writeHeapSnapshotToFile(String filepath);
}
