// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:isolate';

import 'messages.dart';

/// Manages a running Flutter Tool Extension.
///
/// This class is used by the host Flutter tool to start or connect to an extension
/// isolate, send requests, and receive notifications.
class ToolExtensionManager {
  Isolate? _isolate;
  SendPort? _extensionSendPort;
  final ReceivePort _receivePort = ReceivePort();
  final _pendingRequests = <Object, Completer<Response>>{};
  final _notificationsController = StreamController<Notification>.broadcast();
  StreamSubscription<Object?>? _subscription;
  int _requestIdCounter = 0;
  final _handshakeCompleter = Completer<SendPort>();

  /// A stream of notifications sent from the extension to the host tool.
  Stream<Notification> get notifications => _notificationsController.stream;

  /// The [SendPort] that the extension should use to communicate with this manager.
  SendPort get sendPort => _receivePort.sendPort;

  /// A future that completes with the extension's [SendPort] when the handshake is complete.
  Future<SendPort> get handshake => _handshakeCompleter.future;

  /// Spawns the extension isolate using [entryPoint] and performs the handshake.
  ///
  /// The [entryPoint] function is the entry point of the extension isolate. It
  /// will receive this manager's [sendPort] as its argument.
  ///
  /// Throws a [TimeoutException] if the handshake does not complete within [timeout].
  Future<void> start(
    void Function(SendPort) entryPoint, {
    Duration timeout = const Duration(seconds: 2),
  }) async {
    _startListening();
    try {
      _isolate = await Isolate.spawn(entryPoint, _receivePort.sendPort);
      _extensionSendPort = await _handshakeCompleter.future.timeout(timeout);
    } on TimeoutException {
      await dispose();
      throw TimeoutException('Handshake with extension isolate timed out.');
    } on Object {
      await dispose();
      rethrow;
    }
  }

  /// Connects to an externally spawned isolate by waiting for the handshake.
  ///
  /// The caller must have passed this manager's [sendPort] to the extension isolate
  /// during its creation.
  ///
  /// Throws a [TimeoutException] if the handshake does not complete within [timeout].
  Future<void> connect({Duration timeout = const Duration(seconds: 2)}) async {
    _startListening();
    try {
      _extensionSendPort = await _handshakeCompleter.future.timeout(timeout);
    } on TimeoutException {
      await dispose();
      throw TimeoutException('Handshake with extension isolate timed out.');
    } on Object {
      await dispose();
      rethrow;
    }
  }

  void _startListening() {
    if (_subscription != null) {
      return;
    }
    _subscription = _receivePort.listen((Object? message) {
      if (!_handshakeCompleter.isCompleted && message is SendPort) {
        _handshakeCompleter.complete(message);
      } else {
        _handleIncomingMessage(message);
      }
    });
  }

  /// Sends a request to the extension and waits for a response.
  ///
  /// Throws an [RpcException] if the extension returns an error response.
  /// Throws a [StateError] if the manager is not connected to an extension.
  Future<Object?> callMethod(String method, {Map<String, Object?>? params}) async {
    final SendPort? port = _extensionSendPort;
    if (port == null) {
      throw StateError('Manager is not connected to an extension.');
    }

    final int id = _requestIdCounter++;
    final request = Request(id: id, method: method, params: params);
    final completer = Completer<Response>();
    _pendingRequests[id] = completer;

    port.send(request.toMap());

    try {
      final Response response = await completer.future;
      if (response.error != null) {
        throw RpcException(response.error!);
      }
      return response.result;
    } on Object {
      _pendingRequests.remove(id);
      rethrow;
    }
  }

  /// Sends a notification with the given [method] and [params] to the extension.
  ///
  /// Throws a [StateError] if the manager is not connected to an extension.
  void sendNotification(String method, {Map<String, Object?>? params}) {
    final SendPort? port = _extensionSendPort;
    if (port == null) {
      throw StateError('Manager is not connected to an extension.');
    }
    final notification = Notification(method: method, params: params);
    port.send(notification.toMap());
  }

  /// Disposes of the manager, killing the extension isolate and closing ports.
  Future<void> dispose() async {
    await _subscription?.cancel();
    _receivePort.close();
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
    _extensionSendPort = null;
    await _notificationsController.close();
    for (final Completer<Response> completer in _pendingRequests.values) {
      completer.completeError(StateError('Manager was disposed.'));
    }
    _pendingRequests.clear();
  }

  void _handleIncomingMessage(Object? message) {
    if (message is! Map<String, Object?>) {
      return;
    }

    try {
      final Message parsedMessage = Message.fromMap(message);
      if (parsedMessage is Response) {
        final Object? id = parsedMessage.id;
        if (id != null) {
          final Completer<Response>? completer = _pendingRequests.remove(id);
          if (completer != null) {
            completer.complete(parsedMessage);
          }
        }
      } else if (parsedMessage is Notification) {
        _notificationsController.add(parsedMessage);
      }
    } on Object {
      // Ignore malformed messages
    }
  }
}

/// Exception thrown when an RPC call to an extension fails.
class RpcException implements Exception {
  /// Creates an [RpcException] wrapping the given [error].
  RpcException(this.error);

  /// The underlying RPC error.
  final RpcError error;

  @override
  String toString() => 'RpcException: [${error.code}] ${error.message} (data: ${error.data})';
}
