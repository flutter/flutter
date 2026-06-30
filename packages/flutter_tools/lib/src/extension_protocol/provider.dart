// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:isolate';

import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;
import 'package:stream_channel/isolate_channel.dart';
import 'package:stream_channel/stream_channel.dart';

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
  final _registeredMethods = <String, Function>{};
  final _notificationsController = StreamController<Notification>.broadcast();

  StreamSubscription<Object?>? _subscription;
  json_rpc.Peer? _peer;

  /// A stream of notifications sent from the host Flutter tool to this extension.
  Stream<Notification> get notifications => _notificationsController.stream;

  /// Registers a handler for the given RPC [method].
  ///
  /// The [handler] must be a function taking either zero arguments or one
  /// argument of type `Parameters` from `package:json_rpc_2`.
  ///
  /// Throws a [StateError] if a handler for [method] is already registered.
  @override
  void registerRpc(String method, Function handler) {
    if (_registeredMethods.containsKey(method)) {
      throw StateError('A handler for "$method" is already registered.');
    }
    _registeredMethods[method] = handler;
    _peer?.registerMethod(method, handler);
  }

  /// Initializes the provider, establishing the connection with the host tool.
  ///
  /// This must be called after registering all services and RPC handlers.
  void initialize() {
    if (_peer != null) {
      throw StateError('ToolExtensionProvider is already initialized.');
    }
    // Handshake: send our ReceivePort's SendPort to the tool.
    _toolSendPort.send(_receivePort.sendPort);

    // Set up the JSON-RPC peer over the IsolateChannel.
    final channel = IsolateChannel<Object?>.connectReceive(_receivePort);

    final incomingController = StreamController<Object?>(sync: true);
    _subscription = channel.stream.listen(
      (Object? message) {
        _interceptNotifications(message);
        incomingController.add(message);
      },
      onError: incomingController.addError,
      onDone: incomingController.close,
    );

    final peerChannel = StreamChannel<Object?>(incomingController.stream, channel.sink);
    final peer = json_rpc.Peer.withoutJson(peerChannel);
    _peer = peer;

    // Register all cached methods.
    _registeredMethods.forEach(peer.registerMethod);

    // Start listening.
    unawaited(peer.listen());
  }

  void _interceptNotifications(Object? message) {
    if (message is List) {
      message.forEach(_interceptNotifications);
      return;
    }
    if (message is Map && !message.containsKey('id') && message.containsKey('method')) {
      Map<String, Object?>? paramsMap;
      try {
        paramsMap = (message['params'] as Map?)?.cast<String, Object?>();
      } on Object catch (_) {
        // Not a map (could be a List or empty), ignore or handle if needed.
      }
      _notificationsController.add(
        Notification(method: message['method'] as String, params: paramsMap),
      );
    }
  }

  /// Sends a notification to the host Flutter tool.
  void sendNotification(String method, [Object? parameters]) {
    final json_rpc.Peer? peer = _peer;
    if (peer == null) {
      throw StateError('Provider is not initialized.');
    }
    peer.sendNotification(method, parameters);
  }

  /// Closes the communication channels and releases resources.
  Future<void> close() async {
    _receivePort.close();
    await _subscription?.cancel();
    _subscription = null;
    await _peer?.close();
    _peer = null;
    await _notificationsController.close();
  }
}
