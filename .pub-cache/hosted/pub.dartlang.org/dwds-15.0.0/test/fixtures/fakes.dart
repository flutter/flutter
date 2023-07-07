// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

import 'dart:async';

import 'package:dwds/dwds.dart';
import 'package:dwds/src/debugging/execution_context.dart';
import 'package:dwds/src/debugging/inspector.dart';
import 'package:dwds/src/debugging/instance.dart';
import 'package:dwds/src/debugging/modules.dart';
import 'package:dwds/src/debugging/remote_debugger.dart';
import 'package:dwds/src/debugging/webkit_debugger.dart';
import 'package:dwds/src/loaders/strategy.dart';
import 'package:dwds/src/utilities/domain.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:vm_service/vm_service.dart';

/// A library of fake/stub implementations of our classes and their supporting
/// classes (e.g. WipConnection) for unit testing.
import 'package:webkit_inspection_protocol/webkit_inspection_protocol.dart';

import 'debugger_data.dart';

/// Constructs a trivial Isolate we can use when we need to provide one but
/// don't want go through initialization.
Isolate get simpleIsolate => Isolate(
      id: '1',
      number: '1',
      name: 'fake',
      libraries: [],
      exceptionPauseMode: 'abc',
      breakpoints: [],
      pauseOnExit: false,
      pauseEvent: null,
      startTime: 0,
      livePorts: 0,
      runnable: false,
      isSystemIsolate: false,
      isolateFlags: [],
    );

class FakeInspector extends Domain implements AppInspector {
  FakeInspector({this.fakeIsolate}) : super.forInspector();

  Isolate fakeIsolate;

  @override
  Object noSuchMethod(Invocation invocation) {
    throw UnsupportedError('This is a fake');
  }

  @override
  Future<RemoteObject> evaluate(
          String isolateId, String targetId, String expression,
          {Map<String, String> scope}) =>
      null;

  @override
  Future<Obj> getObject(String isolateId, String objectId,
          {int offset, int count}) =>
      null;

  @override
  Future<ScriptList> getScripts(String isolateId) => null;

  @override
  Future<ScriptRef> scriptRefFor(String uri) =>
      Future.value(ScriptRef(id: 'fake', uri: 'fake://uri'));

  @override
  ScriptRef scriptWithId(String scriptId) => null;

  @override
  Isolate checkIsolate(String methodName, String isolateId) => fakeIsolate;

  @override
  Isolate get isolate => fakeIsolate;

  @override
  IsolateRef get isolateRef => null;

  @override
  InstanceHelper get instanceHelper => InstanceHelper(null);
}

class FakeSseConnection implements SseSocketConnection {
  /// A [StreamController] for incoming messages on SSE connection.
  final controllerIncoming = StreamController<String>();

  /// A [StreamController] for outgoing messages on SSE connection.
  final controllerOutgoing = StreamController<String>();

  @override
  bool get isInKeepAlivePeriod => false;

  @override
  StreamSink<String> get sink => controllerOutgoing.sink;

  @override
  Stream<String> get stream => controllerIncoming.stream;

  @override
  void shutdown() {}
}

class FakeModules implements Modules {
  @override
  void initialize(String entrypoint) {}

  @override
  Future<Uri> libraryForSource(String serverPath) {
    throw UnimplementedError();
  }

  @override
  Future<String> moduleForSource(String serverPath) {
    throw UnimplementedError();
  }

  @override
  Future<Map<String, String>> modules() {
    throw UnimplementedError();
  }

  @override
  Future<String> moduleForlibrary(String libraryUri) {
    throw UnimplementedError();
  }
}

class FakeWebkitDebugger implements WebkitDebugger {
  final Map<String, WipScript> _scripts;
  @override
  Future disable() => null;

  @override
  Future enable() => null;

  FakeWebkitDebugger({Map<String, WipScript> scripts}) : _scripts = scripts {
    globalLoadStrategy = RequireStrategy(
        ReloadConfiguration.none,
        (_) async => {},
        (_) async => {},
        (_, __) async => null,
        (_, __) async => null,
        (_, __) async => null,
        null,
        (_) async => null,
        null);
  }

  @override
  Stream<T> eventStream<T>(String method, WipEventTransformer<T> transformer) =>
      null;

  @override
  Future<String> getScriptSource(String scriptId) => null;

  Stream<WipDomain> get onClosed => null;

  @override
  Stream<GlobalObjectClearedEvent> get onGlobalObjectCleared => null;

  @override
  Stream<DebuggerPausedEvent> onPaused;

  @override
  Stream<DebuggerResumedEvent> get onResumed => null;

  @override
  Stream<ScriptParsedEvent> get onScriptParsed => null;

  @override
  Stream<TargetCrashedEvent> get onTargetCrashed => null;

  @override
  Future<WipResponse> pause() => null;

  @override
  Future<WipResponse> resume() => null;

  @override
  Map<String, WipScript> get scripts => _scripts;

  List<WipResponse> results = variables1;
  int resultsReturned = 0;

  @override
  Future<WipResponse> sendCommand(
    String method, {
    Map<String, dynamic> params,
  }) async {
    // Force the results that we expect for looking up the variables.
    if (method == 'Runtime.getProperties') {
      return results[resultsReturned++];
    }
    return null;
  }

  @override
  Future<WipResponse> setPauseOnExceptions(PauseState state) => null;

  @override
  Future<WipResponse> removeBreakpoint(String breakpointId) => null;

  @override
  Future<WipResponse> stepInto({Map<String, dynamic> params}) => null;

  @override
  Future<WipResponse> stepOut() => null;

  @override
  Future<WipResponse> stepOver({Map<String, dynamic> params}) => null;

  @override
  Stream<ConsoleAPIEvent> get onConsoleAPICalled => null;

  @override
  Stream<ExceptionThrownEvent> get onExceptionThrown => null;

  @override
  void close() {}

  @override
  Stream<WipConnection> get onClose => null;

  @override
  Future<RemoteObject> evaluate(String expression,
          {bool returnByValue, int contextId}) =>
      null;

  @override
  Future<RemoteObject> evaluateOnCallFrame(
      String callFrameId, String expression) async {
    return RemoteObject(<String, dynamic>{});
  }

  @override
  Future<List<WipBreakLocation>> getPossibleBreakpoints(WipLocation start) =>
      null;

  @override
  Future<WipResponse> enablePage() => null;

  @override
  Future<WipResponse> pageReload() => null;
}

/// Fake execution context that is needed for id only
class FakeExecutionContext extends ExecutionContext {
  @override
  Future<int> get id async {
    return 0;
  }

  FakeExecutionContext();
}

class FakeStrategy implements LoadStrategy {
  @override
  Future<String> bootstrapFor(String entrypoint) async => 'dummy_bootstrap';

  @override
  shelf.Handler get handler =>
      (request) => (request.url.path == 'someDummyPath')
          ? shelf.Response.ok('some dummy response')
          : shelf.Response.notFound('someDummyPath');

  @override
  String get id => 'dummy-id';

  @override
  String get moduleFormat => 'dummy-format';

  @override
  String get loadLibrariesModule => '';

  @override
  String get loadLibrariesSnippet => '';

  @override
  String loadLibrarySnippet(String libraryUri) => '';

  @override
  String get loadModuleSnippet => '';

  @override
  ReloadConfiguration get reloadConfiguration => ReloadConfiguration.none;

  @override
  String loadClientSnippet(String clientScript) => 'dummy-load-client-snippet';

  @override
  Future<String> moduleForServerPath(String entrypoint, String serverPath) =>
      null;

  @override
  Future<String> serverPathForModule(String entrypoint, String module) => null;

  @override
  Future<String> sourceMapPathForModule(String entrypoint, String module) =>
      null;

  @override
  String serverPathForAppUri(String appUri) => null;

  @override
  MetadataProvider metadataProviderFor(String entrypoint) => null;

  @override
  void trackEntrypoint(String entrypoint) {}

  @override
  Future<Map<String, ModuleInfo>> moduleInfoForEntrypoint(String entrypoint) =>
      throw UnimplementedError();
}
