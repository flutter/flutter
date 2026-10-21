// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:isolate';

import 'package:flutter_tools_extension/flutter_tools_extension.dart';
import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;
import 'package:stream_channel/isolate_channel.dart';

import '../base/logger.dart';

/// Typedef for an extension isolate entrypoint function.
typedef ExtensionEntryPoint = void Function(SendPort sendPort);

/// Represents an active host-side connection to a running tool extension isolate.
class ExtensionConnection {
  ExtensionConnection._({
    required this.capabilities,
    required this.extensionName,
    required this._errorPort,
    required this._exitPort,
    required Isolate this._isolate,
    required this._logger,
    required this._peer,
    required this._receivePort,
  }) {
    _errorPort.handler = (Object? error) {
      final Object? message = error is List && error.isNotEmpty ? error[0] : error;
      _logger.printError('Extension isolate "$extensionName" unhandled error: $message');
    };

    _exitPort.handler = (Object? _) {
      _logger.printTrace('Extension isolate "$extensionName" exited unexpectedly.');
      _errorPort.close();
      _exitPort.close();
      _receivePort.close();
      unawaited(_closeNotificationControllers());
    };
  }

  /// Fallback extension name used when an extension does not report one in its capabilities.
  static const defaultExtensionName = 'unknown_extension';

  Isolate? _isolate;
  final RawReceivePort _errorPort;
  final RawReceivePort _exitPort;
  final Logger _logger;
  final json_rpc.Peer _peer;
  final ReceivePort _receivePort;
  final _notificationControllers = <String, StreamController<Map<String, Object?>>>{};

  /// The capabilities and supported service namespaces of the extension.
  final ToolExtensionCapabilities capabilities;

  /// The resolved package or extension name of the connected extension.
  final String extensionName;

  bool _isDisposed = false;

  /// Returns a broadcast stream of JSON-RPC 2.0 notifications sent by the
  /// extension isolate for [method].
  Stream<Map<String, Object?>> onNotification(String method) {
    if (_isDisposed) {
      throw StateError('ExtensionConnection has been disposed.');
    }
    final StreamController<Map<String, Object?>>
    controller = _notificationControllers.putIfAbsent(method, () {
      final newController = StreamController<Map<String, Object?>>.broadcast();
      _peer.registerMethod(method, (json_rpc.Parameters params) {
        if (newController.isClosed) {
          return;
        }
        final Object? rawValue = params.value;
        if (rawValue is! Map<String, Object?>) {
          _logger.printWarning(
            'Extension "$extensionName" sent malformed notification for "$method": expected Map<String, Object?>.',
          );
          return;
        }
        newController.add(rawValue);
      });
      return newController;
    });
    return controller.stream;
  }

  /// Sends an RPC request to the extension isolate.
  Future<Object?> sendRequest(
    String method, {
    Object? params,
    Duration? timeout = const Duration(seconds: 5),
  }) async {
    if (_isDisposed) {
      throw StateError('ExtensionConnection has been disposed.');
    }
    _logger.printTrace('ExtensionConnection sending RPC request "$method"...');
    try {
      final Future<Object?> request = _peer.sendRequest(method, params);
      final Object? result = await (timeout != null ? request.timeout(timeout) : request);
      _logger.printTrace('ExtensionConnection received response for RPC request "$method".');
      return result;
    } catch (error) {
      _logger.printTrace('ExtensionConnection RPC request "$method" failed with error: $error');
      rethrow;
    }
  }

  /// Spawns an extension isolate from [entryPoint] and completes handshake.
  static Future<ExtensionConnection> spawn(
    ExtensionEntryPoint entryPoint, {
    required Logger logger,
    Duration timeout = const Duration(seconds: 5),
  }) async {
    logger.printTrace('ExtensionConnection spawning extension isolate...');
    final receivePort = ReceivePort();
    final errorPort = RawReceivePort();
    final exitPort = RawReceivePort();
    final errorCompleter = Completer<Never>();

    errorPort.handler = (Object? error) {
      if (!errorCompleter.isCompleted) {
        if (error is List && error.isNotEmpty) {
          errorCompleter.completeError(StateError('Extension isolate error: ${error[0]}'));
        } else {
          errorCompleter.completeError(StateError('Extension isolate error: $error'));
        }
      }
    };

    exitPort.handler = (Object? _) {
      if (!errorCompleter.isCompleted) {
        errorCompleter.completeError(
          StateError('Extension isolate exited unexpectedly before handshake completed.'),
        );
      }
    };

    Isolate? isolate;

    try {
      isolate = await Isolate.spawn(
        entryPoint,
        receivePort.sendPort,
        onError: errorPort.sendPort,
        onExit: exitPort.sendPort,
      );
      logger.printTrace('ExtensionConnection isolate spawned; connecting IsolateChannel...');
      final channel = IsolateChannel<Object?>.connectReceive(receivePort);
      final peer = json_rpc.Peer.withoutJson(channel);

      unawaited(peer.listen());

      logger.printTrace('ExtensionConnection querying extension.getCapabilities...');
      final Object? responseObj = await Future.any<Object?>([
        peer.sendRequest(ToolExtensionEntryPoint.getCapabilitiesMethod),
        errorCompleter.future,
      ]).timeout(timeout);
      if (responseObj is! Map<String, Object?>) {
        throw StateError(
          'Extension handshake failed: extension.getCapabilities did not return a Map.',
        );
      }
      final capabilities = ToolExtensionCapabilities.fromJson(responseObj);
      logger.printTrace(
        'ExtensionConnection handshake complete. Capabilities: ${capabilities.services}',
      );

      return ExtensionConnection._(
        capabilities: capabilities,
        extensionName: capabilities.extensionName ?? defaultExtensionName,
        errorPort: errorPort,
        exitPort: exitPort,
        isolate: isolate,
        logger: logger,
        peer: peer,
        receivePort: receivePort,
      );
    } on TimeoutException {
      logger.printTrace('ExtensionConnection handshake timed out.');
      receivePort.close();
      errorPort.close();
      exitPort.close();
      isolate?.kill(priority: Isolate.immediate);
      throw TimeoutException('Handshake with tool extension isolate timed out.');
    } on Object catch (error) {
      logger.printTrace('ExtensionConnection spawn failed with error: $error');
      receivePort.close();
      errorPort.close();
      exitPort.close();
      isolate?.kill(priority: Isolate.immediate);
      rethrow;
    }
  }

  Future<void> _closeNotificationControllers() async {
    for (final StreamController<Map<String, Object?>> controller
        in _notificationControllers.values) {
      await controller.close();
    }
    _notificationControllers.clear();
  }

  /// Disposes the extension isolate connection.
  Future<void> dispose() async {
    if (_isDisposed) {
      return;
    }
    _isDisposed = true;
    _logger.printTrace('ExtensionConnection disposing isolate connection.');
    _errorPort.close();
    _exitPort.close();
    _receivePort.close();
    await _closeNotificationControllers();
    try {
      await _peer.close();
    } on Object catch (error) {
      _logger.printTrace('Error closing extension connection peer: $error');
    } finally {
      _isolate?.kill(priority: Isolate.immediate);
      _isolate = null;
    }
  }
}

/// Discovers and manages active tool extension isolate connections.
class ExtensionDiscovery {
  /// Creates an [ExtensionDiscovery] instance with required [_logger].
  ExtensionDiscovery({required this._logger});

  final _connections = <ExtensionConnection>[];
  final Logger _logger;

  /// Active extension connections.
  List<ExtensionConnection> get connections => List<ExtensionConnection>.unmodifiable(_connections);

  /// Registers an active [connection].
  void registerConnection(ExtensionConnection connection) {
    _logger.printTrace('ExtensionDiscovery registering active connection.');
    _connections.add(connection);
  }

  /// Registers multiple active [connections].
  void registerConnections(Iterable<ExtensionConnection> connections) {
    _logger.printTrace('ExtensionDiscovery registering ${connections.length} connection(s).');
    _connections.addAll(connections);
  }

  /// Disposes all registered extension isolate connections.
  Future<void> dispose() async {
    _logger.printTrace('ExtensionDiscovery disposing all registered connections.');
    for (final ExtensionConnection connection in _connections) {
      await connection.dispose();
    }
    _connections.clear();
  }
}
