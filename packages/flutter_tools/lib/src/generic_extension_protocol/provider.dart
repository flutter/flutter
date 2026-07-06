// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Provider and RPC registrar for the extension side of tool extensions.
///
/// This library provides the connection and communication channel for a
/// Flutter Tool Extension, allowing it to register services and RPC handlers.
library generic_extension_protocol.provider;

import 'dart:async';
import 'dart:isolate';

import 'package:json_rpc_2/json_rpc_2.dart' as rpc;
import 'package:stream_channel/isolate_channel.dart';
import 'package:stream_channel/stream_channel.dart';

import 'service.dart';

/// Provides the connection and communication channel for a Flutter Tool Extension.
///
/// This class is used by the extension isolate to communicate with the host tool.
/// It handles the handshake, wraps the channel in a JSON-RPC [rpc.Peer],
/// and routes incoming RPC requests to registered [ToolExtensionService]s.
class ToolExtensionProvider implements RpcRegistrar {
  /// Creates a [ToolExtensionProvider] that communicates with the tool via [sendPort].
  ToolExtensionProvider({required String name, required SendPort sendPort})
    : _name = name,
      _toolSendPort = sendPort {
    _receivePort = ReceivePort(name);
  }

  final String _name;
  final SendPort _toolSendPort;

  /// The name of this extension.
  String get name => _name;
  late final ReceivePort _receivePort;
  final _registeredMethods = <String, Function>{};
  final _notificationsController = StreamController<Notification>.broadcast();
  final List<ToolExtensionService> _services = <ToolExtensionService>[];

  StreamSubscription<Object?>? _subscription;
  rpc.Peer? _peer;

  /// A stream of notifications sent from the host Flutter tool to this extension.
  Stream<Notification> get notifications => _notificationsController.stream;

  /// The set of services registered with this provider.
  List<ToolExtensionService> get services => List.unmodifiable(_services);

  /// Registers a [service] with the extension, making it available to the tool.
  ///
  /// All services must be registered before calling [initialize].
  /// Throws a [StateError] if the provider is already initialized.
  void registerService(ToolExtensionService service) {
    if (_peer != null) {
      throw StateError('Cannot register service after initialization.');
    }
    _services.add(service);
  }

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
  /// It sets up the [rpc.Peer], initializes all registered services, performs
  /// the handshake by sending the receive port's send port to the host, and starts
  /// listening for RPC requests.
  ///
  /// Returns the [ToolExtensionCapabilities] representing the supported services.
  Future<ToolExtensionCapabilities> initialize() async {
    if (_peer != null) {
      throw StateError('ToolExtensionProvider is already initialized.');
    }

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
    final peer = rpc.Peer.withoutJson(peerChannel);
    _peer = peer;

    // Initialize registered services and register their methods namespaces.
    final serviceNamespaces = <String>[];
    for (final ToolExtensionService service in _services) {
      serviceNamespaces.add(service.namespace);
      final Map<String, Function> methods = await service.initialize();
      methods.forEach((methodName, handler) {
        final namespacedMethod = '${service.namespace}.$methodName';
        Object? callback(rpc.Parameters params) {
          if (handler is Object? Function(Map<String, Object?>)) {
            final Map<String, Object?> map = params.value is Map<Object?, Object?>
                ? params.asMap.cast<String, Object?>()
                : const <String, Object?>{};
            return handler(map);
          }
          if (handler is Object? Function()) {
            return handler();
          }
          final Map<String, Object?> map = params.value is Map<Object?, Object?>
              ? params.asMap.cast<String, Object?>()
              : const <String, Object?>{};
          return Function.apply(handler, <Object?>[map]);
        }

        peer.registerMethod(namespacedMethod, callback);
      });
    }

    // Register all cached methods.
    _registeredMethods.forEach(peer.registerMethod);

    // Register standard capabilities RPC.
    peer.registerMethod('extension.getCapabilities', () {
      return ToolExtensionCapabilities(services: serviceNamespaces).toMap();
    });

    // Handshake: send our ReceivePort's SendPort to the tool.
    _toolSendPort.send(_receivePort.sendPort);

    // Start listening.
    unawaited(peer.listen());

    return ToolExtensionCapabilities(services: serviceNamespaces);
  }

  void _interceptNotifications(Object? message) {
    if (message is List) {
      message.forEach(_interceptNotifications);
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
        _notificationsController.add(Notification(method: method, params: paramsMap));
      }
    }
  }

  /// Sends a notification to the host Flutter tool.
  void sendNotification(String method, [Object? parameters]) {
    final rpc.Peer? peer = _peer;
    if (peer == null) {
      throw StateError('Provider is not initialized.');
    }
    peer.sendNotification(method, parameters);
  }

  /// Cleanly shuts down the extension, shutting down all registered services.
  Future<void> shutdown() async {
    for (final ToolExtensionService service in _services) {
      await service.shutdown();
    }
    await close();
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
