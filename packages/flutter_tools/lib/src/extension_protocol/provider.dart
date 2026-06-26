// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:isolate';

import 'messages.dart';
import 'service.dart';

/// Provides the connection and communication channel for a Flutter Tool Extension.
///
/// This class is used by the extension to communicate with the host Flutter tool.
/// It implements [RpcRegistrar] to allow services to register their RPC handlers.
class ToolExtensionProvider implements RpcRegistrar {
  /// Creates a [ToolExtensionProvider] that communicates with the tool via [_toolSendPort].
  ToolExtensionProvider(this._toolSendPort);

  final SendPort _toolSendPort;
  final ReceivePort _receivePort = ReceivePort();
  final Map<String, FutureOr<Response> Function(Map<String, Object?> params)> _handlers =
      <String, FutureOr<Response> Function(Map<String, Object?> params)>{};
  StreamSubscription<Object?>? _subscription;

  final StreamController<Notification> _notificationsController =
      StreamController<Notification>.broadcast();

  /// A stream of notifications sent from the host Flutter tool to this extension.
  Stream<Notification> get notifications => _notificationsController.stream;

  /// Registers a handler for the given RPC [method].
  ///
  /// Throws a [StateError] if a handler for [method] is already registered.
  @override
  void registerRpc(
    String method,
    FutureOr<Response> Function(Map<String, Object?> params) handler,
  ) {
    if (_handlers.containsKey(method)) {
      throw StateError('A handler for "$method" is already registered.');
    }
    _handlers[method] = handler;
  }

  /// Initializes the provider, establishing the connection with the host tool.
  ///
  /// This must be called after registering all services and RPC handlers.
  void initialize() {
    _toolSendPort.send(_receivePort.sendPort);
    _subscription = _receivePort.listen(_handleIncomingMessage);
  }

  /// Closes the communication channels and releases resources.
  void close() {
    _subscription?.cancel();
    _receivePort.close();
    _notificationsController.close();
  }

  /// Sends a [notification] to the host Flutter tool.
  void sendNotification(Notification notification) {
    _toolSendPort.send(notification.toMap());
  }

  Future<void> _handleIncomingMessage(Object? message) async {
    if (message is! Map<String, Object?>) {
      return;
    }

    try {
      final Message parsedMessage = Message.fromMap(message);
      if (parsedMessage is Request) {
        final FutureOr<Response> Function(Map<String, Object?> params)? handler =
            _handlers[parsedMessage.method];
        if (handler == null) {
          final errorResponse = Response.error(
            id: parsedMessage.id!,
            error: RpcError(
              code: -32601, // Method not found
              message: 'Method not found: ${parsedMessage.method}',
            ),
          );
          _toolSendPort.send(errorResponse.toMap());
          return;
        }

        try {
          final Map<String, Object?> params = parsedMessage.params ?? <String, Object?>{};
          final Response response = await handler(params);
          // Ensure the response ID matches the request ID.
          final matchedResponse = response.error != null
              ? Response.error(error: response.error, id: parsedMessage.id!)
              : Response.result(id: parsedMessage.id!, result: response.result);
          _toolSendPort.send(matchedResponse.toMap());
        } on Object catch (e, st) {
          final errorResponse = Response.error(
            id: parsedMessage.id!,
            error: RpcError(
              code: -32603, // Internal error
              message: 'Internal error: $e',
              data: st.toString(),
            ),
          );
          _toolSendPort.send(errorResponse.toMap());
        }
      } else if (parsedMessage is Notification) {
        _notificationsController.add(parsedMessage);
      }
    } on Object catch (e) {
      final Object? id = message['id'];
      if (id != null) {
        final errorResponse = Response.error(
          id: id,
          error: RpcError(
            code: -32700, // Parse error
            message: 'Parse error: $e',
          ),
        );
        _toolSendPort.send(errorResponse.toMap());
      }
    }
  }
}
