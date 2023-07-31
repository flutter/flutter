// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:webkit_inspection_protocol/webkit_inspection_protocol.dart';

import 'remote_debugger.dart';

/// A remote debugger with a Webkit Inspection Protocol connection.
class WebkitDebugger implements RemoteDebugger {
  final WipDebugger _wipDebugger;

  /// Null until [close] is called.
  ///
  /// All subsequent calls to [close] will return this future.
  Future<void>? _closed;

  WebkitDebugger(this._wipDebugger);

  @override
  Stream<ConsoleAPIEvent> get onConsoleAPICalled =>
      _wipDebugger.connection.runtime.onConsoleAPICalled;

  @override
  Stream<ExceptionThrownEvent> get onExceptionThrown =>
      _wipDebugger.connection.runtime.onExceptionThrown;

  @override
  Future<WipResponse> sendCommand(String command,
          {Map<String, dynamic>? params}) =>
      _wipDebugger.sendCommand(command, params: params);

  @override
  void close() => _closed ??= _wipDebugger.connection.close();

  @override
  Future<void> disable() => _wipDebugger.disable();

  @override
  Future<void> enable() => _wipDebugger.enable();

  @override
  Future<String> getScriptSource(String scriptId) =>
      _wipDebugger.getScriptSource(scriptId);

  @override
  Future<WipResponse> pause() => _wipDebugger.pause();

  @override
  Future<WipResponse> resume() => _wipDebugger.resume();

  @override
  Future<WipResponse> setPauseOnExceptions(PauseState state) =>
      _wipDebugger.setPauseOnExceptions(state);

  @override
  Future<WipResponse> removeBreakpoint(String breakpointId) =>
      _wipDebugger.removeBreakpoint(breakpointId);

  @override
  Future<WipResponse> stepInto({Map<String, dynamic>? params}) =>
      _wipDebugger.stepInto(params: params);

  @override
  Future<WipResponse> stepOut() => _wipDebugger.stepOut();

  @override
  Future<WipResponse> stepOver({Map<String, dynamic>? params}) =>
      _wipDebugger.stepOver(params: params);

  @override
  Future<WipResponse> enablePage() => _wipDebugger.connection.page.enable();

  @override
  Future<WipResponse> pageReload() => _wipDebugger.connection.page.reload();

  @override
  Future<RemoteObject> evaluate(String expression,
      {bool? returnByValue, int? contextId}) {
    return _wipDebugger.connection.runtime
        .evaluate(expression, returnByValue: returnByValue);
  }

  @override
  Future<RemoteObject> evaluateOnCallFrame(
      String callFrameId, String expression) {
    return _wipDebugger.connection.debugger
        .evaluateOnCallFrame(callFrameId, expression);
  }

  @override
  Future<List<WipBreakLocation>> getPossibleBreakpoints(WipLocation start) {
    return _wipDebugger.connection.debugger.getPossibleBreakpoints(start);
  }

  @override
  Stream<T> eventStream<T>(String method, WipEventTransformer<T> transformer) =>
      _wipDebugger.eventStream(method, transformer);

  @override
  Stream<GlobalObjectClearedEvent> get onGlobalObjectCleared =>
      _wipDebugger.onGlobalObjectCleared;

  @override
  Stream<DebuggerPausedEvent> get onPaused => _wipDebugger.onPaused;

  @override
  Stream<DebuggerResumedEvent> get onResumed => _wipDebugger.onResumed;

  @override
  Stream<ScriptParsedEvent> get onScriptParsed => _wipDebugger.onScriptParsed;

  @override
  Stream<TargetCrashedEvent> get onTargetCrashed => _wipDebugger.eventStream(
      'Inspector.targetCrashed',
      (WipEvent event) => TargetCrashedEvent(event.json));

  @override
  Map<String, WipScript> get scripts => _wipDebugger.scripts;

  @override
  Stream<WipConnection> get onClose => _wipDebugger.connection.onClose;
}
