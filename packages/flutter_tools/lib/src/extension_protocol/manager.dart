// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:isolate';

import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;
import 'package:stream_channel/isolate_channel.dart';
import 'package:stream_channel/stream_channel.dart';

import 'service.dart';

/// Manages a running Flutter Tool Extension.
///
/// This class is used by the host Flutter tool to start or connect to an extension
/// isolate, send requests, and receive notifications.
class ToolExtensionManager {
  Isolate? _isolate;
  final ReceivePort _receivePort = ReceivePort();
  final _notificationsController = StreamController<Notification>.broadcast();
  StreamSubscription<Object?>? _subscription;
  StreamSubscription<Object?>? _peerSubscription;
  final _handshakeCompleter = Completer<SendPort>();

  json_rpc.Peer? _peer;

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
      final SendPort extensionSendPort = await _handshakeCompleter.future.timeout(timeout);
      _initializePeer(extensionSendPort);
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
      final SendPort extensionSendPort = await _handshakeCompleter.future.timeout(timeout);
      _initializePeer(extensionSendPort);
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
      }
    });
  }

  void _initializePeer(SendPort extensionSendPort) {
    final channel = IsolateChannel<Object?>.connectSend(extensionSendPort);

    final incomingController = StreamController<Object?>(sync: true);
    _peerSubscription = channel.stream.listen(
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

  /// Sends a request to the extension and waits for a response.
  ///
  /// Throws an [RpcException] if the extension returns an error response.
  /// Throws a [StateError] if the manager is not connected to an extension.
  Future<Object?> callMethod(String method, {Map<String, Object?>? params}) async {
    final json_rpc.Peer? peer = _peer;
    if (peer == null) {
      throw StateError('Manager is not connected to an extension.');
    }

    try {
      return await peer.sendRequest(method, params);
    } on json_rpc.RpcException catch (e) {
      throw RpcException(e.code, e.message, data: e.data);
    }
  }

  /// Sends a notification with the given [method] and [params] to the extension.
  ///
  /// Throws a [StateError] if the manager is not connected to an extension.
  void sendNotification(String method, {Map<String, Object?>? params}) {
    final json_rpc.Peer? peer = _peer;
    if (peer == null) {
      throw StateError('Manager is not connected to an extension.');
    }
    peer.sendNotification(method, params);
  }

  /// Disposes of the manager, killing the extension isolate and closing ports.
  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
    await _peerSubscription?.cancel();
    _peerSubscription = null;
    _receivePort.close();
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
    await _peer?.close();
    _peer = null;
    await _notificationsController.close();
  }
}

/// Exception thrown when an RPC call to an extension fails.
class RpcException implements Exception {
  /// Creates an [RpcException] with the given [code], [message], and optional [data].
  RpcException(this.code, this.message, {this.data});

  /// The error code.
  final int code;

  /// A message describing the error.
  final String message;

  /// Additional data about the error, if any.
  final Object? data;

  @override
  String toString() => 'RpcException: [$code] $message (data: $data)';
}
