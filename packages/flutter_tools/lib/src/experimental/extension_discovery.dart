// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:isolate';

import 'package:flutter_tools_core/flutter_tools_core.dart';
import 'package:flutter_tools_extension/client.dart';
import 'package:meta/meta.dart';

import '../base/logger.dart';

/// Typedef for an in-process extension isolate entrypoint function.
///
/// Used by unit tests to spawn lightweight in-process extension isolates via
/// [ExtensionConnection.spawn] without compiling a `.dill` kernel file, and
/// during transitional bootstrap before dynamic project discovery is wired via
/// [ExtensionConnection.spawnUri].
typedef ExtensionEntryPoint = void Function(SendPort sendPort);

/// Represents an active host-side connection to a running tool extension isolate.
class ExtensionConnection implements ExtensionRpcChannel {
  ExtensionConnection._(this._connection);

  /// Fallback extension name used when an extension does not report one in its capabilities.
  static const String defaultExtensionName = ExtensionIsolateConnection.defaultExtensionName;

  static const _ownerName = 'ExtensionConnection';

  final ExtensionIsolateConnection _connection;

  /// The capabilities and supported service namespaces of the extension.
  ToolExtensionCapabilities get capabilities => _connection.capabilities;

  /// The resolved package or extension name of the connected extension.
  String get extensionName => _connection.extensionName;

  /// Whether this connection has been disposed.
  bool get isDisposed => _connection.isDisposed;

  /// Shared typed `diagnostics.*` JSON-RPC client bound to this connection.
  late final diagnosticsRpc = ExtensionDiagnosticsRpcClient(this);

  /// Shared typed `config.*` JSON-RPC client bound to this connection.
  late final configRpc = ExtensionConfigurationRpcClient(this);

  /// Shared typed `template.*` JSON-RPC client bound to this connection.
  late final templateRpc = ExtensionTemplateRpcClient(this);

  /// Shared typed `device.*` JSON-RPC client bound to this connection.
  late final deviceRpc = ExtensionDeviceRpcClient(this);

  /// Shared typed `build.*` JSON-RPC client bound to this connection.
  late final buildRpc = ExtensionBuildRpcClient(this);

  /// Shared typed `artifact.*` JSON-RPC client bound to this connection.
  late final artifactRpc = ExtensionArtifactRpcClient(this);

  /// Shared typed `clean.*` JSON-RPC client bound to this connection.
  late final cleanRpc = ExtensionCleanRpcClient(this);

  @override
  Stream<Map<String, Object?>> onNotification(String method) => _connection.onNotification(method);

  @override
  Future<Object?> sendRequest(
    String method, {
    Object? params,
    Duration? timeout = ExtensionIsolateConnection.defaultRpcTimeout,
  }) => _connection.sendRequest(method, params: params, timeout: timeout);

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
    Duration timeout = ExtensionIsolateConnection.defaultRpcTimeout,
  }) async {
    final ExtensionIsolateConnection connection = await ExtensionIsolateConnection.spawn(
      entryPoint,
      extensionName: extensionName,
      onIsolateError: (Object? _, String detail, StackTrace? stackTrace, String extName) =>
          _logIsolateError(logger, extName, detail, stackTrace),
      onIsolateExit: (String extName) =>
          logger.printTrace('Extension isolate "$extName" exited unexpectedly.'),
      onLogMessage: (ExtensionLogMessage message, String extName) =>
          _routeLogMessage(logger, extName, message),
      onMalformedNotification:
          (String method, FormatException error, StackTrace _, String extName) =>
              logger.printWarning(
                'Extension "$extName" sent malformed notification for "$method": ${error.message}',
              ),
      onTrace: logger.printTrace,
      ownerName: _ownerName,
      timeout: timeout,
    );
    return ExtensionConnection._(connection);
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
    Duration timeout = ExtensionIsolateConnection.defaultRpcTimeout,
  }) async {
    final ExtensionIsolateConnection inner = await ExtensionIsolateConnection.spawnUri(
      entrypointUri,
      args: args,
      extensionName: extensionName ?? expectedConfig?.name,
      onIsolateError: (Object? _, String detail, StackTrace? stackTrace, String extName) =>
          _logIsolateError(logger, extName, detail, stackTrace),
      onIsolateExit: (String extName) =>
          logger.printTrace('Extension isolate "$extName" exited unexpectedly.'),
      onLogMessage: (ExtensionLogMessage message, String extName) =>
          _routeLogMessage(logger, extName, message),
      onMalformedNotification:
          (String method, FormatException error, StackTrace _, String extName) =>
              logger.printWarning(
                'Extension "$extName" sent malformed notification for "$method": ${error.message}',
              ),
      onTrace: logger.printTrace,
      ownerName: _ownerName,
      packageConfigUri: packageConfigUri,
      timeout: timeout,
    );
    final connection = ExtensionConnection._(inner);
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

  static void _logIsolateError(
    Logger logger,
    String extensionName,
    String detail,
    StackTrace? stackTrace,
  ) {
    logger.printError('Extension isolate "$extensionName" unhandled error: $detail');
    if (stackTrace != null) {
      logger.printTrace('$stackTrace');
    }
  }

  static void _routeLogMessage(Logger logger, String extensionName, ExtensionLogMessage message) {
    final formatted = '[$extensionName] ${message.message}';
    switch (message.level) {
      case .info:
        logger.printStatus(formatted);
      case .warning:
        logger.printWarning(formatted);
      case .error:
        logger.printError(formatted);
      case .trace:
        logger.printTrace(formatted);
    }
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

  /// Disposes the extension isolate connection.
  Future<void> dispose() => _connection.dispose();
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
    await Future.wait(_connections.map((ExtensionConnection c) => c.dispose()));
    _connections.clear();
  }
}
