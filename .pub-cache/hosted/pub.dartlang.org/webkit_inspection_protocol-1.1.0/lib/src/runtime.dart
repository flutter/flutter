// Copyright 2015 Google. All rights reserved. Use of this source code is
// governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:math';

import '../webkit_inspection_protocol.dart';

class WipRuntime extends WipDomain {
  WipRuntime(WipConnection connection) : super(connection);

  /// Enables reporting of execution contexts creation by means of
  /// executionContextCreated event. When the reporting gets enabled the event
  /// will be sent immediately for each existing execution context.
  Future<WipResponse> enable() => sendCommand('Runtime.enable');

  /// Disables reporting of execution contexts creation.
  Future<WipResponse> disable() => sendCommand('Runtime.disable');

  /// Evaluates expression on global object.
  ///
  /// - `returnByValue`: Whether the result is expected to be a JSON object that
  ///    should be sent by value.
  /// - `contextId`: Specifies in which execution context to perform evaluation.
  ///    If the parameter is omitted the evaluation will be performed in the
  ///    context of the inspected page.
  ///  - `awaitPromise`: Whether execution should await for resulting value and
  ///     return once awaited promise is resolved.
  Future<RemoteObject> evaluate(
    String expression, {
    bool? returnByValue,
    int? contextId,
    bool? awaitPromise,
  }) async {
    Map<String, dynamic> params = {
      'expression': expression,
    };
    if (returnByValue != null) {
      params['returnByValue'] = returnByValue;
    }
    if (contextId != null) {
      params['contextId'] = contextId;
    }
    if (awaitPromise != null) {
      params['awaitPromise'] = awaitPromise;
    }

    final WipResponse response =
        await sendCommand('Runtime.evaluate', params: params);

    if (response.result!.containsKey('exceptionDetails')) {
      throw ExceptionDetails(
          response.result!['exceptionDetails'] as Map<String, dynamic>);
    } else {
      return RemoteObject(response.result!['result'] as Map<String, dynamic>);
    }
  }

  /// Calls function with given declaration on the given object. Object group of
  /// the result is inherited from the target object.
  ///
  /// Each element in [arguments] must be either a [RemoteObject] or a primitive
  /// object (int, String, double, bool).
  Future<RemoteObject> callFunctionOn(
    String functionDeclaration, {
    String? objectId,
    List<dynamic>? arguments,
    bool? returnByValue,
    int? executionContextId,
  }) async {
    Map<String, dynamic> params = {
      'functionDeclaration': functionDeclaration,
    };
    if (objectId != null) {
      params['objectId'] = objectId;
    }
    if (returnByValue != null) {
      params['returnByValue'] = returnByValue;
    }
    if (executionContextId != null) {
      params['executionContextId'] = executionContextId;
    }
    if (arguments != null) {
      // Convert a list of RemoteObjects and primitive values to CallArguments.
      params['arguments'] = arguments.map((dynamic value) {
        if (value is RemoteObject) {
          return {'objectId': value.objectId};
        } else {
          return {'value': value};
        }
      }).toList();
    }

    final WipResponse response =
        await sendCommand('Runtime.callFunctionOn', params: params);

    if (response.result!.containsKey('exceptionDetails')) {
      throw ExceptionDetails(
          response.result!['exceptionDetails'] as Map<String, dynamic>);
    } else {
      return RemoteObject(response.result!['result'] as Map<String, dynamic>);
    }
  }

  /// Returns the JavaScript heap usage. It is the total usage of the
  /// corresponding isolate not scoped to a particular Runtime.
  @experimental
  Future<HeapUsage> getHeapUsage() async {
    final WipResponse response = await sendCommand('Runtime.getHeapUsage');
    return HeapUsage(response.result!);
  }

  /// Returns the isolate id.
  @experimental
  Future<String> getIsolateId() async {
    return (await sendCommand('Runtime.getIsolateId')).result!['id'] as String;
  }

  /// Returns properties of a given object. Object group of the result is
  /// inherited from the target object.
  ///
  /// objectId: Identifier of the object to return properties for.
  ///
  /// ownProperties: If true, returns properties belonging only to the element
  /// itself, not to its prototype chain.
  Future<List<PropertyDescriptor>> getProperties(
    RemoteObject object, {
    bool? ownProperties,
  }) async {
    Map<String, dynamic> params = {
      'objectId': object.objectId,
    };
    if (ownProperties != null) {
      params['ownProperties'] = ownProperties;
    }

    final WipResponse response =
        await sendCommand('Runtime.getProperties', params: params);

    if (response.result!.containsKey('exceptionDetails')) {
      throw ExceptionDetails(
          response.result!['exceptionDetails'] as Map<String, dynamic>);
    } else {
      List locations = response.result!['result'];
      return List.from(locations.map((map) => PropertyDescriptor(map)));
    }
  }

  Stream<ConsoleAPIEvent> get onConsoleAPICalled => eventStream(
      'Runtime.consoleAPICalled',
      (WipEvent event) => ConsoleAPIEvent(event.json));

  Stream<ExceptionThrownEvent> get onExceptionThrown => eventStream(
      'Runtime.exceptionThrown',
      (WipEvent event) => ExceptionThrownEvent(event.json));

  /// Issued when new execution context is created.
  Stream<ExecutionContextDescription> get onExecutionContextCreated =>
      eventStream(
          'Runtime.executionContextCreated',
          (WipEvent event) =>
              ExecutionContextDescription(event.params!['context']));

  /// Issued when execution context is destroyed.
  Stream<String> get onExecutionContextDestroyed => eventStream(
      'Runtime.executionContextDestroyed',
      (WipEvent event) => event.params!['executionContextId']);

  /// Issued when all executionContexts were cleared in browser.
  Stream get onExecutionContextsCleared => eventStream(
      'Runtime.executionContextsCleared', (WipEvent event) => event);
}

// TODO: stackTrace, StackTrace, Stack trace captured when the call was made.
class ConsoleAPIEvent extends WipEvent {
  ConsoleAPIEvent(Map<String, dynamic> json) : super(json);

  /// Type of the call. Allowed values: log, debug, info, error, warning, dir,
  /// dirxml, table, trace, clear, startGroup, startGroupCollapsed, endGroup,
  /// assert, profile, profileEnd.
  String get type => params!['type'] as String;

  /// Call timestamp.
  num get timestamp => params!['timestamp'] as num;

  /// Call arguments.
  List<RemoteObject> get args => (params!['args'] as List)
      .map((m) => RemoteObject(m as Map<String, dynamic>))
      .toList();
}

/// Description of an isolated world.
class ExecutionContextDescription {
  final Map<String, dynamic> json;

  ExecutionContextDescription(this.json);

  /// Unique id of the execution context. It can be used to specify in which
  /// execution context script evaluation should be performed.
  int get id => json['id'] as int;

  /// Execution context origin.
  String get origin => json['origin'];

  /// Human readable name describing given context.
  String get name => json['name'];
}

class ExceptionThrownEvent extends WipEvent {
  ExceptionThrownEvent(Map<String, dynamic> json) : super(json);

  /// Timestamp of the exception.
  int get timestamp => params!['timestamp'] as int;

  ExceptionDetails get exceptionDetails =>
      ExceptionDetails(params!['exceptionDetails'] as Map<String, dynamic>);
}

class ExceptionDetails implements Exception {
  final Map<String, dynamic> json;

  ExceptionDetails(this.json);

  /// Exception id.
  int get exceptionId => json['exceptionId'] as int;

  /// Exception text, which should be used together with exception object when
  /// available.
  String get text => json['text'] as String;

  /// Line number of the exception location (0-based).
  int get lineNumber => json['lineNumber'] as int;

  /// Column number of the exception location (0-based).
  int get columnNumber => json['columnNumber'] as int;

  /// URL of the exception location, to be used when the script was not
  /// reported.
  @optional
  String get url => json['url'] as String;

  /// Script ID of the exception location.
  @optional
  String? get scriptId => json['scriptId'] as String?;

  /// JavaScript stack trace if available.
  @optional
  StackTrace? get stackTrace => json['stackTrace'] == null
      ? null
      : StackTrace(json['stackTrace'] as Map<String, dynamic>);

  /// Exception object if available.
  @optional
  RemoteObject? get exception => json['exception'] == null
      ? null
      : RemoteObject(json['exception'] as Map<String, dynamic>);

  @override
  String toString() => '$text, $url, $scriptId, $lineNumber, $exception';
}

/// Call frames for assertions or error messages.
class StackTrace {
  final Map<String, dynamic> json;

  StackTrace(this.json);

  List<CallFrame> get callFrames => (json['callFrames'] as List)
      .map((m) => CallFrame(m as Map<String, dynamic>))
      .toList();

  /// String label of this stack trace. For async traces this may be a name of
  /// the function that initiated the async call.
  @optional
  String get description => json['description'] as String;

  /// Asynchronous JavaScript stack trace that preceded this stack, if
  /// available.
  @optional
  StackTrace? get parent {
    return json['parent'] == null ? null : StackTrace(json['parent']);
  }

  List<String> printFrames() {
    List<CallFrame> frames = callFrames;

    int width = frames.fold(0, (int val, CallFrame frame) {
      return max(val, frame.functionName.length);
    });

    return frames.map((CallFrame frame) {
      var name = '${frame.functionName}()'.padRight(width + 2);
      return '$name ${frame.url} ${frame.lineNumber}:${frame.columnNumber}';
    }).toList();
  }

  @override
  String toString() => callFrames.map((f) => '  $f').join('\n');
}

/// Stack entry for runtime errors and assertions.
///
/// This class is for the 'runtime' domain.
class CallFrame {
  final Map<String, dynamic> json;

  CallFrame(this.json);

  /// JavaScript function name.
  String get functionName => json['functionName'] as String;

  /// JavaScript script id.
  String get scriptId => json['scriptId'] as String;

  /// JavaScript script name or url.
  String get url => json['url'] as String;

  /// JavaScript script line number (0-based).
  int get lineNumber => json['lineNumber'] as int;

  /// JavaScript script column number (0-based).
  int get columnNumber => json['columnNumber'] as int;

  @override
  String toString() => '$functionName() ($url $lineNumber:$columnNumber)';
}

/// Mirror object referencing original JavaScript object.
class RemoteObject {
  final Map<String, dynamic> json;

  RemoteObject(this.json);

  /// Object type.
  ///
  /// Allowed Values: object, function, undefined, string, number, boolean,
  /// symbol, bigint, wasm.
  String get type => json['type'] as String;

  /// Object subtype hint. Specified for object or wasm type values only.
  ///
  /// Allowed Values: array, null, node, regexp, date, map, set, weakmap,
  /// weakset, iterator, generator, error, proxy, promise, typedarray,
  /// arraybuffer, dataview, i32, i64, f32, f64, v128, anyref.
  String? get subtype => json['subtype'] as String?;

  /// Object class (constructor) name.
  ///
  /// Specified for object type values only.
  String? get className => json['className'] as String?;

  /// Remote object value in case of primitive values or JSON values (if it was
  /// requested). (optional)
  Object? get value => json['value'];

  /// String representation of the object. (optional)
  String? get description => json['description'] as String?;

  /// Unique object identifier (for non-primitive values). (optional)
  String? get objectId => json['objectId'] as String?;

  @override
  String toString() => '$type $value';
}

/// Returns the JavaScript heap usage. It is the total usage of the
/// corresponding isolate not scoped to a particular Runtime.
class HeapUsage {
  final Map<String, dynamic> json;

  HeapUsage(this.json);

  /// Used heap size in bytes.
  int get usedSize => json['usedSize'];

  /// Allocated heap size in bytes.
  int get totalSize => json['totalSize'];

  @override
  String toString() => '$usedSize of $totalSize';
}

/// Object property descriptor.
class PropertyDescriptor {
  final Map<String, dynamic> json;

  PropertyDescriptor(this.json);

  /// Property name or symbol description.
  String get name => json['name'];

  /// The value associated with the property.
  RemoteObject? get value =>
      json['value'] != null ? RemoteObject(json['value']) : null;

  /// True if the value associated with the property may be changed (data
  /// descriptors only).
  bool? get writable => json['writable'] as bool?;

  /// True if the type of this property descriptor may be changed and if the
  /// property may be deleted from the corresponding object.
  bool get configurable => json['configurable'] as bool;

  /// True if this property shows up during enumeration of the properties on the
  /// corresponding object.
  bool get enumerable => json['enumerable'] as bool;

  /// True if the result was thrown during the evaluation.
  bool? get wasThrown => json['wasThrown'] as bool?;

  /// True if the property is owned for the object.
  bool? get isOwn => json['isOwn'] as bool?;
}
