// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:isolate';

import 'package:json_rpc_2/json_rpc_2.dart' as rpc;
import 'package:stream_channel/isolate_channel.dart';
import 'package:stream_channel/stream_channel.dart';

import 'service.dart';

/// Manages multiple running Flutter Tool Extensions.
///
/// This class is used by the host Flutter tool to start and connect to multiple
/// extension isolates, keeping track of their active connections as [ToolExtension] instances.
class ToolExtensionManager {
  final List<ToolExtension> _extensions = [];
  final Map<void Function(SendPort), ToolExtension> _activeSpawns = {};
  final Map<void Function(SendPort), Future<ToolExtension>> _pendingSpawns = {};
  final _notificationsController = StreamController<Notification>.broadcast();
  bool _isDisposed = false;

  /// A stream of notifications sent from all active extensions to the host tool.
  Stream<Notification> get notifications => _notificationsController.stream;

  /// A list of all active tool extensions managed by this manager.
  List<ToolExtension> get extensions => List.unmodifiable(_extensions);

  /// Spawns the extension isolate using [entryPoint] and performs the handshake.
  ///
  /// The [entryPoint] function is the entry point of the extension isolate. It
  /// will receive a [SendPort] as its argument, which it must use to send back
  /// its own [SendPort] during the handshake.
  ///
  /// Returns a [ToolExtension] representing the established connection.
  ///
  /// Throws a [TimeoutException] if the handshake does not complete within [timeout].
  Future<ToolExtension> startExtension(
    void Function(SendPort) entryPoint, {
    Duration timeout = const Duration(seconds: 2),
  }) async {
    if (_isDisposed) {
      throw StateError('ToolExtensionManager is disposed.');
    }
    final ToolExtension? completed = _activeSpawns[entryPoint];
    if (completed != null) {
      return completed;
    }
    final Future<ToolExtension>? pending = _pendingSpawns[entryPoint];
    if (pending != null) {
      return pending;
    }

    final Future<ToolExtension> future = () async {
      try {
        final ToolExtension extension = await ToolExtension._start(
          entryPoint,
          timeout: timeout,
          onNotification: (Notification n) {
            if (!_isDisposed) {
              _notificationsController.add(n);
            }
          },
        );
        if (_isDisposed) {
          await extension.dispose();
          throw StateError('ToolExtensionManager was disposed during initialization.');
        }
        _extensions.add(extension);
        _activeSpawns[entryPoint] = extension;
        return extension;
      } finally {
        unawaited(_pendingSpawns.remove(entryPoint));
      }
    }();
    _pendingSpawns[entryPoint] = future;
    return future;
  }

  /// Connects to an externally spawned isolate by waiting on [receivePort] for the handshake.
  ///
  /// The caller must have passed the `receivePort.sendPort` to the extension isolate
  /// during its creation.
  ///
  /// Returns a [ToolExtension] representing the established connection.
  ///
  /// Throws a [TimeoutException] if the handshake does not complete within [timeout].
  Future<ToolExtension> connectExtension(
    ReceivePort receivePort, {
    Duration timeout = const Duration(seconds: 2),
  }) async {
    if (_isDisposed) {
      throw StateError('ToolExtensionManager is disposed.');
    }
    final ToolExtension extension = await ToolExtension._connect(
      receivePort,
      timeout: timeout,
      onNotification: (Notification n) {
        if (!_isDisposed) {
          _notificationsController.add(n);
        }
      },
    );
    if (_isDisposed) {
      await extension.dispose();
      throw StateError('ToolExtensionManager was disposed during initialization.');
    }
    _extensions.add(extension);
    return extension;
  }

  /// Disposes of the manager, disposing of all managed extensions.
  Future<void> dispose() async {
    _isDisposed = true;
    await Future.wait(_extensions.map((ToolExtension e) => e.dispose()));
    _extensions.clear();
    _activeSpawns.clear();
    _pendingSpawns.clear();
    await _notificationsController.close();
  }
}

/// Represents an active connection to a running Flutter Tool Extension.
class ToolExtension {
  ToolExtension._({
    required Isolate? isolate,
    required StreamController<Notification> notificationsController,
    required ReceivePort receivePort,
  }) : _isolate = isolate,
       _receivePort = receivePort,
       _notificationsController = notificationsController;

  Isolate? _isolate;
  final ReceivePort _receivePort;
  final StreamController<Notification> _notificationsController;
  StreamSubscription<Object?>? _subscription;
  StreamSubscription<Object?>? _peerSubscription;
  rpc.Peer? _peer;
  bool _isDisposed = false;

  /// A stream of notifications sent from this extension to the host tool.
  Stream<Notification> get notifications => _notificationsController.stream;

  /// Helper to start a new extension isolate.
  static Future<ToolExtension> _start(
    void Function(SendPort) entryPoint, {
    required Duration timeout,
    void Function(Notification)? onNotification,
  }) async {
    final receivePort = ReceivePort();
    final notificationsController = StreamController<Notification>.broadcast();

    final extension = ToolExtension._(
      isolate: null,
      receivePort: receivePort,
      notificationsController: notificationsController,
    );

    final handshakeCompleter = Completer<SendPort>();
    extension._subscription = receivePort.cast<Object?>().listen((Object? message) {
      if (!handshakeCompleter.isCompleted && message is SendPort) {
        handshakeCompleter.complete(message);
      }
    });

    try {
      final Isolate isolate = await Isolate.spawn(entryPoint, receivePort.sendPort);
      extension._isolate = isolate;

      final SendPort extensionSendPort = await handshakeCompleter.future.timeout(timeout);
      final channel = IsolateChannel<Object?>.connectSend(extensionSendPort);

      final incomingController = StreamController<Object?>(sync: true);
      extension._peerSubscription = channel.stream.listen(
        (Object? message) {
          _interceptNotifications(message, notificationsController, onNotification);
          incomingController.add(message);
        },
        onError: incomingController.addError,
        onDone: incomingController.close,
      );

      final peerChannel = StreamChannel<Object?>(incomingController.stream, channel.sink);
      final peer = rpc.Peer.withoutJson(peerChannel);
      extension._peer = peer;
      unawaited(peer.listen());

      return extension;
    } on TimeoutException {
      await extension.dispose();
      throw TimeoutException('Handshake with extension isolate timed out.');
    } on Object {
      await extension.dispose();
      rethrow;
    }
  }

  /// Helper to connect to an externally spawned extension.
  static Future<ToolExtension> _connect(
    ReceivePort receivePort, {
    required Duration timeout,
    void Function(Notification)? onNotification,
  }) async {
    final notificationsController = StreamController<Notification>.broadcast();

    final extension = ToolExtension._(
      isolate: null,
      receivePort: receivePort,
      notificationsController: notificationsController,
    );

    final handshakeCompleter = Completer<SendPort>();
    extension._subscription = receivePort.cast<Object?>().listen((Object? message) {
      if (!handshakeCompleter.isCompleted && message is SendPort) {
        handshakeCompleter.complete(message);
      }
    });

    try {
      final SendPort extensionSendPort = await handshakeCompleter.future.timeout(timeout);
      final channel = IsolateChannel<Object?>.connectSend(extensionSendPort);

      final incomingController = StreamController<Object?>(sync: true);
      extension._peerSubscription = channel.stream.listen(
        (Object? message) {
          _interceptNotifications(message, notificationsController, onNotification);
          incomingController.add(message);
        },
        onError: incomingController.addError,
        onDone: incomingController.close,
      );

      final peerChannel = StreamChannel<Object?>(incomingController.stream, channel.sink);
      final peer = rpc.Peer.withoutJson(peerChannel);
      extension._peer = peer;
      unawaited(peer.listen());

      return extension;
    } on TimeoutException {
      await extension.dispose();
      throw TimeoutException('Handshake with extension isolate timed out.');
    } on Object {
      await extension.dispose();
      rethrow;
    }
  }

  static void _interceptNotifications(
    Object? message,
    StreamController<Notification> controller,
    void Function(Notification)? onNotification,
  ) {
    if (message is List) {
      for (final Object? msg in message) {
        _interceptNotifications(msg, controller, onNotification);
      }
      return;
    }
    if (message is Map<Object?, Object?> && !message.containsKey('id')) {
      final Object? method = message['method'];
      if (method is String) {
        Map<String, Object?>? paramsMap;
        try {
          paramsMap = (message['params'] as Map<Object?, Object?>?)?.cast<String, Object?>();
        } on Object catch (_) {
          // Not a map (could be a List or empty), ignore or handle if needed.
        }
        final notification = Notification(method: method, params: paramsMap);
        controller.add(notification);
        onNotification?.call(notification);
      }
    }
  }

  /// Sends a request to the extension and waits for a response.
  ///
  /// Throws an [rpc.RpcException] if the extension returns an error response.
  /// Throws a [StateError] if the extension is disposed.
  Future<Object?> callMethod(String method, {Map<String, Object?>? params}) {
    final rpc.Peer? peer = _peer;
    if (peer == null || _isDisposed) {
      throw StateError('Extension is disposed.');
    }
    return peer.sendRequest(method, params);
  }

  /// Sends a notification with the given [method] and [params] to the extension.
  ///
  /// Throws a [StateError] if the extension is disposed.
  void sendNotification(String method, {Map<String, Object?>? params}) {
    final rpc.Peer? peer = _peer;
    if (peer == null || _isDisposed) {
      throw StateError('Extension is disposed.');
    }
    peer.sendNotification(method, params);
  }

  /// Returns the capabilities (i.e. supported services) reported by the extension.
  ///
  /// Throws a [StateError] if the extension is disposed.
  Future<ToolExtensionCapabilities> getCapabilities() async {
    final Object? result = await callMethod('extension.getCapabilities');
    if (result is Map) {
      return ToolExtensionCapabilities.fromJson(result.cast<String, Object?>());
    }
    throw StateError('Invalid capabilities response from extension.');
  }

  /// Disposes of the extension, killing its isolate and closing ports.
  Future<void> dispose() async {
    if (_isDisposed) {
      return;
    }
    _isDisposed = true;
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
