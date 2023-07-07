// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:webkit_inspection_protocol/webkit_inspection_protocol.dart';

class TargetCrashedEvent extends WipEvent {
  TargetCrashedEvent(Map<String, dynamic> json) : super(json);
}

/// A generic debugger used in remote debugging.
abstract class RemoteDebugger {
  Stream<ConsoleAPIEvent> get onConsoleAPICalled;

  Stream<ExceptionThrownEvent> get onExceptionThrown;

  Stream<GlobalObjectClearedEvent> get onGlobalObjectCleared;

  Stream<DebuggerPausedEvent> get onPaused;

  Stream<DebuggerResumedEvent> get onResumed;

  Stream<ScriptParsedEvent> get onScriptParsed;

  Stream<TargetCrashedEvent> get onTargetCrashed;

  Map<String, WipScript> get scripts;

  Stream<void> get onClose;

  Future<WipResponse> sendCommand(String command,
      {Map<String, dynamic>? params});

  Future<void> disable();

  Future<void> enable();

  Future<String> getScriptSource(String scriptId);

  Future<WipResponse> pause();

  Future<WipResponse> resume();

  Future<WipResponse> setPauseOnExceptions(PauseState state);

  Future<WipResponse> removeBreakpoint(String breakpointId);

  Future<WipResponse> stepInto({Map<String, dynamic>? params});

  Future<WipResponse> stepOut();

  Future<WipResponse> stepOver({Map<String, dynamic>? params});

  Future<WipResponse> enablePage();

  Future<WipResponse> pageReload();

  Future<RemoteObject> evaluate(String expression,
      {bool? returnByValue, int? contextId});

  Future<RemoteObject> evaluateOnCallFrame(
      String callFrameId, String expression);

  Future<List<WipBreakLocation>> getPossibleBreakpoints(WipLocation start);

  Stream<T> eventStream<T>(String method, WipEventTransformer<T> transformer);

  void close();
}
