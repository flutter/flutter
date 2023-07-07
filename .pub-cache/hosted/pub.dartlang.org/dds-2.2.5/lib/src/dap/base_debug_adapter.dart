// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';

import 'exceptions.dart';
import 'protocol_common.dart';
import 'protocol_generated.dart';
import 'protocol_stream.dart';

typedef _FromJsonHandler<T> = T Function(Map<String, Object?>);
typedef _NullableFromJsonHandler<T> = T? Function(Map<String, Object?>?);
typedef _RequestHandler<TArg, TResp> = Future<void> Function(
    Request, TArg, void Function(TResp));
typedef _VoidArgRequestHandler<TArg> = Future<void> Function(
    Request, TArg, void Function(void));
typedef _VoidNoArgRequestHandler<TArg> = Future<void> Function(
    Request, TArg, void Function());

/// A base class for debug adapters.
///
/// Communicates over a [ByteStreamServerChannel] and turns messages into
/// appropriate method calls/events.
///
/// This class does not implement any DA functionality, only message handling.
abstract class BaseDebugAdapter<TLaunchArgs extends LaunchRequestArguments,
    TAttachArgs extends AttachRequestArguments> {
  int _sequence = 1;
  final ByteStreamServerChannel _channel;

  /// Completers for requests that are sent from the server back to the editor
  /// such as `runInTerminal`.
  final _serverToClientRequestCompleters = <int, Completer<Object?>>{};

  BaseDebugAdapter(this._channel, {Function? onError}) {
    _channel.listen(_handleIncomingMessage, onError: onError);
  }

  /// Parses arguments for [attachRequest] into a type of [TAttachArgs].
  ///
  /// This method must be implemented by the implementing class using a class
  /// that corresponds to the arguments it expects (these may differ between
  /// Dart CLI, Dart tests, Flutter, Flutter tests).
  TAttachArgs Function(Map<String, Object?>) get parseAttachArgs;

  /// Parses arguments for [launchRequest] into a type of [TLaunchArgs].
  ///
  /// This method must be implemented by the implementing class using a class
  /// that corresponds to the arguments it expects (these may differ between
  /// Dart CLI, Dart tests, Flutter, Flutter tests).
  TLaunchArgs Function(Map<String, Object?>) get parseLaunchArgs;

  Future<void> attachRequest(
    Request request,
    TAttachArgs args,
    void Function() sendResponse,
  );

  Future<void> configurationDoneRequest(
    Request request,
    ConfigurationDoneArguments? args,
    void Function() sendResponse,
  );

  Future<void> continueRequest(
    Request request,
    ContinueArguments args,
    void Function(ContinueResponseBody) sendResponse,
  );

  @mustCallSuper
  Future<void> customRequest(
    Request request,
    RawRequestArguments? args,
    void Function(Object?) sendResponse,
  ) async {
    throw DebugAdapterException('Unknown command ${request.command}');
  }

  Future<void> disconnectRequest(
    Request request,
    DisconnectArguments? args,
    void Function() sendResponse,
  );

  Future<void> evaluateRequest(
    Request request,
    EvaluateArguments args,
    void Function(EvaluateResponseBody) sendResponse,
  );

  /// Calls [handler] for an incoming request, using [fromJson] to parse its
  /// arguments from the request.
  ///
  /// [handler] will be provided a function [sendResponse] that it can use to
  /// sends its response without needing to build a [Response] from fields on
  /// the request.
  ///
  /// [handler] must _always_ call [sendResponse], even if the response does not
  /// require a body.
  ///
  /// If [handler] throws, its exception will be sent as an error response.
  Future<void> handle<TArg, TResp>(
    Request request,
    _RequestHandler<TArg, TResp> handler,
    TArg Function(Map<String, Object?>) fromJson,
  ) async {
    final args = request.arguments != null
        ? fromJson(request.arguments as Map<String, Object?>)
        // arguments are only valid to be null then TArg is nullable.
        : null as TArg;

    // Because handlers may need to send responses before they have finished
    // executing (for example, initializeRequest needs to send its response
    // before sending InitializedEvent()), we pass in a function `sendResponse`
    // rather than using a return value.
    var sendResponseCalled = false;
    void sendResponse(TResp responseBody) {
      assert(!sendResponseCalled,
          'sendResponse was called multiple times by ${request.command}');
      sendResponseCalled = true;
      final response = Response(
        success: true,
        requestSeq: request.seq,
        seq: _sequence++,
        command: request.command,
        body: responseBody,
      );
      _channel.sendResponse(response);
    }

    try {
      await handler(request, args, sendResponse);
      assert(sendResponseCalled,
          'sendResponse was not called in ${request.command}');
    } catch (e, s) {
      final response = Response(
        success: false,
        requestSeq: request.seq,
        seq: _sequence++,
        command: request.command,
        message: e is DebugAdapterException ? e.message : '$e',
        body: '$s',
      );
      _channel.sendResponse(response);
    }
  }

  Future<void> initializeRequest(
    Request request,
    InitializeRequestArguments args,
    void Function(Capabilities) sendResponse,
  );

  Future<void> launchRequest(
    Request request,
    TLaunchArgs args,
    void Function() sendResponse,
  );

  Future<void> nextRequest(
    Request request,
    NextArguments args,
    void Function() sendResponse,
  );

  Future<void> restartRequest(
    Request request,
    RestartArguments? args,
    void Function() sendResponse,
  );

  Future<void> scopesRequest(
    Request request,
    ScopesArguments args,
    void Function(ScopesResponseBody) sendResponse,
  );

  /// Sends an event, lookup up the event type based on the runtimeType of
  /// [body].
  void sendEvent(EventBody body, {String? eventType}) {
    final event = Event(
      seq: _sequence++,
      event: eventType ?? eventTypes[body.runtimeType]!,
      body: body,
    );
    _channel.sendEvent(event);
  }

  /// Sends a request to the client, looking up the request type based on the
  /// runtimeType of [arguments].
  Future<Object?> sendRequest(RequestArguments arguments) {
    final request = Request(
      seq: _sequence++,
      command: commandTypes[arguments.runtimeType]!,
      arguments: arguments,
    );

    // Store a completer to be used when a response comes back.
    final completer = Completer<Object?>();
    _serverToClientRequestCompleters[request.seq] = completer;
    _channel.sendRequest(request);

    return completer.future;
  }

  Future<void> setBreakpointsRequest(
      Request request,
      SetBreakpointsArguments args,
      void Function(SetBreakpointsResponseBody) sendResponse);

  Future<void> setExceptionBreakpointsRequest(
    Request request,
    SetExceptionBreakpointsArguments args,
    void Function(SetExceptionBreakpointsResponseBody) sendResponse,
  );

  Future<void> sourceRequest(
    Request request,
    SourceArguments args,
    void Function(SourceResponseBody) sendResponse,
  );

  Future<void> stackTraceRequest(
    Request request,
    StackTraceArguments args,
    void Function(StackTraceResponseBody) sendResponse,
  );

  Future<void> stepInRequest(
    Request request,
    StepInArguments args,
    void Function() sendResponse,
  );

  Future<void> stepOutRequest(
    Request request,
    StepOutArguments args,
    void Function() sendResponse,
  );

  Future<void> terminateRequest(
    Request request,
    TerminateArguments? args,
    void Function() sendResponse,
  );

  Future<void> threadsRequest(
    Request request,
    void args,
    void Function(ThreadsResponseBody) sendResponse,
  );

  Future<void> variablesRequest(
    Request request,
    VariablesArguments args,
    void Function(VariablesResponseBody) sendResponse,
  );

  /// Wraps a fromJson handler for requests that allow null arguments.
  _NullableFromJsonHandler<T> _allowNullArg<T extends RequestArguments>(
    _FromJsonHandler<T> fromJson,
  ) {
    return (data) => data == null ? null : fromJson(data);
  }

  /// Handles incoming messages from the client editor.
  void _handleIncomingMessage(ProtocolMessage message) {
    if (message is Request) {
      _handleIncomingRequest(message);
    } else if (message is Response) {
      _handleIncomingResponse(message);
    } else {
      throw DebugAdapterException('Unknown Protocol message ${message.type}');
    }
  }

  /// Handles an incoming request, calling the appropriate method to handle it.
  void _handleIncomingRequest(Request request) {
    if (request.command == 'initialize') {
      handle(request, initializeRequest, InitializeRequestArguments.fromJson);
    } else if (request.command == 'launch') {
      handle(request, _withVoidResponse(launchRequest), parseLaunchArgs);
    } else if (request.command == 'attach') {
      handle(request, _withVoidResponse(attachRequest), parseAttachArgs);
    } else if (request.command == 'restart') {
      handle(
        request,
        _withVoidResponse(restartRequest),
        _allowNullArg(RestartArguments.fromJson),
      );
    } else if (request.command == 'terminate') {
      handle(
        request,
        _withVoidResponse(terminateRequest),
        _allowNullArg(TerminateArguments.fromJson),
      );
    } else if (request.command == 'disconnect') {
      handle(
        request,
        _withVoidResponse(disconnectRequest),
        _allowNullArg(DisconnectArguments.fromJson),
      );
    } else if (request.command == 'configurationDone') {
      handle(
        request,
        _withVoidResponse(configurationDoneRequest),
        _allowNullArg(ConfigurationDoneArguments.fromJson),
      );
    } else if (request.command == 'setBreakpoints') {
      handle(request, setBreakpointsRequest, SetBreakpointsArguments.fromJson);
    } else if (request.command == 'setExceptionBreakpoints') {
      handle(
        request,
        setExceptionBreakpointsRequest,
        SetExceptionBreakpointsArguments.fromJson,
      );
    } else if (request.command == 'continue') {
      handle(request, continueRequest, ContinueArguments.fromJson);
    } else if (request.command == 'next') {
      handle(request, _withVoidResponse(nextRequest), NextArguments.fromJson);
    } else if (request.command == 'stepIn') {
      handle(
        request,
        _withVoidResponse(stepInRequest),
        StepInArguments.fromJson,
      );
    } else if (request.command == 'stepOut') {
      handle(
        request,
        _withVoidResponse(stepOutRequest),
        StepOutArguments.fromJson,
      );
    } else if (request.command == 'threads') {
      handle(request, threadsRequest, _voidArgs);
    } else if (request.command == 'stackTrace') {
      handle(request, stackTraceRequest, StackTraceArguments.fromJson);
    } else if (request.command == 'source') {
      handle(request, sourceRequest, SourceArguments.fromJson);
    } else if (request.command == 'scopes') {
      handle(request, scopesRequest, ScopesArguments.fromJson);
    } else if (request.command == 'variables') {
      handle(request, variablesRequest, VariablesArguments.fromJson);
    } else if (request.command == 'evaluate') {
      handle(request, evaluateRequest, EvaluateArguments.fromJson);
    } else {
      handle(
        request,
        customRequest,
        _allowNullArg(RawRequestArguments.fromJson),
      );
    }
  }

  void _handleIncomingResponse(Response response) {
    final completer =
        _serverToClientRequestCompleters.remove(response.requestSeq);

    if (response.success) {
      completer?.complete(response.body);
    } else {
      completer?.completeError(
        response.message ?? 'Request ${response.requestSeq} failed',
      );
    }
  }

  /// Helpers for requests that have `void` arguments. The supplied args are
  /// ignored.
  void _voidArgs(Map<String, Object?>? args) {}

  /// Helper that converts a handler with no response value to one that has
  /// passes an unused arg so that `Function()` can be passed to a function
  /// accepting `Function<T>(T x)` where `T` happens to be `void`.
  ///
  /// This allows handlers to simply call sendResponse() where they have no
  /// return value but need to send a valid response.
  _VoidArgRequestHandler<TArg> _withVoidResponse<TArg>(
    _VoidNoArgRequestHandler<TArg> handler,
  ) {
    return (request, arg, sendResponse) => handler(
          request,
          arg,
          () => sendResponse(null),
        );
  }
}
