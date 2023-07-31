// Copyright 2015 Google. All rights reserved. Use of this source code is
// governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:collection';

import '../webkit_inspection_protocol.dart';

class WipDebugger extends WipDomain {
  final _scripts = <String, WipScript>{};

  WipDebugger(WipConnection connection) : super(connection) {
    onScriptParsed.listen((event) {
      _scripts[event.script.scriptId] = event.script;
    });
    onGlobalObjectCleared.listen((_) {
      _scripts.clear();
    });
  }

  Future<WipResponse> enable() => sendCommand('Debugger.enable');

  Future<WipResponse> disable() => sendCommand('Debugger.disable');

  Future<String> getScriptSource(String scriptId) async {
    return (await sendCommand('Debugger.getScriptSource',
            params: {'scriptId': scriptId}))
        .result!['scriptSource'] as String;
  }

  Future<WipResponse> pause() => sendCommand('Debugger.pause');

  Future<WipResponse> resume() => sendCommand('Debugger.resume');

  Future<WipResponse> stepInto({Map<String, dynamic>? params}) =>
      sendCommand('Debugger.stepInto', params: params);

  Future<WipResponse> stepOut() => sendCommand('Debugger.stepOut');

  Future<WipResponse> stepOver({Map<String, dynamic>? params}) =>
      sendCommand('Debugger.stepOver', params: params);

  Future<WipResponse> setPauseOnExceptions(PauseState state) {
    return sendCommand('Debugger.setPauseOnExceptions',
        params: {'state': _pauseStateToString(state)});
  }

  /// Sets JavaScript breakpoint at a given location.
  ///
  /// - `location`: Location to set breakpoint in
  /// - `condition`: Expression to use as a breakpoint condition. When
  ///    specified, debugger will only stop on the breakpoint if this expression
  ///    evaluates to true.
  Future<SetBreakpointResponse> setBreakpoint(
    WipLocation location, {
    String? condition,
  }) async {
    Map<String, dynamic> params = {
      'location': location.toJsonMap(),
    };
    if (condition != null) {
      params['condition'] = condition;
    }

    final WipResponse response =
        await sendCommand('Debugger.setBreakpoint', params: params);

    if (response.result!.containsKey('exceptionDetails')) {
      throw ExceptionDetails(
          response.result!['exceptionDetails'] as Map<String, dynamic>);
    } else {
      return SetBreakpointResponse(response.json);
    }
  }

  /// Removes JavaScript breakpoint.
  Future<WipResponse> removeBreakpoint(String breakpointId) {
    return sendCommand('Debugger.removeBreakpoint',
        params: {'breakpointId': breakpointId});
  }

  /// Evaluates expression on a given call frame.
  ///
  /// - `callFrameId`: Call frame identifier to evaluate on
  /// - `expression`: Expression to evaluate
  /// - `returnByValue`: Whether the result is expected to be a JSON object that
  ///   should be sent by value
  Future<RemoteObject> evaluateOnCallFrame(
    String callFrameId,
    String expression, {
    bool? returnByValue,
  }) async {
    Map<String, dynamic> params = {
      'callFrameId': callFrameId,
      'expression': expression,
    };
    if (returnByValue != null) {
      params['returnByValue'] = returnByValue;
    }

    final WipResponse response =
        await sendCommand('Debugger.evaluateOnCallFrame', params: params);

    if (response.result!.containsKey('exceptionDetails')) {
      throw ExceptionDetails(
          response.result!['exceptionDetails'] as Map<String, dynamic>);
    } else {
      return RemoteObject(response.result!['result'] as Map<String, dynamic>);
    }
  }

  /// Returns possible locations for breakpoint. scriptId in start and end range
  /// locations should be the same.
  ///
  /// - `start`: Start of range to search possible breakpoint locations in
  /// - `end`: End of range to search possible breakpoint locations in
  ///   (excluding). When not specified, end of scripts is used as end of range.
  /// - `restrictToFunction`: Only consider locations which are in the same
  ///   (non-nested) function as start.
  Future<List<WipBreakLocation>> getPossibleBreakpoints(
    WipLocation start, {
    WipLocation? end,
    bool? restrictToFunction,
  }) async {
    Map<String, dynamic> params = {
      'start': start.toJsonMap(),
    };
    if (end != null) {
      params['end'] = end.toJsonMap();
    }
    if (restrictToFunction != null) {
      params['restrictToFunction'] = restrictToFunction;
    }

    final WipResponse response =
        await sendCommand('Debugger.getPossibleBreakpoints', params: params);

    if (response.result!.containsKey('exceptionDetails')) {
      throw ExceptionDetails(
          response.result!['exceptionDetails'] as Map<String, dynamic>);
    } else {
      List locations = response.result!['locations'];
      return List.from(locations.map((map) => WipBreakLocation(map)));
    }
  }

  /// Enables or disables async call stacks tracking.
  ///
  /// maxDepth - Maximum depth of async call stacks. Setting to 0 will
  /// effectively disable collecting async call stacks (default).
  Future<WipResponse> setAsyncCallStackDepth(int maxDepth) {
    return sendCommand('Debugger.setAsyncCallStackDepth', params: {
      'maxDepth': maxDepth,
    });
  }

  Stream<DebuggerPausedEvent> get onPaused => eventStream(
      'Debugger.paused', (WipEvent event) => DebuggerPausedEvent(event.json));

  Stream<GlobalObjectClearedEvent> get onGlobalObjectCleared => eventStream(
      'Debugger.globalObjectCleared',
      (WipEvent event) => GlobalObjectClearedEvent(event.json));

  Stream<DebuggerResumedEvent> get onResumed => eventStream(
      'Debugger.resumed', (WipEvent event) => DebuggerResumedEvent(event.json));

  Stream<ScriptParsedEvent> get onScriptParsed => eventStream(
      'Debugger.scriptParsed',
      (WipEvent event) => ScriptParsedEvent(event.json));

  Map<String, WipScript> get scripts => UnmodifiableMapView(_scripts);
}

String _pauseStateToString(PauseState state) {
  switch (state) {
    case PauseState.all:
      return 'all';
    case PauseState.none:
      return 'none';
    case PauseState.uncaught:
      return 'uncaught';
    default:
      throw ArgumentError('unknown state: $state');
  }
}

enum PauseState { all, none, uncaught }

class ScriptParsedEvent extends WipEvent {
  ScriptParsedEvent(Map<String, dynamic> json) : super(json);

  WipScript get script => WipScript(params!);

  @override
  String toString() => script.toString();
}

class GlobalObjectClearedEvent extends WipEvent {
  GlobalObjectClearedEvent(Map<String, dynamic> json) : super(json);
}

class DebuggerResumedEvent extends WipEvent {
  DebuggerResumedEvent(Map<String, dynamic> json) : super(json);
}

/// Fired when the virtual machine stopped on breakpoint or exception or any
/// other stop criteria.
class DebuggerPausedEvent extends WipEvent {
  DebuggerPausedEvent(Map<String, dynamic> json) : super(json);

  /// Call stack the virtual machine stopped on.
  List<WipCallFrame> getCallFrames() => (params!['callFrames'] as List)
      .map((frame) => WipCallFrame(frame as Map<String, dynamic>))
      .toList();

  /// Pause reason.
  ///
  /// Allowed Values: ambiguous, assert, debugCommand, DOM, EventListener,
  /// exception, instrumentation, OOM, other, promiseRejection, XHR.
  String get reason => params!['reason'] as String;

  /// Object containing break-specific auxiliary properties.
  Object? get data => params!['data'];

  /// Hit breakpoints IDs (optional).
  List<String>? get hitBreakpoints {
    if (params!['hitBreakpoints'] == null) return null;
    return (params!['hitBreakpoints'] as List).cast<String>();
  }

  /// Async stack trace, if any.
  StackTrace? get asyncStackTrace => params!['asyncStackTrace'] == null
      ? null
      : StackTrace(params!['asyncStackTrace']);

  @override
  String toString() => 'paused: $reason';
}

/// A debugger call frame.
///
/// This class is for the 'debugger' domain.
class WipCallFrame {
  final Map<String, dynamic> json;

  WipCallFrame(this.json);

  /// Call frame identifier.
  ///
  /// This identifier is only valid while the virtual machine is paused.
  String get callFrameId => json['callFrameId'] as String;

  /// Name of the JavaScript function called on this call frame.
  String get functionName => json['functionName'] as String;

  /// Location in the source code.
  WipLocation get location =>
      WipLocation(json['location'] as Map<String, dynamic>);

  /// JavaScript script name or url.
  String get url => json['url'] as String;

  /// Scope chain for this call frame.
  Iterable<WipScope> getScopeChain() => (json['scopeChain'] as List)
      .map((scope) => WipScope(scope as Map<String, dynamic>));

  /// `this` object for this call frame.
  RemoteObject get thisObject =>
      RemoteObject(json['this'] as Map<String, dynamic>);

  /// The value being returned, if the function is at return point.
  ///
  /// (optional)
  RemoteObject? get returnValue {
    return json.containsKey('returnValue')
        ? RemoteObject(json['returnValue'] as Map<String, dynamic>)
        : null;
  }

  @override
  String toString() => '[$functionName]';
}

class WipLocation {
  final Map<String, dynamic> json;

  WipLocation(this.json);

  WipLocation.fromValues(String scriptId, int lineNumber, {int? columnNumber})
      : json = {} {
    json['scriptId'] = scriptId;
    json['lineNumber'] = lineNumber;
    if (columnNumber != null) {
      json['columnNumber'] = columnNumber;
    }
  }

  String get scriptId => json['scriptId'];

  int get lineNumber => json['lineNumber'];

  int? get columnNumber => json['columnNumber'];

  Map<String, dynamic> toJsonMap() {
    return json;
  }

  @override
  String toString() => '[$scriptId:$lineNumber:$columnNumber]';
}

class WipScript {
  final Map<String, dynamic> json;

  WipScript(this.json);

  String get scriptId => json['scriptId'] as String;

  String get url => json['url'] as String;

  int get startLine => json['startLine'] as int;

  int get startColumn => json['startColumn'] as int;

  int get endLine => json['endLine'] as int;

  int get endColumn => json['endColumn'] as int;

  bool? get isContentScript => json['isContentScript'] as bool?;

  String? get sourceMapURL => json['sourceMapURL'] as String?;

  @override
  String toString() => '[script $scriptId: $url]';
}

class WipScope {
  final Map<String, dynamic> json;

  WipScope(this.json);

  // "catch", "closure", "global", "local", "with"
  String get scope => json['type'] as String;

  /// Name of the scope, null if unnamed closure or global scope
  String? get name => json['name'] as String?;

  /// Object representing the scope. For global and with scopes it represents
  /// the actual object; for the rest of the scopes, it is artificial transient
  /// object enumerating scope variables as its properties.
  RemoteObject get object =>
      RemoteObject(json['object'] as Map<String, dynamic>);
}

class WipBreakLocation extends WipLocation {
  WipBreakLocation(Map<String, dynamic> json) : super(json);

  WipBreakLocation.fromValues(String scriptId, int lineNumber,
      {int? columnNumber, String? type})
      : super.fromValues(scriptId, lineNumber, columnNumber: columnNumber) {
    if (type != null) {
      json['type'] = type;
    }
  }

  /// Allowed Values: `debuggerStatement`, `call`, `return`.
  String? get type => json['type'] as String?;
}

/// The response from [WipDebugger.setBreakpoint].
class SetBreakpointResponse extends WipResponse {
  SetBreakpointResponse(Map<String, dynamic> json) : super(json);

  String get breakpointId => result!['breakpointId'];

  WipLocation get actualLocation => WipLocation(result!['actualLocation']);
}
