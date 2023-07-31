// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:stack_trace/stack_trace.dart';
import 'package:stream_channel/stream_channel.dart';

import '../error_code.dart' as error_code;
import 'exception.dart';
import 'parameters.dart';
import 'utils.dart';

/// A callback for unhandled exceptions.
typedef ErrorCallback = void Function(dynamic error, dynamic stackTrace);

/// A JSON-RPC 2.0 server.
///
/// A server exposes methods that are called by requests, to which it provides
/// responses. Methods can be registered using [registerMethod] and
/// [registerFallback]. Requests can be handled using [handleRequest] and
/// [parseRequest].
///
/// Note that since requests can arrive asynchronously and methods can run
/// asynchronously, it's possible for multiple methods to be invoked at the same
/// time, or even for a single method to be invoked multiple times at once.
class Server {
  final StreamChannel<dynamic> _channel;

  /// The methods registered for this server.
  final _methods = <String, Function>{};

  /// The fallback methods for this server.
  ///
  /// These are tried in order until one of them doesn't throw a
  /// [RpcException.methodNotFound] exception.
  final _fallbacks = Queue<Function>();

  final _done = Completer<void>();

  /// Returns a [Future] that completes when the underlying connection is
  /// closed.
  ///
  /// This is the same future that's returned by [listen] and [close]. It may
  /// complete before [close] is called if the remote endpoint closes the
  /// connection.
  Future get done => _done.future;

  /// Whether the underlying connection is closed.
  ///
  /// Note that this will be `true` before [close] is called if the remote
  /// endpoint closes the connection.
  bool get isClosed => _done.isCompleted;

  /// A callback that is fired on unhandled exceptions.
  ///
  /// In the case where a user provided callback results in an exception that
  /// cannot be properly routed back to the client, this handler will be
  /// invoked. If it is not set, the exception will be swallowed.
  final ErrorCallback? onUnhandledError;

  /// Whether to strictly enforce the JSON-RPC 2.0 specification for received
  /// messages.
  ///
  /// If `false`, this [Server] will accept some requests which are not
  /// conformant with the JSON-RPC 2.0 specification. In particular, requests
  /// missing the `jsonrpc` parameter will be accepted.
  final bool strictProtocolChecks;

  /// Creates a [Server] that communicates over [channel].
  ///
  /// Note that the server won't begin listening to [requests] until
  /// [Server.listen] is called.
  ///
  /// Unhandled exceptions in callbacks will be forwarded to [onUnhandledError].
  /// If this is not provided, unhandled exceptions will be swallowed.
  ///
  /// If [strictProtocolChecks] is false, this [Server] will accept some
  /// requests which are not conformant with the JSON-RPC 2.0 specification. In
  /// particular, requests missing the `jsonrpc` parameter will be accepted.
  Server(StreamChannel<String> channel,
      {ErrorCallback? onUnhandledError, bool strictProtocolChecks = true})
      : this.withoutJson(
            jsonDocument.bind(channel).transform(respondToFormatExceptions),
            onUnhandledError: onUnhandledError,
            strictProtocolChecks: strictProtocolChecks);

  /// Creates a [Server] that communicates using decoded messages over
  /// [channel].
  ///
  /// Unlike [new Server], this doesn't read or write JSON strings. Instead, it
  /// reads and writes decoded maps or lists.
  ///
  /// Note that the server won't begin listening to [requests] until
  /// [Server.listen] is called.
  ///
  /// Unhandled exceptions in callbacks will be forwarded to [onUnhandledError].
  /// If this is not provided, unhandled exceptions will be swallowed.
  ///
  /// If [strictProtocolChecks] is false, this [Server] will accept some
  /// requests which are not conformant with the JSON-RPC 2.0 specification. In
  /// particular, requests missing the `jsonrpc` parameter will be accepted.
  Server.withoutJson(this._channel,
      {this.onUnhandledError, this.strictProtocolChecks = true});

  /// Starts listening to the underlying stream.
  ///
  /// Returns a [Future] that will complete when the connection is closed or
  /// when it has an error. This is the same as [done].
  ///
  /// [listen] may only be called once.
  Future listen() {
    _channel.stream.listen(_handleRequest, onError: (error, stackTrace) {
      _done.completeError(error, stackTrace);
      _channel.sink.close();
    }, onDone: () {
      if (!_done.isCompleted) _done.complete();
    });
    return done;
  }

  /// Closes the underlying connection.
  ///
  /// Returns a [Future] that completes when all resources have been released.
  /// This is the same as [done].
  Future close() {
    _channel.sink.close();
    if (!_done.isCompleted) _done.complete();
    return done;
  }

  /// Registers a method named [name] on this server.
  ///
  /// [callback] can take either zero or one arguments. If it takes zero, any
  /// requests for that method that include parameters will be rejected. If it
  /// takes one, it will be passed a [Parameters] object.
  ///
  /// [callback] can return either a JSON-serializable object or a Future that
  /// completes to a JSON-serializable object. Any errors in [callback] will be
  /// reported to the client as JSON-RPC 2.0 errors.
  void registerMethod(String name, Function callback) {
    if (_methods.containsKey(name)) {
      throw ArgumentError('There\'s already a method named "$name".');
    }

    _methods[name] = callback;
  }

  /// Registers a fallback method on this server.
  ///
  /// A server may have any number of fallback methods. When a request comes in
  /// that doesn't match any named methods, each fallback is tried in order. A
  /// fallback can pass on handling a request by throwing a
  /// [RpcException.methodNotFound] exception.
  ///
  /// [callback] can return either a JSON-serializable object or a Future that
  /// completes to a JSON-serializable object. Any errors in [callback] will be
  /// reported to the client as JSON-RPC 2.0 errors. [callback] may send custom
  /// errors by throwing an [RpcException].
  void registerFallback(Function(Parameters parameters) callback) {
    _fallbacks.add(callback);
  }

  /// Handle a request.
  ///
  /// [request] is expected to be a JSON-serializable object representing a
  /// request sent by a client. This calls the appropriate method or methods for
  /// handling that request and returns a JSON-serializable response, or `null`
  /// if no response should be sent. [callback] may send custom
  /// errors by throwing an [RpcException].
  Future _handleRequest(request) async {
    dynamic response;
    if (request is List) {
      if (request.isEmpty) {
        response = RpcException(error_code.INVALID_REQUEST,
                'A batch must contain at least one request.')
            .serialize(request);
      } else {
        var results = await Future.wait(request.map(_handleSingleRequest));
        var nonNull = results.where((result) => result != null);
        if (nonNull.isEmpty) return;
        response = nonNull.toList();
      }
    } else {
      response = await _handleSingleRequest(request);
      if (response == null) return;
    }

    if (!isClosed) _channel.sink.add(response);
  }

  /// Handles an individual parsed request.
  Future _handleSingleRequest(request) async {
    try {
      _validateRequest(request);

      var name = request['method'];
      var method = _methods[name];
      method ??= _tryFallbacks;

      Object? result;
      if (method is ZeroArgumentFunction) {
        if (request.containsKey('params')) {
          throw RpcException.invalidParams('No parameters are allowed for '
              'method "$name".');
        }
        result = await method();
      } else {
        result = await method(Parameters(name, request['params']));
      }

      // A request without an id is a notification, which should not be sent a
      // response, even if one is generated on the server.
      if (!request.containsKey('id')) return null;

      return {'jsonrpc': '2.0', 'result': result, 'id': request['id']};
    } catch (error, stackTrace) {
      if (error is RpcException) {
        if (error.code == error_code.INVALID_REQUEST ||
            request.containsKey('id')) {
          return error.serialize(request);
        } else {
          onUnhandledError?.call(error, stackTrace);
          return null;
        }
      } else if (!request.containsKey('id')) {
        onUnhandledError?.call(error, stackTrace);
        return null;
      }
      final chain = Chain.forTrace(stackTrace);
      return RpcException(error_code.SERVER_ERROR, getErrorMessage(error),
          data: {
            'full': '$error',
            'stack': '$chain',
          }).serialize(request);
    }
  }

  /// Validates that [request] matches the JSON-RPC spec.
  void _validateRequest(request) {
    if (request is! Map) {
      throw RpcException(
          error_code.INVALID_REQUEST,
          'Request must be '
          'an Array or an Object.');
    }

    if (strictProtocolChecks && !request.containsKey('jsonrpc')) {
      throw RpcException(
          error_code.INVALID_REQUEST,
          'Request must '
          'contain a "jsonrpc" key.');
    }

    if ((strictProtocolChecks || request.containsKey('jsonrpc')) &&
        request['jsonrpc'] != '2.0') {
      throw RpcException(
          error_code.INVALID_REQUEST,
          'Invalid JSON-RPC '
          'version ${jsonEncode(request['jsonrpc'])}, expected "2.0".');
    }

    if (!request.containsKey('method')) {
      throw RpcException(
          error_code.INVALID_REQUEST,
          'Request must '
          'contain a "method" key.');
    }

    var method = request['method'];
    if (request['method'] is! String) {
      throw RpcException(
          error_code.INVALID_REQUEST,
          'Request method must '
          'be a string, but was ${jsonEncode(method)}.');
    }

    if (request.containsKey('params')) {
      var params = request['params'];
      if (params is! List && params is! Map) {
        throw RpcException(
            error_code.INVALID_REQUEST,
            'Request params must '
            'be an Array or an Object, but was ${jsonEncode(params)}.');
      }
    }

    var id = request['id'];
    if (id != null && id is! String && id is! num) {
      throw RpcException(
          error_code.INVALID_REQUEST,
          'Request id must be a '
          'string, number, or null, but was ${jsonEncode(id)}.');
    }
  }

  /// Try all the fallback methods in order.
  Future _tryFallbacks(Parameters params) {
    var iterator = _fallbacks.toList().iterator;

    Future tryNext() async {
      if (!iterator.moveNext()) {
        throw RpcException.methodNotFound(params.method);
      }

      try {
        return await iterator.current(params);
      } on RpcException catch (error) {
        if (error.code != error_code.METHOD_NOT_FOUND) rethrow;
        return tryNext();
      }
    }

    return tryNext();
  }
}
