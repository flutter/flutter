// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:isolate';

import 'package:flutter_tools_extension/flutter_tools_extension.dart';
import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;
import 'package:meta/meta.dart';
import 'package:stream_channel/isolate_channel.dart';

import '../base/logger.dart';

/// Typedef for an in-process extension isolate entrypoint function.
///
/// Used by unit tests to spawn lightweight in-process extension isolates via
/// [ExtensionConnection.spawn] without compiling a `.dill` kernel file, and
/// during transitional bootstrap before dynamic project discovery is wired via
/// [ExtensionConnection.spawnUri].
typedef ExtensionEntryPoint = void Function(SendPort sendPort);

/// Represents an active host-side connection to a running tool extension isolate.
class ExtensionConnection {
  ExtensionConnection._({
    required this.capabilities,
    required this.extensionName,
    required this._isolate,
    required this._logger,
    required this._peer,
  });

  /// Fallback extension name used when an extension does not report one in its capabilities.
  static const defaultExtensionName = 'unknown_extension';

  Isolate? _isolate;
  final json_rpc.Peer _peer;
  final Logger _logger;

  /// The capabilities and supported service namespaces of the extension.
  final ToolExtensionCapabilities capabilities;

  /// The resolved package or extension name of the connected extension.
  final String extensionName;

  bool _isDisposed = false;

  /// Whether this connection has been disposed.
  bool get isDisposed => _isDisposed;

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
  /// without compiling a `.dill` kernel file, and during transitional bootstrap
  /// before dynamic project discovery is wired via [spawnUri].
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
  static Future<ExtensionConnection> spawnUri(
    Uri entrypointUri, {
    required Logger logger,
    required Uri packageConfigUri,
    List<String> args = const <String>[],
    String? extensionName,
    Duration timeout = const Duration(seconds: 5),
  }) {
    logger.printTrace(
      'ExtensionConnection spawning extension isolate from URI "$entrypointUri"...',
    );
    return _spawnAndHandshake(
      logger: logger,
      extensionName: extensionName,
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
  }

  static Future<ExtensionConnection> _spawnAndHandshake({
    required Future<Isolate> Function(SendPort sendPort, SendPort onError, SendPort onExit)
    isolateLauncher,
    required Logger logger,
    String? extensionName,
    Duration timeout = const Duration(seconds: 5),
  }) async {
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

      return ExtensionConnection._(
        isolate: isolate,
        peer: peer,
        capabilities: capabilities,
        extensionName: extensionName ?? capabilities.extensionName ?? defaultExtensionName,
        logger: logger,
      );
    } on TimeoutException {
      logger.printTrace('ExtensionConnection handshake timed out.');
      receivePort.close();
      isolate?.kill(priority: Isolate.immediate);
      throw TimeoutException('Handshake with tool extension isolate timed out.');
    } on Object catch (error) {
      logger.printTrace('ExtensionConnection spawn failed with error: $error');
      receivePort.close();
      isolate?.kill(priority: Isolate.immediate);
      rethrow;
    } finally {
      errorPort.close();
      exitPort.close();
    }
  }

  /// Disposes the extension isolate connection.
  Future<void> dispose() async {
    if (_isDisposed) {
      return;
    }
    _isDisposed = true;
    _logger.printTrace('ExtensionConnection disposing isolate connection.');
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

  final List<ExtensionConnection> _connections = <ExtensionConnection>[];
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
