// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:_fe_analyzer_shared/src/macros/executor/message_grouper.dart';
import 'package:_fe_analyzer_shared/src/macros/executor/serialization.dart';

/// An instance of this class is thrown when remotely executed code throws
/// an exception.
class RemoteException {
  final String message;
  final String stackTrace;

  RemoteException({
    required this.message,
    required this.stackTrace,
  });
}

/// Channel for exchanging requests and responses over [Socket].
class RequestChannel {
  final Socket _socket;
  final Map<int, Completer<Object?>> _requests = {};
  final Map<String, Future<Object?> Function(Object?)> _requestHandlers = {};

  int _nextRequestId = 0;

  RequestChannel(this._socket) {
    final MessageGrouper messageGrouper = new MessageGrouper(_socket);
    messageGrouper.messageStream.map((bytes) {
      final ByteDataDeserializer deserializer = new ByteDataDeserializer(
        new ByteData.sublistView(bytes),
      );
      return deserializer.expectAny();
    }).listen(_processMessage, cancelOnError: true, onDone: () {
      _socket.destroy();
    });
  }

  /// Registers the [handler] for the [method].
  void add(String method, Future<Object?> Function(Object?) handler) {
    _requestHandlers[method] = handler;
  }

  /// Sends a request with the given [method] and [argument], when it is
  /// handled on the other side by the handler registered with [add], the
  /// result is returned from the [Future].
  ///
  /// If an exception happens on the other side, the returned future completes
  /// with a [RemoteException].
  ///
  /// The other side may do callbacks.
  Future<T> sendRequest<T>(String method, Object? argument) async {
    final int requestId = _nextRequestId++;
    final Completer<Object?> completer = new Completer<Object?>();
    _requests[requestId] = completer;
    _writeObject({
      'requestId': requestId,
      'method': method,
      'argument': argument,
    });

    return await completer.future as T;
  }

  void _processMessage(Object? message) {
    if (message is Map<Object?, Object?>) {
      final Object? requestId = message['requestId'];
      if (requestId != null) {
        final Object? method = message['method'];
        final Object? argument = message['argument'];
        if (method != null) {
          final Future<Object?> Function(Object?)? handler =
              _requestHandlers[method];
          if (handler != null) {
            handler(argument).then((result) {
              _writeObject({
                'responseId': requestId,
                'result': result,
              });
            }, onError: (e, stackTrace) {
              _writeObject({
                'responseId': requestId,
                'exception': {
                  'message': '$e',
                  'stackTrace': '$stackTrace',
                },
              });
            });
          } else {
            _writeObject({
              'responseId': requestId,
              'exception': {
                'message': 'No handler for: $method',
                'stackTrace': '${StackTrace.current}',
              },
            });
          }
          return;
        }
      }

      final Object? responseId = message['responseId'];
      if (responseId != null) {
        final Completer<Object?>? completer = _requests.remove(responseId);
        if (completer == null) {
          return;
        }

        final Object? exception = message['exception'];
        if (exception is Map) {
          completer.completeError(
            new RemoteException(
              message: exception['message'] as String,
              stackTrace: exception['stackTrace'] as String,
            ),
          );
          return;
        }

        final Object? result = message['result'];
        completer.complete(result);
        return;
      }
    }

    throw new StateError('Unexpected message: $message');
  }

  /// Sends [bytes] for [MessageGrouper].
  void _writeBytes(List<int> bytes) {
    final ByteData lengthByteData = new ByteData(4)..setUint32(0, bytes.length);
    _socket.add(lengthByteData.buffer.asUint8List());
    _socket.add(bytes);
    _socket.flush();
  }

  /// Serializes and sends the [object].
  void _writeObject(Object object) {
    final ByteDataSerializer serializer = new ByteDataSerializer();
    serializer.addAny(object);
    _writeBytes(serializer.result);
  }
}
