// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:isolate';

import 'package:flutter_tools_core/flutter_tools_core.dart';
import 'package:flutter_tools_extension/flutter_tools_extension.dart';
import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;
import 'package:meta/meta.dart';
import 'package:stream_channel/isolate_channel.dart';

import '../base/logger.dart';

/// Typedef for an in-process extension isolate entrypoint function.
///
/// Used by unit tests to spawn lightweight in-process extension isolates via
/// [ExtensionConnection.spawn] without compiling a `.dill` kernel file.
typedef ExtensionEntryPoint = void Function(SendPort sendPort);

/// Represents an active host-side connection to a running tool extension isolate.
class ExtensionConnection {
  ExtensionConnection._({
    required this.capabilities,
    required this._errorPort,
    required this._exitPort,
    required this.extensionName,
    required this._isolate,
    required this._logger,
    required this._peer,
    required this._receivePort,
  });

  /// Fallback extension name used when an extension does not report one in its capabilities.
  static const defaultExtensionName = 'unknown_extension';

  Isolate? _isolate;

  /// Port receiving uncaught async errors (`[String error, String? stackTrace]`)
  /// from the extension isolate.
  final ReceivePort _errorPort;

  /// Port notified when the extension isolate terminates so the host can close
  /// [_receivePort] and fail any in-flight RPCs instead of hanging.
  final ReceivePort _exitPort;

  final Logger _logger;
  final json_rpc.Peer _peer;
  final ReceivePort _receivePort;
  final _notificationControllers = <String, StreamController<Map<String, Object?>>>{};

  /// The capabilities and supported service namespaces of the extension.
  final ToolExtensionCapabilities capabilities;

  /// The resolved package or extension name of the connected extension.
  final String extensionName;

  bool _isDisposed = false;

  /// Whether this connection has been disposed.
  bool get isDisposed => _isDisposed;

  /// Handles uncaught async errors from the extension isolate after handshake.
  ///
  /// Per [Isolate.addErrorListener], `dart:isolate` delivers uncaught errors on
  /// the `onError` port as a two-element `List<Object?>` containing
  /// `[String errorDescription, String? stackTrace]`. Logging them here surfaces
  /// uncaught extension isolate errors that occur outside an active JSON-RPC
  /// request handler.
  void _handleIsolateError(Object? error) {
    if (error case [final Object? errorDescription, final Object? stackTrace]) {
      _logger.printError('Extension isolate "$extensionName" unhandled error: $errorDescription');
      if (stackTrace != null) {
        _logger.printTrace('$stackTrace');
      }
    } else {
      _logger.printError('Extension isolate "$extensionName" unhandled error: $error');
    }
  }

  /// Handles unexpected extension isolate termination after handshake.
  ///
  /// `IsolateChannel` (backed by a `ReceivePort`/`SendPort` pair) does not
  /// automatically close when the remote isolate exits. Closing [_receivePort]
  /// when the `onExit` port fires causes the JSON-RPC [json_rpc.Peer] to close
  /// immediately, failing any in-flight [sendRequest] calls (such as
  /// long-running `timeout: null` build requests) with a [StateError] and
  /// closing active notification streams instead of hanging indefinitely.
  void _handleIsolateExit() {
    _logger.printTrace('Extension isolate "$extensionName" exited unexpectedly.');
    unawaited(dispose());
  }

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

  /// Spawns an in-process extension isolate from [entryPoint] and completes the
  /// capability handshake.
  ///
  /// Used by unit tests to exercise extension protocol behavior in-process
  /// without compiling a `.dill` kernel file.
  @visibleForTesting
  static Future<ExtensionConnection> spawn(
    ExtensionEntryPoint entryPoint, {
    required Logger logger,
    String? extensionName,
    Duration timeout = const Duration(seconds: 5),
  }) {
    logger.printTrace('ExtensionConnection spawning extension isolate...');
    return _spawnAndHandshake(
      logger: logger,
      extensionName: extensionName,
      timeout: timeout,
      isolateLauncher: (SendPort sendPort, SendPort onError, SendPort onExit) {
        return Isolate.spawn(entryPoint, sendPort, onError: onError, onExit: onExit);
      },
    );
  }

  /// Spawns an extension isolate dynamically from [entrypointUri] (a compiled
  /// `.dill` Kernel URI or `.dart` script URI) using [packageConfigUri] and
  /// completes the capability handshake.
  ///
  /// When [expectedConfig] is provided, validates that the runtime
  /// [ToolExtensionCapabilities] reported by `extension.getCapabilities` match
  /// the static declarations in `extension/flutter_tools/config.yaml`,
  /// disposing the connection and throwing a [StateError] if they drift.
  static Future<ExtensionConnection> spawnUri(
    Uri entrypointUri, {
    required Logger logger,
    required Uri packageConfigUri,
    List<String> args = const <String>[],
    ExtensionPackageConfig? expectedConfig,
    String? extensionName,
    Duration timeout = const Duration(seconds: 5),
  }) async {
    logger.printTrace(
      'ExtensionConnection spawning extension isolate from URI "$entrypointUri"...',
    );
    final ExtensionConnection connection = await _spawnAndHandshake(
      logger: logger,
      extensionName: extensionName ?? expectedConfig?.name,
      timeout: timeout,
      isolateLauncher: (SendPort sendPort, SendPort onError, SendPort onExit) {
        return Isolate.spawnUri(
          entrypointUri,
          args,
          sendPort,
          packageConfig: packageConfigUri,
          onError: onError,
          onExit: onExit,
        );
      },
    );
    if (expectedConfig != null) {
      try {
        connection._validateCapabilitiesMatchConfig(expectedConfig);
      } on Object {
        await connection.dispose();
        rethrow;
      }
    }
    return connection;
  }

  void _validateCapabilitiesMatchConfig(ExtensionPackageConfig expectedConfig) {
    final Set<String> actualServices = capabilities.services.toSet();
    if (actualServices.length != expectedConfig.services.length ||
        !actualServices.containsAll(expectedConfig.services)) {
      throw StateError(
        'Extension "$extensionName" capabilities mismatch: '
        'extension/flutter_tools/config.yaml declares services '
        '${expectedConfig.services.toList()}, '
        'but ToolExtensionEntryPoint.run registered ${capabilities.services}.',
      );
    }
    if (expectedConfig.hostPlatforms.isNotEmpty) {
      final Set<String> actualPlatforms = capabilities.supportedPlatforms;
      if (actualPlatforms.length != expectedConfig.hostPlatforms.length ||
          !actualPlatforms.containsAll(expectedConfig.hostPlatforms)) {
        throw StateError(
          'Extension "$extensionName" capabilities mismatch: '
          'extension/flutter_tools/config.yaml declares host_platforms '
          '${expectedConfig.hostPlatforms.toList()}, '
          'but ToolExtensionEntryPoint.run registered supportedPlatforms '
          '${actualPlatforms.toList()}.',
        );
      }
    }
  }

  static Future<ExtensionConnection> _spawnAndHandshake({
    required Future<Isolate> Function(SendPort sendPort, SendPort onError, SendPort onExit)
    isolateLauncher,
    required Logger logger,
    String? extensionName,
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final receivePort = ReceivePort();
    final errorPort = ReceivePort();
    final exitPort = ReceivePort();
    final errorCompleter = Completer<Never>();
    ExtensionConnection? connection;

    // Isolate.spawn delivers uncaught isolate errors as a two-element list:
    // `[String errorDescription, String? stackTrace]`.
    errorPort.listen((Object? error) {
      if (connection case final ExtensionConnection activeConnection) {
        activeConnection._handleIsolateError(error);
        return;
      }
      if (!errorCompleter.isCompleted) {
        final Object? errorDescription = switch (error) {
          [final Object? description, _] => description,
          _ => error,
        };
        errorCompleter.completeError(StateError('Extension isolate error: $errorDescription'));
      }
    });

    exitPort.listen((Object? _) {
      if (connection case final ExtensionConnection activeConnection) {
        activeConnection._handleIsolateExit();
        return;
      }
      if (!errorCompleter.isCompleted) {
        errorCompleter.completeError(
          StateError('Extension isolate exited unexpectedly before handshake completed.'),
        );
      }
    });

    Isolate? isolate;

    try {
      isolate = await isolateLauncher(receivePort.sendPort, errorPort.sendPort, exitPort.sendPort);
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

      return connection = ExtensionConnection._(
        capabilities: capabilities,
        errorPort: errorPort,
        exitPort: exitPort,
        extensionName: extensionName ?? capabilities.extensionName ?? defaultExtensionName,
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
    for (final StreamController<Map<String, Object?>> controller
        in _notificationControllers.values) {
      await controller.close();
    }
    _notificationControllers.clear();
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
