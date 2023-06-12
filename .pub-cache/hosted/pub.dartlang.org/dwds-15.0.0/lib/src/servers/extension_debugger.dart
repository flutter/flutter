// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:webkit_inspection_protocol/webkit_inspection_protocol.dart';

import '../../data/devtools_request.dart';
import '../../data/extension_request.dart';
import '../../data/serializers.dart';
import '../debugging/execution_context.dart';
import '../debugging/remote_debugger.dart';
import '../handlers/socket_connections.dart';
import '../services/chrome_debug_exception.dart';

/// A remote debugger backed by the Dart Debug Extension with an SSE connection.
class ExtensionDebugger implements RemoteDebugger {
  /// A connection between the debugger and the background of
  /// Dart Debug Extension
  final SocketConnection sseConnection;

  /// A map from id to a completer associated with an [ExtensionRequest]
  final _completers = <int, Completer>{};
  final _eventStreams = <String, Stream>{};
  var _completerId = 0;

  /// Null until [close] is called.
  ///
  /// All subsequent calls to [close] will return this future.
  Future<void>? _closed;

  String? instanceId;
  ExecutionContext? _executionContext;

  ExecutionContext? get executionContext => _executionContext;

  final _devToolsRequestController = StreamController<DevToolsRequest>();

  Stream<DevToolsRequest> get devToolsRequestStream =>
      _devToolsRequestController.stream;

  final _notificationController = StreamController<WipEvent>.broadcast();

  Stream<WipEvent> get onNotification => _notificationController.stream;

  final _closeController = StreamController<WipEvent>.broadcast();

  @override
  Stream<WipEvent> get onClose => _closeController.stream;

  @override
  Stream<ConsoleAPIEvent> get onConsoleAPICalled => eventStream(
      'Runtime.consoleAPICalled',
      (WipEvent event) => ConsoleAPIEvent(event.json));

  @override
  Stream<ExceptionThrownEvent> get onExceptionThrown => eventStream(
      'Runtime.exceptionThrown',
      (WipEvent event) => ExceptionThrownEvent(event.json));

  final _scripts = <String, WipScript>{};
  final _scriptIds = <String, String>{};

  ExtensionDebugger(this.sseConnection) {
    sseConnection.stream.listen((data) {
      final message = serializers.deserialize(jsonDecode(data));
      if (message is ExtensionResponse) {
        final encodedResult = {
          'result': json.decode(message.result),
          'id': message.id
        };
        final completer = _completers[message.id];
        if (completer == null) {
          throw StateError('Missing completer.');
        }
        // TODO(#988): Call completeError(WipError()) to match the behavior of
        // package:webkit_inspection_protocol.
        completer.complete(WipResponse(encodedResult));
      } else if (message is ExtensionEvent) {
        final map = {
          'method': json.decode(message.method),
          'params': json.decode(message.params)
        };
        // Note: package:sse will try to keep the connection alive, even after
        // the client has been closed. Therefore the extension sends an event to
        // notify DWDS that we should close the connection, instead of relying
        // on the done event sent when the client is closed. See details:
        // https://github.com/dart-lang/webdev/pull/1595#issuecomment-1116773378
        if (map['method'] == 'DebugExtension.detached') {
          close();
        } else {
          _notificationController.sink.add(WipEvent(map));
        }
      } else if (message is BatchedEvents) {
        for (var event in message.events) {
          final map = {
            'method': json.decode(event.method),
            'params': json.decode(event.params)
          };
          _notificationController.sink.add(WipEvent(map));
        }
      } else if (message is DevToolsRequest) {
        instanceId = message.instanceId;
        _executionContext =
            RemoteDebuggerExecutionContext(message.contextId, this);
        _devToolsRequestController.sink.add(message);
      }
    }, onError: (_) {
      close();
    }, onDone: close);
    onScriptParsed.listen((event) {
      // Remove stale scripts from cache.
      if (event.script.url.isNotEmpty &&
          _scriptIds.containsKey(event.script.url)) {
        _scripts.remove(_scriptIds[event.script.url]);
      }
      _scripts[event.script.scriptId] = event.script;
      _scriptIds[event.script.url] = event.script.scriptId;
    });
    // Listens for a page reload.
    onGlobalObjectCleared.listen((_) {
      _scripts.clear();
    });
  }

  void sendEvent(String method, String params) {
    sseConnection.sink
        .add(jsonEncode(serializers.serialize(ExtensionEvent((b) => b
          ..method = method
          ..params = params))));
  }

  /// Sends a [command] with optional [params] to Dart Debug Extension
  /// over the SSE connection.
  @override
  Future<WipResponse> sendCommand(String command,
      {Map<String, dynamic>? params}) {
    final completer = Completer<WipResponse>();
    final id = newId();
    _completers[id] = completer;
    sseConnection.sink
        .add(jsonEncode(serializers.serialize(ExtensionRequest((b) => b
          ..id = id
          ..command = command
          ..commandParams = jsonEncode(params ?? {})))));
    return completer.future;
  }

  int newId() => _completerId++;

  @override
  void close() => _closed ??= () {
        _closeController.add(WipEvent({}));
        return Future.wait([
          sseConnection.sink.close(),
          _notificationController.close(),
          _devToolsRequestController.close(),
          _closeController.close(),
        ]);
      }();

  @override
  Future disable() => sendCommand('Debugger.disable');

  @override
  Future enable() => sendCommand('Debugger.enable');

  @override
  Future<String> getScriptSource(String scriptId) async =>
      (await sendCommand('Debugger.getScriptSource',
              params: {'scriptId': scriptId}))
          .result!['scriptSource'] as String;

  @override
  Future<WipResponse> pause() => sendCommand('Debugger.pause');

  @override
  Future<WipResponse> resume() => sendCommand('Debugger.resume');

  @override
  Future<WipResponse> setPauseOnExceptions(PauseState state) =>
      sendCommand('Debugger.setPauseOnExceptions',
          params: {'state': _pauseStateToString(state)});

  @override
  Future<WipResponse> removeBreakpoint(String breakpointId) {
    return sendCommand('Debugger.removeBreakpoint',
        params: {'breakpointId': breakpointId});
  }

  @override
  Future<WipResponse> stepInto({Map<String, dynamic>? params}) =>
      sendCommand('Debugger.stepInto', params: params);

  @override
  Future<WipResponse> stepOut() => sendCommand('Debugger.stepOut');

  @override
  Future<WipResponse> stepOver({Map<String, dynamic>? params}) =>
      sendCommand('Debugger.stepOver', params: params);

  @override
  Future<WipResponse> enablePage() => sendCommand('Page.enable');

  @override
  Future<WipResponse> pageReload() => sendCommand('Page.reload');

  @override
  Future<RemoteObject> evaluate(String expression,
      {bool? returnByValue, int? contextId}) async {
    final params = <String, dynamic>{
      'expression': expression,
    };
    if (returnByValue != null) {
      params['returnByValue'] = returnByValue;
    }
    if (returnByValue != null) {
      params['contextId'] = contextId;
    }
    final response = await sendCommand('Runtime.evaluate', params: params);
    final result = _validateResult(response.result);
    return RemoteObject(result['result'] as Map<String, dynamic>);
  }

  @override
  Future<RemoteObject> evaluateOnCallFrame(
      String callFrameId, String expression) async {
    final params = <String, dynamic>{
      'callFrameId': callFrameId,
      'expression': expression,
    };
    final response =
        await sendCommand('Debugger.evaluateOnCallFrame', params: params);
    final result = _validateResult(response.result);
    return RemoteObject(result['result'] as Map<String, dynamic>);
  }

  @override
  Future<List<WipBreakLocation>> getPossibleBreakpoints(
      WipLocation start) async {
    final params = <String, dynamic>{
      'start': start.toJsonMap(),
    };
    final response =
        await sendCommand('Debugger.getPossibleBreakpoints', params: params);
    final result = _validateResult(response.result);
    final locations = result['locations'] as List;
    return List.from(
        locations.map((map) => WipBreakLocation(map as Map<String, dynamic>)));
  }

  @override
  Stream<T> eventStream<T>(String method, WipEventTransformer<T> transformer) {
    return _eventStreams
        .putIfAbsent(
            method,
            () => onNotification
                .where((event) => event.method == method)
                .map(transformer))
        .cast();
  }

  @override
  Stream<GlobalObjectClearedEvent> get onGlobalObjectCleared => eventStream(
      'Debugger.globalObjectCleared',
      (WipEvent event) => GlobalObjectClearedEvent(event.json));

  @override
  Stream<DebuggerPausedEvent> get onPaused => eventStream(
      'Debugger.paused', (WipEvent event) => DebuggerPausedEvent(event.json));

  @override
  Stream<DebuggerResumedEvent> get onResumed => eventStream(
      'Debugger.resumed', (WipEvent event) => DebuggerResumedEvent(event.json));

  @override
  Stream<ScriptParsedEvent> get onScriptParsed => eventStream(
      'Debugger.scriptParsed',
      (WipEvent event) => ScriptParsedEvent(event.json));

  @override
  Stream<TargetCrashedEvent> get onTargetCrashed => eventStream(
      'Inspector.targetCrashed',
      (WipEvent event) => TargetCrashedEvent(event.json));

  @override
  Map<String, WipScript> get scripts => UnmodifiableMapView(_scripts);

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

  Map<String, dynamic> _validateResult(Map<String, dynamic>? result) {
    if (result == null) {
      throw ChromeDebugException({'result': null});
    }
    if (result.containsKey('exceptionDetails')) {
      throw ChromeDebugException(
          result['exceptionDetails'] as Map<String, dynamic>);
    }
    return result;
  }
}
